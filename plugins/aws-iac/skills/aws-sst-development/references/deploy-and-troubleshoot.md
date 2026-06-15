# Deploying and operating SST v4 stacks

The deploy/operate half of the lifecycle: running deploys safely, recovering from
failures, migrating resources, and the operational contracts (durable aliases,
observability) that keep a deployed stack healthy. Read `authoring.md` for how to
*write* the resources; this is about getting them live and keeping them live.

## Table of contents

- [The deploy commands](#the-deploy-commands)
- [Before every deploy](#before-every-deploy)
- [Resource-type migrations: never single-PR](#resource-type-migrations-never-single-pr)
- [Renaming a physical name within the same type](#renaming-a-physical-name-within-the-same-type)
- [Pulumi state hygiene after a failed deploy](#pulumi-state-hygiene-after-a-failed-deploy)
- [Durable Lambda alias contract](#durable-lambda-alias-contract)
- [Observability as a merge gate](#observability-as-a-merge-gate)
- [CI trigger gotcha](#ci-trigger-gotcha)

## The deploy commands

All via the project's package manager (`npx`, `pnpm exec`, or an npm script —
check `package.json`). From the project root unless the SST app lives in a
subdir:

| Command | What it does |
|---------|--------------|
| `npx sst dev` | Live-reload dev mode; Lambdas run locally against real AWS resources. |
| `npx sst diff --stage <stage>` | Preview the plan (create/update/delete) without applying. Run this before any real deploy. |
| `npx sst deploy --stage <stage>` | Apply the plan to AWS. |
| `npx sst remove --stage <stage>` | Tear down the stack (blocked on `protect: true` stages). |
| `npx sst state ...` | Inspect/repair Pulumi state — see hygiene below. |

`--stage` controls the deployment target. `prod` is special (retain/protect);
ephemeral `pr-<n>` stages back PR previews and must work from a cold start.

## Before every deploy

1. **Confirm the target account.** `aws sts get-caller-identity` — a deploy goes
   wherever your credentials point. The skill's PreToolUse hook surfaces the
   account once per session; still eyeball it for prod.
2. **Run `npx sst diff`** and read the plan. Look for unexpected **replacements**
   (Pulumi printing `+-` / "replace") — a replacement on a stateful resource
   (bucket, table) means data loss or a name rotation. If you see one you didn't
   intend, stop and find out why (usually a changed logical name or an immutable
   field).
3. **Type-check and test** — `tsc --noEmit` and the infra Vitest suite
   (`testing.md`). The `Output<T>` interpolation bug type-checks clean but fails
   at deploy, so green types are necessary, not sufficient.
4. **Flag irreversibility to the user** for prod deploys, `sst remove`, and any
   migration. State the account and stage.

## Resource-type migrations: never single-PR

**Rule: when an existing AWS resource changes Pulumi *type* — e.g.
`aws.cloudcontrol.Resource` → typed `aws.bedrock.AgentcoreGateway`, or any change
of the type token at the same logical name — never put the destroy of the old
resource and the create of the new one in the same PR/deploy.** Split into two
sequential deploys:

1. **PR-A (teardown):** remove *only* the old resource declaration. Deploy
   destroys the AWS resource cleanly, freeing the AWS-side name.
2. **PR-B (recreate):** introduce the new typed resource. Deploy creates into a
   clean namespace — no conflict.

### Why

Pulumi treats a type change as **create-new + destroy-old, and creates first**.
If the AWS-side name (anything that must be unique per account — an AgentCore
Gateway, an IAM role, an S3 bucket, an ECR repo) is still owned by the old
resource at create time, the deploy fails with `ConflictException` /
`ValidationException` / 409 / 400 and leaves the stack half-deployed.

- `replaceOnChanges: [...]` + `deleteBeforeReplace: true` **only work within one
  resource type.** For a type-token change Pulumi sees two unrelated resources, so
  they do nothing.
- `dependsOn` doesn't help either — there's no source-side handle on the
  not-yet-deleted old resource.

### The cost, and how to plan it

The price is a **gap window** between PR-A's deploy finishing and PR-B's deploy
finishing, during which the AWS resource doesn't exist. For a public surface
(e.g. a gateway URL) that's downtime.

- Open PR-B back-to-back and have it ready to merge the instant PR-A's deploy
  completes.
- Notify external consumers if the resource is user-facing.
- Internal tooling that resolves the resource via SSM self-heals on next call.

This pattern turns a non-deterministic outage into a planned ~minutes window.

## Renaming a physical name within the same type

Even when the type is unchanged and Pulumi *would* support `deleteBeforeReplace`,
prefer two reversible steps over a single delete-before-replace:

1. PR-A: rename to a temporary distinct physical name.
2. PR-B: rename back to the desired physical name.

Single-step renames that depend on `deleteBeforeReplace` work in theory but are
sensitive to AWS-side delete latency that can outlast Pulumi's update timeout,
leaving you stuck mid-replace.

## Pulumi state hygiene after a failed deploy

When a deploy fails mid-flight, inspect state before re-running:

```bash
# (use the repo's package manager; -C infra if the app is in a subdir)
npx sst state export --stage <stage> > /tmp/state.json
jq '.latest.resources | map(.urn)' /tmp/state.json | grep <relevant-name>
```

- A failed **Create** usually leaves *no* partial entry — Pulumi's rollback is
  clean; just fix the cause and re-deploy.
- A failed **Delete** may leave the entry in state while the AWS resource is
  already gone. Recovery is `sst state remove <urn>` (not hand-editing the JSON).
- **Do not** edit the exported state file and re-import. Use `sst state remove` /
  `pulumi import` for state surgery — manual edits corrupt the checkpoint.

**Always delete the exported state file when done** — it contains account IDs and
identifiers that must not linger:

```bash
rm -f /tmp/state.json
```

## Durable Lambda alias contract

(Applies only to projects using durable/long-running Lambdas — `durable: true`.)

**Invoke durable Lambdas through a published alias (`live`), never `$LATEST`.**
Every `UpdateFunctionConfiguration` advances `$LATEST` and silently orphans
in-flight durable executions started against the prior code — no `Errors` metric,
no `FunctionError`, they just vanish. When adding a `durable: true` Lambda:

1. Provision an `aws.lambda.Alias` named `live` next to the function (raw Pulumi —
   SST has no first-class alias), with `{ ignoreChanges: ["functionVersion"] }`
   so deploys don't reconcile the rotation script's writes back. The bootstrap
   target is the sharp part: a fresh stage has no numbered version yet, so you
   either (a) point the alias at `"$LATEST"` as a placeholder and let the
   post-deploy rotation move it to a numbered version (verify your AWS region
   accepts `$LATEST` on `CreateAlias` — some setups reject it), or (b) publish a
   numbered version first (`aws.lambda.FunctionVersion`, or a CLI
   `publish-version`) and point the alias at `"1"`. Either way, `ignoreChanges`
   keeps subsequent deploys from clobbering the rotated value.
2. Have the deploy pipeline run `aws lambda publish-version` +
   `update-alias --name live` *after* every deploy (prod and preview, so previews
   exercise the same contract).
3. Source any build identity (commit SHA, feature flag) at *runtime*, not in the
   Lambda env — otherwise every deploy advances `$LATEST` even with no code change.

## Observability as a merge gate

These projects require every new Lambda / queue / schedule to ship with
monitoring *before* merge — cheap insurance against a silent prod regression.
Whether you enforce it is per-project, but the checklist is sound:

- **New Lambda?** Add it to an error-alarm segment in `infra/observability.ts`
  (keep the segment map `as const` so a typo fails at typecheck, not at the pager).
- **Structured logging.** Use Powertools `Logger` (set `POWERTOOLS_SERVICE_NAME`);
  emit `service` + `errorType` on error paths. Avoid bare `console.error` in
  Lambda code — it bypasses the JSON formatter your metric filters match on.
- **Custom metrics carry a `stage` dimension** and alarms filter on the literal
  `stage: "prod"`. Without this, a `pr-<n>` preview Lambda writes into the same
  metric slot as prod and trips a prod alarm on preview traffic. Set the `stage`
  dimension as a Powertools *default dimension* (read once from `process.env.STAGE`)
  so "forgot to tag stage" is structurally impossible; hard-code `"prod"` in the
  alarm (not `${stage}`) so preview alarms don't page.
- **DLQs / Step Functions / schedules** each get a failure alarm, ideally rolled
  into a composite pipeline-health alarm.
- **Set `treatMissingData: "notBreaching"`** on alarms so a quiet metric doesn't
  alarm on absence.

## CI trigger gotcha

A common GitHub Actions deploy workflow declares
`on: pull_request: types: [opened, synchronize, reopened, closed]` — note there's
no `edited`. So `gh pr edit <num> --base main` (re-basing a stacked PR onto main)
does **not** re-trigger the deploy workflow. Force it with a rebase + force-push
(fires `synchronize`) or an empty commit (`git commit --allow-empty`). This bites
when you stack infra PRs for a two-PR migration.
