#!/usr/bin/env bash

# Build the bash assets
bbuild --out=bin src/main.sh

# Bundle just the bin directory and the README file
tarshc bin README.md
