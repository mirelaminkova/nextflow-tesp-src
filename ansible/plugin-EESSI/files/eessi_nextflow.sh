# shellcheck shell=bash
# /etc/profile.d/eessi_nextflow.sh -- managed by Ansible (nextflow-tesp-src).
#
# Sets up the EESSI 2025.06 environment and loads Nextflow in interactive
# shells. EESSI's init/bash runs archdetect and sets MODULEPATH/Lmod for this
# node's CPU (zen2/zen3/zen4/intel/neoverse/...), so the same plugin works on
# any SRC flavour.

# Point each user's Nextflow config at the TESP settings the playbook writes,
# so re-running the playbook (new endpoint or password) reaches every user.
# Only a missing config is created; a user's own config is left alone.
# Nextflow reads $NXF_HOME/config (default ~/.nextflow/config), and needs that
# directory writable anyway: it downloads plugins there.
: "${NEXTFLOW_TESP_CONFIG:=/etc/nextflow/tesp.config}"
nxf_user_config="${NXF_HOME:-$HOME/.nextflow}/config"
if [ ! -e "$nxf_user_config" ] && [ -r "$NEXTFLOW_TESP_CONFIG" ]; then
    mkdir -p "${nxf_user_config%/config}" &&
        printf "includeConfig '%s'\n" "$NEXTFLOW_TESP_CONFIG" > "$nxf_user_config"
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
