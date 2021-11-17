#!/bin/bash

aws cloudformation delete-stack \
    --stack-name FisStackAccessControls
aws cloudformation wait stack-delete-complete \
    --stack-name FisStackAccessControls