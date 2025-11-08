#!/bin/bash
#----------------------------------------------------start--------------------------------------------------#

echo "🚀 Starting Fast Execution..."

git clone https://github.com/GoogleCloudPlatform/training-data-analyst &>/dev/null &
until [ -d training-data-analyst/blogs ]; do :; done
cd training-data-analyst/blogs || exit 1

PROJECT_ID=$(gcloud config get-value project)
BUCKET=${PROJECT_ID}-bucket

# Create bucket (background)
gsutil mb -c multi_regional gs://${BUCKET} &>/dev/null &

# 🔁 Tunggu sampai bucket siap (tanpa sleep, langsung lanjut begitu ada)
until gsutil ls -b gs://${BUCKET} &>/dev/null; do :; done
echo "✅ Bucket ${BUCKET} is ready!"

# Local ops
mv endpointslambda/Apache2_0License.txt endpointslambda/old.txt &
rm -f endpointslambda/aeflex-endpoints/app.yaml &

# Upload semua paralel (bucket sudah siap)
gsutil -m rsync -d -r endpointslambda gs://${BUCKET}/endpointslambda &
gsutil -m acl set -R -a public-read gs://${BUCKET} &
gsutil cp -s nearline ghcn/ghcn_on_bq.ipynb gs://${BUCKET} &

echo "🎯 All uploads running in parallel (no waiting)"
echo "🎉 Congratulations For Completing The Lab !!!"

#-----------------------------------------------------end----------------------------------------------------------#
