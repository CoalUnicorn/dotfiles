#! /bin/bash
set -e

conf submodule update --init --recursive
conf submodule foreach git pull --recurse-submodules origin master
