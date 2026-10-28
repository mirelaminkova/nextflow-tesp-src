# shellcheck shell=bash
# /etc/profile.d/eessi_nextflow.sh -- managed by Ansible (nextflow-tesp-src).
#
# Sets up the EESSI 2025.06 environment and loads Nextflow in interactive
# shells. EESSI's init/bash runs archdetect and sets MODULEPATH/Lmod for this
# node's CPU (zen2/zen3/zen4/intel/neoverse/...), so the same plugin works on
# any SRC flavour.

# Point each user's Nextflow config at the TESP settings the playbook writes,
# so re-running the playbook (new endpoint or password) reaches every user.
# A missing config is created. A full copy left by earlier versions of this
# script (recognised by its first line; users were told to edit it) is moved
# to config.pre-tesp first. Any other config is the user's own and is left
# alone. Nextflow reads $NXF_HOME/config (default ~/.nextflow/config) and needs
# that directory writable anyway: it downloads plugins there. Only the CO's
# group can read the system config; an account outside it loses a config that
# is just the include (seeded when the file was world-readable), which would
# make every nextflow run fail. Failures are ignored: a login must never fail
# here, also not in shells with set -e.
: "${NEXTFLOW_TESP_CONFIG:=/etc/nextflow/tesp.config}"
nxf_user_config="${NXF_HOME:-$HOME/.nextflow}/config"
if [ ! -r "$NEXTFLOW_TESP_CONFIG" ] && [ -e "$NEXTFLOW_TESP_CONFIG" ]; then
    if [ "$(cat "$nxf_user_config" 2>/dev/null)" = "includeConfig '$NEXTFLOW_TESP_CONFIG'" ]; then
        rm -f "$nxf_user_config" 2>/dev/null || :
    fi
elif [ -r "$NEXTFLOW_TESP_CONFIG" ]; then
    if [ "$(head -n 1 "$nxf_user_config" 2>/dev/null)" = '// Managed by Ansible (nextflow-tesp-src). GA4GH TES -> Pulsar via TESP-API.' ]; then
        mv -n "$nxf_user_config" "$nxf_user_config.pre-tesp" 2>/dev/null || :
    fi
    if [ ! -e "$nxf_user_config" ]; then
        { mkdir -p "${nxf_user_config%/config}" &&
            printf "includeConfig '%s'\n" "$NEXTFLOW_TESP_CONFIG" > "$nxf_user_config"; } 2>/dev/null || :
    fi
fi
unset nxf_user_config

# Skip non-interactive shells: EESSI init prints a banner to stdout, which
# would corrupt scp/sftp/rsync sessions.
[ -z "$PS1" ] && return

if [ -r /cvmfs/software.eessi.io/versions/2025.06/init/bash ]; then
    # shellcheck source=/dev/null
    source /cvmfs/software.eessi.io/versions/2025.06/init/bash
    module load Nextflow/26.04.0
fi
