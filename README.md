# qfour-workflows

Shared reusable GitHub Actions workflows for all Qfour repositories.

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

## Security posture

| Control | Implementation |
|---|---|
| Action pinning | All third-party actions pinned to **commit SHA** with version comment. Updated weekly by Dependabot. |
| Default deny permissions | `permissions: {}` at workflow level; each job grants only what it needs. |
| OIDC | ECR push uses `aws-actions/configure-aws-credentials` via OIDC (`id-token: write`). No long-lived AWS keys. |
| Untrusted input | All caller-provided inputs validated by regex before use; `run:` scripts read from `env:` (no `${{ }}` direct interpolation). |
| Token leakage | `actions/checkout` uses `persist-credentials: false`. `GITHUB_TOKEN` is not left on the runner. |
| Timeouts | Every job has `timeout-minutes:` so a hung step cannot consume the runner indefinitely. |
| Concurrency | Self-check (`ci.yaml`) cancels superseded runs on the same ref. |
| Self-lint | `.github/workflows/ci.yaml` runs `actionlint` on every PR to catch drift before `@v1` consumers are affected. |

### Caller input contract

The reusable workflows accept only the following character sets (defense in depth):

| Input | Regex |
|---|---|
| `name` | `^[a-z0-9-]+$` |
| `context`, `dockerfile` | `^[A-Za-z0-9._/-]+$` (no `..`) |
| `sha-tag` | `^[a-f0-9]{7,40}$` |
| `release-tag` | `^v[A-Za-z0-9._-]+$` |
| `registry` | `^[0-9]{12}\.dkr\.ecr\.[a-z0-9-]+\.amazonaws\.com(\.cn)?$` |
| `aws-region` | `^[a-z]{2}-[a-z]+-[0-9]+$` |
| `severity-at-least` | `critical` \| `high` \| `medium` \| `low` |
