#!/bin/bash
#----------------------------------------------------start--------------------------------------------------#

echo "🚀 Starting Fast Execution..."

PROJECT_ID=$(gcloud config get-value project)
BUCKET=${PROJECT_ID}-bucket

gsutil mb -c multi_regional gs://${BUCKET} &

mkdir -p endpointslambda && cd $_

curl -s "https://api.github.com/repos/myayangs/GCSB/contents/Arcade/labs/ManageStorageConfigurationusinggsutil/endpointslambda" |
	grep '"download_url":' |
	cut -d '"' -f 4 |
	xargs -n 1 -P 5 wget -q

gsutil -m cp -r . gs://${BUCKET}/endpointslambda &

mv Apache2_0License.txt old.txt 2>/dev/null &
rm -f aeflex-endpoints/app.yaml 2>/dev/null &

gsutil -m rsync -d -r . gs://${BUCKET}/endpointslambda &
gsutil -m acl set -R -a public-read gs://${BUCKET} &

gsutil cp -s nearline ghcn_on_bq.ipynb gs://${BUCKET} &

wait

echo "🎯 All uploads done in parallel (no waiting)"
echo "🎉 Congratulations For Completing The Lab !!!"

#-----------------------------------------------------end----------------------------------------------------------#
