#!/bin/bash

# Delete all CSV files in domain-specific folders
find domain1/ domain2/ domain3/ -type f -name "*.csv" -exec rm -f {} \;

# Optionally clean logs (if applicable)
if [ -d "../logs" ]; then
  find ../logs/ -type f -name "*.txt" -exec rm -f {} \;
  echo "All TXT files in ../logs/ have been deleted."
fi

echo "All CSV files in domain1/, domain2/, and domain3/ have been deleted."
