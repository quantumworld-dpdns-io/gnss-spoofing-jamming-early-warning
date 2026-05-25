.PHONY: all build build-rust build-python build-go build-frontend \
        test test-rust test-python test-go test-frontend test-all \
        test-robot test-robot-acceptance test-robot-security test-robot-performance \
        lint lint-rust lint-python lint-go lint-frontend lint-all \
        format format-rust format-python format-go format-frontend \
        clean clean-rust clean-python clean-go clean-frontend \
        docker docker-build docker-push \
        release release-dry-run \
        security-audit fuzz chaos \
        quantum quantum-simulate quantum-validate \
        dev dev-backend dev-frontend dev-all \
        docs serve-docs \
        install-hooks \
        run-mcp-server run-api-gateway run-detection-engine \
        package-deb package-rpm package-homebrew package-docker

# ─── Build ────────────────────────────────────────────────
SHELL := /bin/bash
CARGO := cargo
PYTHON := python3
NODE := node
NPM := npm
GO := go
DOCKER := docker

build: build-rust build-python build-go build-frontend

build-rust:
	$(CARGO) build --release --workspace

build-python:
	cd src/detection-engine/python && pip install -e .

build-go:
	cd src/api-gateway && $(GO) build -o ../../bin/api-gateway ./cmd/

build-frontend:
	cd src/frontend && $(NPM) ci && $(NPM) run build

# ─── Test ──────────────────────────────────────────────────
test: test-rust test-python test-go test-frontend

test-rust:
	$(CARGO) test --workspace --release

test-python:
	cd src/detection-engine/python && $(PYTHON) -m pytest tests/ -v --cov

test-go:
	cd src/api-gateway && $(GO) test ./... -v -race

test-frontend:
	cd src/frontend && $(NPM) run test

test-all: test test-robot

test-robot: test-robot-acceptance test-robot-security test-robot-performance
	pabot --processes 4 --outputdir tests/robot/results tests/robot/

test-robot-acceptance:
	robot --outputdir tests/robot/results/acceptance tests/robot/acceptance/

test-robot-security:
	robot --outputdir tests/robot/results/security tests/robot/security/

test-robot-performance:
	robot --outputdir tests/robot/results/performance tests/robot/performance/

# ─── Lint ──────────────────────────────────────────────────
lint: lint-rust lint-python lint-go lint-frontend

lint-rust:
	$(CARGO) clippy --workspace -- -D warnings && $(CARGO) fmt --check

lint-python:
	ruff check src/detection-engine/python/ tests/ && mypy src/detection-engine/python/

lint-go:
	cd src/api-gateway && $(GO) vet ./... && golangci-lint run

lint-frontend:
	cd src/frontend && $(NPM) run lint

format: format-rust format-python format-go format-frontend

format-rust:
	$(CARGO) fmt

format-python:
	ruff format src/detection-engine/python/ tests/

format-go:
	cd src/api-gateway && $(GO) fmt ./...

format-frontend:
	cd src/frontend && $(NPM) run format

# ─── Clean ─────────────────────────────────────────────────
clean: clean-rust clean-python clean-go clean-frontend
	rm -rf bin/ dist/ build/ target/

clean-rust:
	$(CARGO) clean

clean-python:
	rm -rf src/detection-engine/python/*.egg-info src/detection-engine/python/__pycache__/
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true

clean-go:
	rm -rf bin/

clean-frontend:
	rm -rf src/frontend/.next src/frontend/out

# ─── Docker ────────────────────────────────────────────────
docker-build:
	$(DOCKER) build -t gnss-detection:latest -f deploy/docker/Dockerfile .
	$(DOCKER) build -t gnss-detection-mcp:latest -f deploy/docker/Dockerfile.mcp .

docker-push:
	$(DOCKER) push ghcr.io/quantumworld-dpdns-io/gnss-detection:latest
	$(DOCKER) push ghcr.io/quantumworld-dpdns-io/gnss-detection-mcp:latest

# ─── Release ───────────────────────────────────────────────
release:
	npx semantic-release

release-dry-run:
	npx semantic-release --dry-run

# ─── Security ──────────────────────────────────────────────
security-audit:
	$(CARGO) audit
	bandit -r src/detection-engine/python/
	trivy fs --severity HIGH,CRITICAL .

fuzz:
	cd src/detection-engine/crates/gnss-parser && $(CARGO) fuzz run fuzz_nmea -- -runs=100000
	cd src/detection-engine/crates/signal-processing && $(CARGO) fuzz run fuzz_detector -- -runs=100000

chaos:
	chaos run tests/chaos/experiments.json

# ─── Quantum ───────────────────────────────────────────────
quantum: quantum-simulate quantum-validate

quantum-simulate:
	cd src/detection-engine/python && $(PYTHON) -c "from quantum.autoencoder import _test_autoencoder; _test_autoencoder()"
	cd src/detection-engine/python && $(PYTHON) -c "from quantum.vqc import _test_vqc; _test_vqc()"
	cd src/detection-engine/python && $(PYTHON) -c "from quantum.circuits import _test_circuits; _test_circuits()"
	cd src/detection-engine/python && $(PYTHON) -c "from quantum.qrng import _test_qrng; _test_qrng()"

quantum-validate:
	$(CARGO) test -p quantum-detector --release

# ─── Dev Servers ───────────────────────────────────────────
dev-backend:
	$(CARGO) run -p mcp-server -- --host 127.0.0.1:8090 &
	cd src/api-gateway && $(GO) run ./cmd/ &

dev-frontend:
	cd src/frontend && $(NPM) run dev

dev-all: dev-backend dev-frontend

# ─── Docs ──────────────────────────────────────────────────
docs:
	cd docs && $(NPM) run build-docs
	$(CARGO) doc --workspace --no-deps

serve-docs:
	cd docs && $(NPM) run serve

# ─── Git Hooks ─────────────────────────────────────────────
install-hooks:
	pre-commit install
	pre-commit install --hook-type commit-msg

# ─── Run Servers ───────────────────────────────────────────
run-mcp-server:
	$(CARGO) run -p mcp-server --release

run-api-gateway:
	cd src/api-gateway && $(GO) run ./cmd/

run-detection-engine:
	$(CARGO) run -p detection-engine --release

# ─── Packaging ─────────────────────────────────────────────
package-deb:
	dpkg-deb --build deploy/packages/debian gnss-detection_0.1.0_amd64.deb

package-rpm:
	rpmbuild -bb deploy/packages/gnss-detection.spec

package-homebrew:
	brew create --tap quantumworld-dpdns-io/homebrew-gnss https://github.com/quantumworld-dpdns-io/gnss-spoofing-jamming-early-warning/archive/v0.1.0.tar.gz

package-docker: docker-build

# ─── Help ──────────────────────────────────────────────────
help:
	@echo "GNSS Spoofing Detection Makefile"
	@echo "================================"
	@echo "build              - Build all components"
	@echo "test               - Run all tests"
	@echo "test-robot         - Run Robot Framework tests"
	@echo "lint               - Lint all code"
	@echo "format             - Format all code"
	@echo "clean              - Clean build artifacts"
	@echo "docker-build       - Build Docker images"
	@echo "release            - Create semantic release"
	@echo "security-audit     - Run security audits"
	@echo "fuzz               - Run fuzz testing"
	@echo "quantum            - Run quantum tests"
	@echo "dev                - Start development servers"
	@echo "install-hooks      - Install git hooks"
	@echo "package-deb        - Build Debian package"
