#!/bin/bash

set -e
set -u
set -o pipefail

echo "Cleaning up service linked role resources"
echo "FAIL" > cleanup-status.txt

echo "This is a no-op as we cannot guarantee that we owned the role in the first place"

echo "OK" > cleanup-status.txt
