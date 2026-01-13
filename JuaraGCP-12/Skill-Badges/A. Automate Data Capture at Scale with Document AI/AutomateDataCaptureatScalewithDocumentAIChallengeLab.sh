#!/bin/bash

export BG_GREEN=$(tput setab 2)
export BG_MAGENTA=$(tput setab 5)
export BOLD=$(tput bold)
export RESET=$(tput sgr0)

#----------------------------------------------------start--------------------------------------------------#
echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

read -p "Processor name: " PROCESSOR

export PROCESSOR
export PROJECT_ID=$(gcloud config get-value project)
export REGION=$(gcloud compute project-info describe \
	--format="value(commonInstanceMetadata.items[google-compute-default-region])")
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
ACCESS_TOKEN="$(gcloud auth application-default print-access-token)"
SERVICE_ACCOUNT=$(gcloud storage service-agent --project=$PROJECT_ID)

enable_api() {
	gcloud services enable "$1" --project "${PROJECT_ID}"
}

enable_api documentai.googleapis.com
enable_api cloudfunctions.googleapis.com
enable_api cloudbuild.googleapis.com
enable_api eventarc.googleapis.com
enable_api geocoding-backend.googleapis.com
enable_api run.googleapis.com

task1() {
	gcloud projects add-iam-policy-binding "$PROJECT_ID" \
		--member "serviceAccount:$SERVICE_ACCOUNT" \
		--role "roles/pubsub.publisher" \
		--quiet

	curl -s -X POST \
		-H "Authorization: Bearer $ACCESS_TOKEN" \
		-H "Content-Type: application/json" \
		-d '{
      "display_name": "'"$PROCESSOR"'",
      "type": "FORM_PARSER_PROCESSOR"
    }' \
		"https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/us/processors"

	PROCESSOR_ID=$(curl -s \
		-H "Authorization: Bearer $ACCESS_TOKEN" \
		"https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/us/processors" |
		grep '"name":' |
		sed -E 's/.*processors\/([^"]+)".*/\1/' |
		head -n 1)

	export PROCESSOR_ID
}

task2() {
	mkdir -p ~/document-ai-challenge

	gsutil -m cp -r gs://spls/gsp367/* ~/document-ai-challenge/

	for suffix in input-invoices output-invoices archived-invoices; do
		gsutil mb -c standard -l "${REGION}" -b on "gs://${PROJECT_ID}-${suffix}" &
	done

	gsutil -m cp -r gs://cloud-training/gsp367/* \
		~/document-ai-challenge/invoices gs://${PROJECT_ID}-input-invoices/

}

task3() {
	bq --location=US mk -d \
		--description "Form Parser Results" \
		"${PROJECT_ID}:invoice_parser_results" 2>/dev/null || true

	bq mk --table \
		invoice_parser_results.doc_ai_extracted_entities \
		"${HOME}/document-ai-challenge/scripts/table-schema/doc_ai_extracted_entities.json" \
		2>/dev/null || true
}

task1 &
task2 &
task3 &

wait

deploy_function1() {
	gcloud functions deploy process-invoices \
		--gen2 \
		--region=$REGION \
		--entry-point=process_invoice \
		--runtime=python311 \
		--service-account=${PROJECT_ID}@appspot.gserviceaccount.com \
		--source=document-ai-challenge/scripts/cloud-functions/process-invoices \
		--timeout=400 \
		--env-vars-file=document-ai-challenge/scripts/cloud-functions/process-invoices/.env.yaml \
		--trigger-resource=gs://${PROJECT_ID}-input-invoices \
		--trigger-event=google.storage.object.finalize --service-account $PROJECT_NUMBER-compute@developer.gserviceaccount.com \
		--allow-unauthenticated
}
deploy_success=false
while [ "$deploy_success" = false ]; do
	if deploy_function1; then
		echo "Function deployed successfully..."
		deploy_success=true
	else
		echo "Retrying..."
	fi
done

deploy_function2() {
	gcloud functions deploy process-invoices \
		--gen2 \
		--region=$REGION \
		--entry-point=process_invoice \
		--runtime=python311 \
		--source=document-ai-challenge/scripts/cloud-functions/process-invoices \
		--timeout=400 \
		--trigger-resource=gs://${PROJECT_ID}-input-invoices \
		--trigger-event=google.storage.object.finalize \
		--update-env-vars=PROCESSOR_ID=${PROCESSOR_ID},PARSER_LOCATION=us,PROJECT_ID=${PROJECT_ID} \
		--service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com
}
deploy_success=false
while [ "$deploy_success" = false ]; do
	if deploy_function2; then
		echo "Function deployed successfully..."
		deploy_success=true
	else
		echo "Retrying..."
	fi
done

gsutil -m cp -r gs://cloud-training/gsp367/* document-ai-challenge/invoices gs://${PROJECT_ID}-input-invoices/

echo "${BG_GREEN}${BOLD}✅ Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
