terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  backend "s3" {
    bucket = "gnss-detection-terraform-state"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "development"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

locals {
  name_prefix = "gnss-detection-${var.environment}"
  common_tags = {
    Environment = var.environment
    Project     = "gnss-spoofing-detection"
    ManagedBy   = "terraform"
  }
}

provider "aws" {
  region = var.region
}

# ─── EKS Cluster ──────────────────────────────────────────
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${local.name_prefix}-cluster"
  cluster_version = "1.31"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  node_groups = {
    main = {
      desired_size   = 3
      min_size       = 3
      max_size       = 10
      instance_types = ["t3.medium", "t3.large"]
    }
    quantum = {
      desired_size   = 1
      min_size       = 0
      max_size       = 3
      instance_types = ["g4dn.xlarge", "g5.xlarge"]
    }
  }

  tags = local.common_tags
}

# ─── VPC ──────────────────────────────────────────────────
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name_prefix}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.common_tags
}

# ─── RDS for PostgreSQL ──────────────────────────────────
resource "aws_db_instance" "main" {
  count = var.environment == "production" ? 1 : 0

  identifier     = "${local.name_prefix}-db"
  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t3.medium"

  db_name  = "gnss_detection"
  username = "gnss_admin"
  password = random_password.db_password.result

  vpc_security_group_ids = [module.vpc.default_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 30
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-05:00"

  skip_final_snapshot = var.environment != "production"
  deletion_protection = var.environment == "production"

  tags = local.common_tags
}

resource "random_password" "db_password" {
  length  = 32
  special = false
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnets"
  subnet_ids = module.vpc.private_subnets
  tags       = local.common_tags
}

# ─── Elasticache for Redis ──────────────────────────────
resource "aws_elasticache_cluster" "redis" {
  count = var.environment == "production" ? 1 : 0

  cluster_id           = "${local.name_prefix}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [module.vpc.default_security_group_id]

  tags = local.common_tags
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.name_prefix}-redis-subnets"
  subnet_ids = module.vpc.private_subnets
}

# ─── S3 for Iceberg ─────────────────────────────────────
resource "aws_s3_bucket" "iceberg" {
  bucket = "${local.name_prefix}-iceberg-warehouse"
  tags   = local.common_tags
}

resource "aws_s3_bucket_versioning" "iceberg" {
  bucket = aws_s3_bucket.iceberg.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ─── ECR for Docker images ──────────────────────────────
resource "aws_ecr_repository" "main" {
  name                 = local.name_prefix
  image_tag_mutability = "MUTABLE"
  tags                 = local.common_tags
}

# ─── IAM Role for CI/CD ──────────────────────────────────
resource "aws_iam_role" "github_actions" {
  name = "${local.name_prefix}-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "accounts.google.com"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = local.common_tags
}

# ─── Outputs ─────────────────────────────────────────────
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "database_endpoint" {
  value = var.environment == "production" ? aws_db_instance.main[0].address : null
}

output "redis_endpoint" {
  value = var.environment == "production" ? aws_elasticache_cluster.redis[0].cache_nodes[0].address : null
}

output "ecr_repository_url" {
  value = aws_ecr_repository.main.repository_url
}

output "iceberg_bucket" {
  value = aws_s3_bucket.iceberg.bucket
}
