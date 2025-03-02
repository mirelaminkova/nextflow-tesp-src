#!/bin/bash
# This script serves as a wrapper for the Nextflow service

# Source the Nextflow-specific initialization
source /opt/nextflow-eessi-init.sh

# Print Nextflow version for verification
nextflow -version

# Keep the service running
sleep infinity
