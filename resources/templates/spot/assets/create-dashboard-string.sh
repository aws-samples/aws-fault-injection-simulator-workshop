#!/bin/bash

# Replace region with template placeholder and compact to string
jq -c '.widgets[].properties.region = "${AWS::Region}"' dashboard.json \
| sed "s/^/'/; s/$/'/;" \
| sed 's/^/!Sub /' 