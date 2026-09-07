# ADR-005: Deployment Strategy

## Status
Superseded for the default environment by [ADR-006](ADR-006-zero-cost-serverless.md)

The EKS / Knative / RDS topology remains a **paid** option under `deploy/terraform-eks/` and Helm/ArgoCD. It is not applied by `make infra-apply`.

## Context
The GNSS spoofing detection system must support both cloud SaaS and edge/embedded deployments for sensor nodes.

## Decision
We adopt a **Hybrid K8s + Serverless** deployment:

| Component | Deployment | Rationale |
|-----------|-----------|-----------|
| API Gateway | Knative Serving | Scale-to-zero for low-traffic periods |
| Detection Engine | StatefulSet on EKS | Performance-critical, stateful |
| MCP Server | Knative Serving | Event-driven tool requests |
| Quantum Backend | GPU node pool on EKS | GPU-required circuits |
| Frontend | CloudFront + S3 | Static site, global CDN |
| Database | RDS / Elasticache | Managed services |
| CI/CD | GitHub Actions + ArgoCD | GitOps workflow |

## Consequences
- Multi-region failover capability
- Edge sensor nodes run DuckDB + lightweight detection
- Central cloud aggregates and runs quantum detection
- ArgoCD enables declarative GitOps
