# Nextflow + TESP on SURF Research Cloud

This repository holds the Ansible playbook for a **Nextflow** component on [SURF Research Cloud](https://portal.live.surfresearchcloud.nl/) (SRC). It installs the [EESSI](https://www.eessi.io/) client, loads Nextflow 26.04.0 from the EESSI 2025.06 stack at login, and configures Nextflow's GA4GH TES executor so pipelines can run on a [TESP workspace](https://github.com/mirelaminkova/TESP-src) (TESP-API in front of Pulsar and SLURM).

The repository started as the `nf-tesp` branch of [mirelaminkova/Nextflow_EESSI](https://github.com/mirelaminkova/Nextflow_EESSI). Only the EESSI/Nextflow plugin and its history were kept.

## What the playbook does

`ansible/plugin-EESSI/plugin-EESSI-client.yml` (the SRC catalog item points at this path, so don't move it):

| Step | Files |
| --- | --- |
| Installs `lmod` and the EESSI CVMFS client, and checks that `cvmfs_talk` is installed | first play |
| Adds a private Stratum 1 when `src_stratum1_host` is set | `files/template-eessi-hpc.org.local` |
| Loads EESSI 2025.06 and `Nextflow/26.04.0` in interactive login shells | `files/eessi_nextflow.sh` |
| Writes the Nextflow TES config to `/etc/nextflow/nextflow.config`; the login script copies it to `~/.nextflow/config` on first login | first play (inline) |

The login script does nothing in non-interactive shells: EESSI prints a banner, which would break `scp`, `sftp` and `rsync`.

## Component parameters

| Parameter | Default | Secret | Meaning |
| --- | --- | --- | --- |
| `src_stratum1_host` | unset | no | Private EESSI Stratum 1 |
| `src_tes_endpoint` | `http://localhost:8080` | no | TES base URL of the TESP workspace |
| `src_tes_username` | empty | no | TES Basic auth user |
| `src_tes_password` | empty | **yes** | TES Basic auth password |

Connecting to a TESP workspace with an S3 work directory is being reworked in [#2](https://github.com/mirelaminkova/nextflow-tesp-src/issues/2).

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
| Unit | Ansible playbooks in `tests/` that inspect the plugin and run its login script against a stand-in EESSI, without root, CVMFS or network: `tests/run.sh` | `tests/` |
| End to end | Nextflow against a tesp-api stack in CI ([#3](https://github.com/mirelaminkova/nextflow-tesp-src/issues/3)) | not yet |

CI (`.github/workflows/ci.yml`) runs the same hooks and the unit tests, and needs no secrets. Hook and action versions are pinned to commit SHAs; the semgrep rule packs come from the semgrep registry at run time, so they can change without a commit here.

Tasks that use password or secret variables carry `no_log: true`, which also hides their error messages. To debug a failing one, set `no_log: false` on that task temporarily, on a workspace whose credentials you may print.
