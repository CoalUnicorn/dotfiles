#! /bin/bash

###############################################################################
#               Script to manage Pathogen plugins for Vim                     #
###############################################################################
set -e
# !!! Change to use relative paths
CONF='/usr/bin/git --git-dir=/home/michal/.cfg/ --work-tree=/home/michal'
$CONF submodule update --init --recursive
$CONF submodule foreach git pull --recurse-submodules origin master
