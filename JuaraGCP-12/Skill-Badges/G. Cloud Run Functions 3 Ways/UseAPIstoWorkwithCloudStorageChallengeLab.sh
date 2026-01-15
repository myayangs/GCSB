#!/bin/bash

export BG_GREEN=$(tput setab 2)
export BG_MAGENTA=$(tput setab 5)
export BOLD=$(tput bold)
export RESET=$(tput sgr0)

#----------------------------------------------------start--------------------------------------------------#
echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

read -p "HTTP function name: " HTTP_FUNCTION </dev/tty
read -p "Cloud Storage function name: " STORAGE_FUNCTION </dev/tty

export PROJECT_ID=$(gcloud config get-value project)
export REGION=$(gcloud compute project-info describe \
	--format="value(commonInstanceMetadata.items[google-compute-default-region])")
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
export SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_NUMBER)
export BUCKET="gs://$PROJECT_ID"
export HTTP_FUNCTION
export STORAGE_FUNCTION

enable_lib() {
	gcloud services enable \
		artifactregistry.googleapis.com \
		cloudfunctions.googleapis.com \
		cloudbuild.googleapis.com \
		eventarc.googleapis.com \
		run.googleapis.com \
		logging.googleapis.com \
		pubsub.googleapis.com \
		--project $PROJECT_ID
}

lib_enabled=false
while [ "$lib_enabled" = false ]; do
	if enable_lib; then
		echo "Required Library Enabled"
		lib_enabled=true
	else
		echo "Re-trying to enable required APIs..."
	fi
done

gcloud projects add-iam-policy-binding $PROJECT_ID \
	--member serviceAccount:$SERVICE_ACCOUNT \
	--role roles/pubsub.publisher

gsutil mb -l $REGION gs://$PROJECT_ID

task1() {
	mkdir ~/$STORAGE_FUNCTION && cd $_

	cat >index.js <<EOF
const functions = require('@google-cloud/functions-framework');
functions.cloudEvent('$STORAGE_FUNCTION', (cloudevent) => {
  console.log('A new event in your Cloud Storage bucket has been logged!');
  console.log(cloudevent);
});
EOF

	cat >package.json <<EOF
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

	deploy_function() {
		gcloud functions deploy $STORAGE_FUNCTION \
			--gen2 \
			--runtime nodejs20 \
			--entry-point $STORAGE_FUNCTION \
			--source . \
			--region $REGION \
			--trigger-bucket $BUCKET \
			--trigger-location $REGION \
			--max-instances 2}
	}

	deploy_success=false
	while [ "$deploy_success" = false ]; do
		if deploy_function; then
			echo "Function deployed successfully..."
			deploy_success=true
		else
			echo "Retrying ..."
		fi
	done

}

task2() {
	mkdir ~/$HTTP_FUNCTION && cd $_

	cat >index.js <<EOF
const functions = require('@google-cloud/functions-framework');
functions.http('$HTTP_FUNCTION', (req, res) => {
  res.status(200).send('subscribe to quikclab');
});
EOF

	cat >package.json <<EOF
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

	deploy_function() {
		gcloud functions deploy $HTTP_FUNCTION \
			--gen2 \
			--runtime nodejs20 \
			--entry-point $HTTP_FUNCTION \
			--source . \
			--region $REGION \
			--trigger-http \
			--timeout 600s \
			--max-instances 2 \
			--min-instances 1
	}

	deploy_success=false
	while [ "$deploy_success" = false ]; do
		if deploy_function; then
			echo "Function deployed successfully..."
			deploy_success=true
		else
			echo "Retrying ..."
		fi
	done

}

task1 &
task2 &

echo "${BG_GREEN}${BOLD}✅ Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
