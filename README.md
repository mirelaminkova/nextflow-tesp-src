# Nextflow + TESP on SURF Research Cloud

This repository holds the Ansible playbook for a **Nextflow** component on [SURF Research Cloud](https://portal.live.surfresearchcloud.nl/) (SRC). It installs the [EESSI](https://www.eessi.io/) client, loads Nextflow 26.04.0 from the EESSI 2025.06 stack at login, and configures Nextflow's GA4GH TES executor so pipelines can run on a [TESP workspace](https://github.com/mirelaminkova/TESP-src) (TESP-API in front of Pulsar and SLURM).

The repository started as the `nf-tesp` branch of [mirelaminkova/Nextflow_EESSI](https://github.com/mirelaminkova/Nextflow_EESSI). Only the EESSI/Nextflow plugin and its history were kept.

## What the playbook does

`ansible/plugin-EESSI/plugin-EESSI-client.yml` (the SRC catalog item points at this path, so don't move it):

| Step | Files |
| --- | --- |
| Checks the component parameters before installing anything | `tasks/validate-parameters.yml`, `vars/tes.yml` |
| Checks that the S3 key pair can write to `src_nf_workdir`, also before installing anything | `tasks/check-s3-access.yml`, `files/check-s3-access.py` |
| Installs `lmod` and the EESSI CVMFS client, and checks that `cvmfs_talk` is installed | first play |
| Adds a private Stratum 1 when `src_stratum1_host` is set | `files/template-eessi-hpc.org.local` |
| Loads EESSI 2025.06 and `Nextflow/26.04.0` in interactive login shells | `files/eessi_nextflow.sh` |
| Writes the TESP settings to `/etc/nextflow/tesp.config` | `templates/tesp.config.j2` |

At every login shell (an SSH or desktop login; `ssh host cmd`, `scp` and `sftp` don't read `/etc/profile.d`), the login script creates a missing `~/.nextflow/config` (or `$NXF_HOME/config`, as set before `/etc/profile.d` runs) containing only `includeConfig '/etc/nextflow/tesp.config'`. Re-running the playbook with a new endpoint or password therefore reaches every user. A full copy left by earlier versions of this component is moved to `config.pre-tesp` and replaced the same way; copy any settings you added to it back into `~/.nextflow/config`. Any other config is the user's own and is left alone: add the `includeConfig` line to it yourself. EESSI and Nextflow are only loaded in interactive shells, because EESSI prints a banner that would break `scp`, `sftp` and `rsync`.

## Connecting to TESP

1. Create a [TESP workspace](https://github.com/mirelaminkova/TESP-src) with S3 storage configured (TESP README, "Using S3"). Its welcome page shows the TES base URL (`https://<tesp-workspace>/tes`) and the password for user `tes`.
2. Create the Nextflow workspace with these component parameters:

| Parameter | Default | Secret | Meaning |
| --- | --- | --- | --- |
| `src_tes_endpoint` | empty: TES off | no | TES base URL from the TESP welcome page; `https://` (plain `http://` only for localhost) |
| `src_tes_username` | `tes` | no | TES Basic auth user |
| `src_tes_password` | empty | **yes** | TES Basic auth password; required with an endpoint |
| `src_nf_workdir` | empty | no | Nextflow work directory, `s3://<bucket>/<prefix>` (a prefix is required); required with an endpoint |
| `src_s3_endpoint_url` | empty (AWS S3) | no | Same S3 endpoint as TESP's `src_s3_endpoint_url` |
| `src_s3_region` | `us-east-1` | no | Region to sign requests for |
| `src_s3_access_key_id` | empty | **yes** | S3 access key; set both keys or neither |
| `src_s3_secret_access_key` | empty | **yes** | S3 secret key |
| `src_s3_addressing_style` | `path` | no | `path`, `virtual` or `auto`, as on TESP |
| `src_stratum1_host` | unset | no | Private EESSI Stratum 1 |

3. Log in and run a pipeline. Tasks go to TESP, and the work directory is on S3:

```bash
nextflow run <pipeline>
```

Why the work directory must be on S3: Nextflow's TES executor (nf-ga4gh, pinned to 1.5.0) passes every task file, including `.command.run`, to TESP as a URL. tesp-api downloads `s3://` URLs with presigned requests, and rejects local paths. Nextflow itself reads and writes the same bucket, so give it a key pair that can write there. TESP uses its own key pair.

What pipelines must do on TESP:
- **Containers:** every process needs a `container`; TESP runs it with Apptainer.
- **No glob outputs:** `path '*.txt'` outputs are refused ([mirelaminkova/tesp-api#29](https://github.com/mirelaminkova/tesp-api/issues/29)). Name output files explicitly.
- **Resources:** `cpus` and `memory` become SLURM limits on the single TESP node, so cap them with `process.resourceLimits` to fit it.
- **Run time:** tesp-api stops waiting for a task after about 27 minutes, queue time included.

Without `src_tes_endpoint`, `/etc/nextflow/tesp.config` holds only comments and Nextflow runs tasks locally.

**Who can read the credentials:** `/etc/nextflow/tesp.config` is readable by every account on the workspace (0644), service accounts included, because every user's Nextflow config includes it. It holds:
- the TES password: on SRC everyone who can log in is a member of the CO, the same people who can open the TESP welcome page that shows it;
- the S3 key pair, if set: TESP never shows that key, so this file widens who can read it. Use a key that only grants access to the buckets meant for this work, and don't use this component on a workspace shared beyond the CO.

**S3 check at deploy time:** with TES on and the S3 keys set, the playbook writes a small object under `src_nf_workdir` and deletes it again, before installing anything. A key pair that can't write there fails the deployment with the cause and the parameter to fix, never the key itself, for example:

```text
Can't write to src_nf_workdir s3://nextflow-tesp/test at https://objectstore.surf.nl (InvalidAccessKeyId): src_s3_access_key_id is not a key that https://objectstore.surf.nl knows. Check the CO secret it comes from: ...
```

`InvalidAccessKeyId` and `SignatureDoesNotMatch` mean the CO secret behind `src_s3_access_key_id` or `src_s3_secret_access_key` holds the wrong value: update it in the CO's secrets and recreate the workspace. `AccessDenied` means the key is valid but can't write to that bucket. An endpoint that can't be reached is retried for about a minute first. Without the keys the check is skipped: Nextflow then uses the AWS default credentials of whoever runs it.

**Allowed values:** the playbook validates the parameters (strict URLs without quotes or credentials, a valid bucket name, both S3 keys or neither, no control characters) and escapes them for Groovy. A password or key may contain any printable character except the Ansible template markers `{{`, `{%` and `{#`; leading and trailing whitespace is removed, as in TESP: Ansible evaluates parameters as templates before this playbook sees them. TESP's generated passwords are base64, so they never contain them.

## Checks

Install the hooks once per clone. Linters and unit tests run on commit; ast-grep and semgrep run on push and block it on findings:

```bash
pre-commit install
```

Run everything by hand:

```bash
pre-commit run --all-files
```

```bash
pre-commit run --all-files --hook-stage pre-push
```

| Level | What | Where |
| --- | --- | --- |
| Static | yamllint, ansible-lint (production profile), `ansible-playbook --syntax-check`, shellcheck | `.pre-commit-config.yaml`, `.yamllint`, `.ansible-lint` |
| Static, on push | ast-grep rules (no `ignore_errors`; `no_log` on tasks that use password or secret variables) with their own tests; semgrep `p/github-actions` and `p/secrets` | `sgconfig.yml`, `.ast-grep/` |
| Unit | Ansible playbooks in `tests/` that inspect the plugin, run its login script against a stand-in EESSI, check parameter validation, render the TESP config with hostile values, and check that workflow actions are pinned and that the review workflow keeps its limits (`tests/workflows.yml`); Python tests of the S3 check's request signing (AWS's published SigV4 examples) and error messages; no root, CVMFS or network: `tests/run.sh` | `tests/` |
| End to end | CI only (needs Docker): tesp-api at the commit TESP-src pins, with Pulsar and MinIO, basic auth, and nginx at `/tes/`. The job renders this repo's config template, running the deploy-time S3 check against MinIO, checks that the S3 check rejects an unknown access key and a wrong secret key, seeds the config with the login script, and runs a two-process pipeline with Nextflow 26.04.0 on Java 25 against an `s3://` work dir. It checks the result and that both tasks reached COMPLETE on TES, then checks that a wrong password fails with 401 | `.github/workflows/e2e.yml`, `tests/e2e/` |

CI (`.github/workflows/ci.yml`, `e2e.yml`) runs the same hooks, the unit tests and the end-to-end test, and needs no secrets. Hook and action versions are pinned to commit SHAs; the semgrep rule packs come from the semgrep registry at run time, so they can change without a commit here.

### Automated review

`.github/workflows/claude-review.yml` has Claude ([claude-code-action](https://github.com/anthropics/claude-code-action)) review a PR when it is opened, reopened or marked ready for review, and skips drafts and PRs from forks. It posts inline threads from an adversarial and a quality angle; answer each thread with a fix or a reasoned reply, then resolve it. A review that finds nothing posts nothing; a green `claude-review` run with no threads means it found nothing.

It runs on a Claude subscription. To turn it on, a maintainer adds one repository secret (Settings → Secrets and variables → Actions): `CLAUDE_CODE_OAUTH_TOKEN`, from `claude setup-token`. Reviews count against that subscription's usage. Without the secret, the job skips with a notice. The workflow passes no API key or federation inputs, so the action can't use another credential in place of the token. To review a PR again, mark it as draft and then ready again; each run is a full, paid review. If the review step fails, the job's last step prints the error Claude got (such as an expired token or a usage limit), and not the transcript.

What Claude can do: read the checkout and the PR diff (written to `pr.diff` by the job) and post inline comments. It has no shell, no `gh`, no web access and no subagents; `.git` (where the action stores the job token), `/proc`, `/tmp` and the runner's own directories are denied, and settings or MCP servers in the PR's `.claude/` are not loaded. So PR comments, which anyone can write on this public repository, never reach it, and a comment body is its only output. The job's `GITHUB_TOKEN` can read the code and write to PRs. The diff and files are still model input: someone who can push a branch can steer what the review says, and can change the workflow on their own PR. `tests/workflows.yml` checks these limits against regressions.

Tasks that use password or secret variables carry `no_log: true`, which also hides their error messages. To debug a failing one, set `no_log: false` on that task temporarily, on a workspace whose credentials you may print.
