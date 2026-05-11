# qfour-workflows

Shared reusable GitHub Actions workflows for the `falco-ctf-*` repositories.

## Workflows

| File | Purpose | Callers |
|---|---|---|
| `go-test.yaml` | `go vet` + `go test ./...` via Docker | `falco-ctf-app` |
| `kustomize-lint.yaml` | `kustomize build` for all overlays | `falco-ctf-app`, `falco-ctf-platform` |
| `docker-build.yaml` | Build single image + upload artifact | standalone use |
| `sysdig-scan.yaml` | Sysdig CLI scan + SARIF upload | standalone use |
| `image-push.yaml` | Push SHA tag + release tag to ECR | standalone use |
| `image-pipeline.yaml` | **Orchestrator**: build → scan → push for one image | `falco-ctf-app`, `falco-ctf-platform` |

## Actions

| File | Purpose |
|---|---|
| `compute-tag` | Derives image tag from `GITHUB_REF` (SHA or `v*` release tag) |

## Usage

```yaml
jobs:
  build:
    name: build (${{ matrix.name }})
    strategy:
      matrix:
        include:
          - { name: scoreboard, context: ., dockerfile: scoreboard/Dockerfile }
    uses: Qfour/qfour-workflows/.github/workflows/image-pipeline.yaml@v1
    with:
      name: ${{ matrix.name }}
      context: ${{ matrix.context }}
      dockerfile: ${{ matrix.dockerfile }}
      push: ${{ github.event_name == 'push' }}
      registry: ${{ vars.ECR_REGISTRY }}
      aws-region: ${{ vars.AWS_REGION }}
    secrets:
      sysdig-token: ${{ secrets.SYSDIG_SECURE_TOKEN }}
      aws-role-arn: ${{ secrets.AWS_ROLE_ARN }}
```

## Versioning

- `@v1` — moving major tag, receives non-breaking updates automatically
- `@v1.x.y` — pinned release for audit/stability requirements
- `@main` — **do not use in production**

## Tag image strategy

| Event | Tags pushed |
|---|---|
| `push` to `main` | `<registry>/falco-ctf-<name>:<sha7>` |
| `push` tag `v*` | `<registry>/falco-ctf-<name>:<sha7>` AND `<registry>/falco-ctf-<name>:<vtag>` |
| `pull_request` | build + scan only (no push) |

## Required secrets / variables (in caller repo)

| Name | Type | Required for |
|---|---|---|
| `SYSDIG_SECURE_TOKEN` | secret | scan |
| `AWS_ROLE_ARN` | secret | push |
| `ECR_REGISTRY` | variable | push |
| `AWS_REGION` | variable | push |
