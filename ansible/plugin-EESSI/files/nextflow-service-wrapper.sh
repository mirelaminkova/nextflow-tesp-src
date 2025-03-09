#!/bin/bash

# Create log directory for Nextflow service logs
mkdir -p /var/log/nextflow
LOGFILE="/var/log/nextflow/nextflow-service.log"

# Start logging
echo "$(date): Starting Nextflow service wrapper" > $LOGFILE
echo "$(date): Script executed with proper shebang" >> $LOGFILE
echo "Initial PATH: $PATH" >> $LOGFILE

# Set environment variables for EESSI: define MODULEPATH and LMOD_LUA_PATH
export MODULEPATH="/cvmfs/software.eessi.io/versions/2023.06/software/linux/x86_64/amd/zen2/modules/all:/cvmfs/software.eessi.io/host_injections/2023.06/software/linux/x86_64/amd/zen2/modules/all"
export LMOD_LUA_PATH="/usr/share/lmod/lmod/libexec/?.lua;/usr/share/lmod/lmod/libexec/?/init.lua"

# Source the EESSI initialization script (which sets up Lmod)
if [ -f /cvmfs/software.eessi.io/versions/2023.06/init/bash ]; then
    echo "$(date): Sourcing EESSI init file" >> $LOGFILE
    source /cvmfs/software.eessi.io/versions/2023.06/init/bash >> $LOGFILE 2>&1
else
    echo "$(date): EESSI init file not found" >> $LOGFILE
    ls -la /cvmfs/software.eessi.io/versions/2023.06/ >> $LOGFILE 2>&1
fi

echo "$(date): MODULEPATH after sourcing: $MODULEPATH" >> $LOGFILE

# Load the Nextflow module automatically
echo "$(date): Loading Nextflow module" >> $LOGFILE
module load Nextflow/23.10.0 >> $LOGFILE 2>&1

# Verify that Nextflow is available
echo "$(date): Checking Nextflow executable" >> $LOGFILE
which nextflow >> $LOGFILE 2>&1

# Keep service running (or replace the sleep with further Nextflow commands as needed)
echo "$(date): Starting sleep loop" >> $LOGFILE
sleep infinity
