# Optimizations and Performance - Session 2 - Demo 2: Terraform CI with GitHub Actions

This demo builds a **GitHub Actions CI pipeline** for a Terraform workspace — one commit at a time — with a PR open the entire time so every push is visible in the Actions tab.

## What students learn

- How to trigger a workflow on pull requests to `main`
- Why the `permissions` block is declared early (`contents: read`, `pull-requests: write`)
- How to pin Marketplace actions to a version (`@v4`, `@v3`) and why floating to `@latest` is unsafe
- Running `terraform fmt --check`, `terraform init`, and `terraform validate` without cloud credentials
- Injecting AWS credentials from repository secrets using `${{ secrets.X }}` syntax
- Capturing `terraform plan` output with `tee` and referencing it across steps
- Posting the plan as a collapsible PR comment using `actions/github-script`
- Why `continue-on-error: true` silently removes a gate step and how the rubric penalizes it

## Project structure

```
.
├── provider.tf                      # AWS provider, Terraform >= 1.8, aws ~> 5.0
├── variables.tf                     # region, environment, app_name, app_version
├── main.tf                          # aws_ssm_parameter resource
├── outputs.tf                       # parameter_name, parameter_arn
├── envs/
│   └── dev/
│       └── dev.tfvars               # dev environment variable values
└── .github/
    └── workflows/
        └── terraform-ci.yml         # fully built CI workflow
```

## Prerequisites

- A GitHub account with access to the repository
- AWS credentials (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`) configured as repository secrets under **Settings → Secrets and variables → Actions**
- No local Terraform installation required — the pipeline runs entirely on GitHub-hosted runners

## Live demo PR

The pipeline was built incrementally across six commits on a feature branch, with a PR open the whole time. **This PR is intentionally left open** so you can browse the Actions history and see each step appear as it was added:

**[PR #1 — ci: Terraform CI pipeline (incremental)](https://github.com/jatitoam/oyd-session2-demo-2-github-actions/pull/1)**

Navigate to the **Checks** tab on that PR to see each workflow run and the growing pipeline. Navigate to the **Comments** section to see the Terraform plan posted as a collapsible block.

## How the pipeline was built (commit by commit)

### Commit 1 — Workflow skeleton

Trigger on PRs to `main`, declare `permissions`, check out the repo.

```yaml
on:
  pull_request:
    branches: [main]

permissions:
  contents: read
  pull-requests: write

steps:
  - uses: actions/checkout@v4
```

### Commit 2 — `terraform fmt --check`

Install Terraform (`hashicorp/setup-terraform@v3`, pinned to `~> 1.8`) and run format check. A formatting error fails the step, blocks the PR, and forces the developer to run `terraform fmt` locally.

### Commit 3 — `terraform init -backend=false`

Downloads provider plugins and sets up the module graph. `-backend=false` skips remote state initialization — the CI runner should never touch a remote backend on every PR.

### Commit 4 — `terraform validate`

Static analysis of the configuration: type checking, missing required variables, invalid resource arguments. No API calls. No credentials needed yet.

### Commit 5 — AWS credentials + `terraform plan`

```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ secrets.AWS_REGION }}

- name: Terraform Plan
  id: plan
  run: terraform plan -var-file=envs/dev/dev.tfvars -no-color 2>&1 | tee plan.txt
```

Credentials live in encrypted repository secrets — never in the YAML file. `tee` writes the plan output to both stdout and `plan.txt` so the next step can read it. The `id: plan` field exposes `steps.plan.outcome` to downstream steps.

### Commit 6 — Post plan as PR comment

```yaml
- name: Post Plan as PR Comment
  uses: actions/github-script@v7
  continue-on-error: true
  with:
    script: |
      const fs = require('fs');
      const plan = fs.readFileSync('plan.txt', 'utf8');
      github.rest.issues.createComment({
        ...context.repo,
        issue_number: context.issue.number,
        body: `<details><summary>Terraform Plan</summary>\n\n\`\`\`\n${plan}\n\`\`\`\n</details>`
      });
```

`pull-requests: write` (declared in commit 1) authorizes the API call. The `<details>` block keeps the comment collapsed by default. `continue-on-error: true` is acceptable here because comment posting is best-effort — the plan already ran and the PR check already passed.

## Key concepts summary

| Concept | Introduced in |
|---|---|
| Workflow trigger on PR to `main` | Commit 1 |
| `permissions` block — declared early | Commit 1 |
| Marketplace action version pinning (`@v4`, `@v3`) | Commit 1–2 |
| `terraform fmt --check` failure and fix cycle | Commit 2 |
| `working-directory` scoping | Commit 2 |
| `-backend=false` rationale | Commit 3 |
| `terraform validate` — static analysis, no API calls | Commit 4 |
| Secrets syntax `${{ secrets.X }}` | Commit 5 |
| `tee` for dual output capture | Commit 5 |
| `id:` field for downstream step reference | Commit 5 |
| `continue-on-error` danger on gate steps | Commit 5 |
| `pull-requests: write` enabling the comment API | Commit 6 |
| `<details>` collapsible block in PR comments | Commit 6 |
| `continue-on-error: true` acceptable on comment step | Commit 6 |

## Expected outcomes

By the end of this demo, students should be able to:

1. Write a GitHub Actions workflow that triggers on pull requests
2. Chain `fmt`, `init`, `validate`, and `plan` steps in the correct order
3. Inject AWS credentials safely using repository secrets
4. Capture and surface Terraform plan output as a PR comment
5. Explain why `continue-on-error` must never appear on a gate step
