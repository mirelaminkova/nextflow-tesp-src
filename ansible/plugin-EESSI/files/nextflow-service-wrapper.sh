#!/bin/bash
# Systemd service wrapper: set up EESSI 2025.06 + Nextflow, then idle.

mkdir -p /var/log/nextflow
LOGFILE="/var/log/nextflow/nextflow-service.log"
EESSI_VERSION=2025.06
NEXTFLOW_VERSION=26.04.0

echo "$(date): Starting Nextflow service wrapper" > "$LOGFILE"

# init/bash sets up MODULEPATH/Lmod for the detected architecture.
if [ -f "/cvmfs/software.eessi.io/versions/${EESSI_VERSION}/init/bash" ]; then
    echo "$(date): Sourcing EESSI ${EESSI_VERSION} environment" >> "$LOGFILE"
    source "/cvmfs/software.eessi.io/versions/${EESSI_VERSION}/init/bash" >> "$LOGFILE" 2>&1
else
    echo "$(date): ERROR - EESSI ${EESSI_VERSION} init not found" >> "$LOGFILE"
fi

echo "$(date): Loading Nextflow/${NEXTFLOW_VERSION}" >> "$LOGFILE"
module load "Nextflow/${NEXTFLOW_VERSION}" >> "$LOGFILE" 2>&1
which nextflow >> "$LOGFILE" 2>&1 || echo "$(date): nextflow not found in PATH" >> "$LOGFILE"

echo "$(date): Ready; idling" >> "$LOGFILE"
sleep infinity
