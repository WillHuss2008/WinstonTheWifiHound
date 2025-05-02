#!/bin/bash

# Convert all .sh files to Unix line endings
for file in *.sh; do
    if [ -f "$file" ]; then
        dos2unix "$file"
        chmod +x "$file"
    fi
done 