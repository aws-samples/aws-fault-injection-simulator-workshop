#!/bin/bash

cat userdata.1 send_metrics.py userdata.2 > userdata.txt
cat userdata.txt | base64 > userdata.b64