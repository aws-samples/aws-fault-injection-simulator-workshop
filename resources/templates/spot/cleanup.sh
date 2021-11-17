#!/bin/bash

aws cloudformation delete-stack \
    --stack-name FisSpotTest
aws cloudformation wait stack-delete-complete \
    --stack-name FisSpotTest
