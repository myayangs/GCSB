#!/bin/bash
#----------------------------------------------------start--------------------------------------------------#

echo "🚀 Starting Fast Execution..."

REGION="$(gcloud config get-value compute/region 2>/dev/null || true)"
REGION="${REGION:-asia-southeast2}"

gcloud compute instance-groups managed create dev-instance-group \
	--template=dev-instance-template \
	--size=1 \
	--region="$REGION"

gcloud compute instance-groups managed set-autoscaling dev-instance-group \
	--region="$REGION" \
	--min-num-replicas=1 \
	--max-num-replicas=3 \
	--target-cpu-utilization=0.6 \
	--mode=on

echo "🎉 Congratulations For Completing The Lab !!!"

#-----------------------------------------------------end----------------------------------------------------------#
