#!/bin/bash
# Set up the EESSI 2025.06 environment and load Nextflow.
#
# Sourcing init/bash runs archdetect and configures MODULEPATH/Lmod for whatever
# CPU this node has, so we don't hardcode an architecture-specific path.
source /cvmfs/software.eessi.io/versions/2025.06/init/bash
module load Nextflow/26.04.0
