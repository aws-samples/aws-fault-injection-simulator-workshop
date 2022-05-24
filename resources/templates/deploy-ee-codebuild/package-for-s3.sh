#!/bin/bash

echo "Navigate to module definition. For official module:"
echo "- https://admin.eventengine.run/backend/modules/4bbb96f5e7cc46f6beaca519345b642d"
echo
read -p "Press CTRL-C to stop. Any other key to continue"

echo
echo "Select right arrow beside version you would like to upload assets for"
echo "Select Assets Tab"
echo "Copy the S3 path starting with s3:// from the example"
read -p "Paste S3 path here. CTRL-C to stop: " s3_path
echo

# Remove the my-asset.zip tail
s3_path=$( dirname $s3_path )

echo
cd ../../../
pwd
zip -r -x \*\*/node_modules/\* @ /tmp/resources.zip resources/*

echo
echo "Copy & Paste credentials from EE into shell"
echo "Copy resources to S3"
echo "aws s3 cp /tmp/resources.zip ${s3_path}/resources.zip"
echo
echo "Update the commit log in the Readme tab"
echo
