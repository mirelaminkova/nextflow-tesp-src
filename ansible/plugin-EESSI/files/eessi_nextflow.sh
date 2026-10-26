# shellcheck shell=bash
# /etc/profile.d/eessi_nextflow.sh -- managed by Ansible (nextflow-tesp-src).
#
# Sets up the EESSI 2025.06 environment and loads Nextflow in interactive
# shells. EESSI's init/bash runs archdetect and sets MODULEPATH/Lmod for this
# node's CPU (zen2/zen3/zen4/intel/neoverse/...), so the same plugin works on
# any SRC flavour.

# Skip non-interactive shells: EESSI init prints a banner to stdout, which
# would corrupt scp/sftp/rsync sessions.
[ -z "$PS1" ] && return

if [ -r /cvmfs/software.eessi.io/versions/2025.06/init/bash ]; then
    # shellcheck source=/dev/null
    source /cvmfs/software.eessi.io/versions/2025.06/init/bash
    module load Nextflow/26.04.0
fi

# Seed a per-user Nextflow config the first time, so runs automatically pick
# up the TES (TESP-API / Pulsar) settings. ~/.nextflow is writable, which
# Nextflow needs for plugin downloads (/etc/nextflow is not).
if [ ! -f "$HOME/.nextflow/config" ] && [ -f /etc/nextflow/nextflow.config ]; then
    mkdir -p "$HOME/.nextflow"
    cp /etc/nextflow/nextflow.config "$HOME/.nextflow/config"
fi
