#!/bin/bash

export BG_GREEN=$(tput setab 2)
export BG_MAGENTA=$(tput setab 5)
export BOLD=$(tput bold)
export RESET=$(tput sgr0)

#----------------------------------------------------start--------------------------------------------------#
echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

read -p "Please input the processor name: " PROCESSOR
export PROCESSOR

export PROJECT_ID=$(gcloud config get-value project)
export REGION=$(gcloud compute project-info describe \
	--format="value(commonInstanceMetadata.items[google-compute-default-region])")
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
ACCESS_TOKEN="$(gcloud auth application-default print-access-token)"
SERVICE_ACCOUNT=$(gcloud storage service-agent --project=$PROJECT_ID)

token() { gcloud auth application-default print-access-token; }

retry() {
	local n=0 max=10 delay=10
	until "$@"; do
		n=$((n + 1))
		if ((n >= max)); then
			echo "Command failed after ${max} attempts: $*" >&2
			return 1
		fi
		echo "Retrying (${n}/${max})..." >&2
		sleep "${delay}"
	done
}

enable_lib() {
	gcloud services enable \
		documentai.googleapis.com \
		cloudfunctions.googleapis.com \
		cloudbuild.googleapis.com \
		geocoding-backend.googleapis.com \
		eventarc.googleapis.com \
		run.googleapis.com \
		--project "${PROJECT_ID}"
}

task1() {
	curl -sS -X POST \
		-H "Authorization: Bearer ${ACCESS_TOKEN}" \
		-H "Content-Type: application/json" \
		-d "{\"display_name\":\"${PROCESSOR}\",\"type\":\"FORM_PARSER_PROCESSOR\"}" \
		"https://documentai.googleapis.com/v1/projects/${PROJECT_ID}/locations/us/processors"

	gcloud projects add-iam-policy-binding $PROJECT_ID \
		--member serviceAccount:$SERVICE_ACCOUNT \
		--role roles/pubsub.publisher

	PROCESSOR_ID=$(curl -X GET \
		-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
		-H "Content-Type: application/json" \
		"https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/us/processors" |
		grep '"name":' |
		sed -E 's/.*"name": "projects\/[0-9]+\/locations\/us\/processors\/([^"]+)".*/\1/')

	export PROCESSOR_ID

}

setup_bigquery() {
  bq --location=US mk -d \
    --description "Form Parser Results" \
    "${PROJECT_ID}:invoice_parser_results" 2>/dev/null || true

  bq mk --table \
    invoice_parser_results.doc_ai_extracted_entities \
    "${HOME}/document-ai-challenge/scripts/table-schema/doc_ai_extracted_entities.json" \
    2>/dev/null || true
}

deploy_function_initial() {
  gcloud functions deploy process-invoices \
    --gen2 \
    --region="${REGION}" \
    --entry-point=process_invoice \
    --runtime=python39 \
    --source=cloud-functions/process-invoices \
    --timeout=400 \
    --env-vars-file=cloud-functions/process-invoices/.env.yaml \
    --trigger-resource="gs://${PROJECT_ID}-input-invoices" \
    --trigger-event=google.storage.object.finalize \
    --service-account="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --allow-unauthenticated
}

deploy_function_update_env() {
  gcloud functions deploy process-invoices \
    --gen2 \
    --region="${REGION}" \
    --entry-point=process_invoice \
    --runtime=python39 \
    --source=cloud-functions/process-invoices \
    --timeout=400 \
    --trigger-resource="gs://${PROJECT_ID}-input-invoices" \
    --trigger-event=google.storage.object.finalize \
    --update-env-vars="PROCESSOR_ID=${PROCESSOR_ID},PARSER_LOCATION=us,PROJECT_ID=${PROJECT_ID}" \
    --service-account="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
}

retry enable_lib
echo "Required APIs enabled."

create_processor_and_iam & pid1=$!
setup_local_and_buckets & pid2=$!
setup_bigquery & pid3=$!

wait "$pid1" "$pid2" "$pid3"


retry deploy_function_initial
retry deploy_function_update_env

gsutil -m cp -r gs://cloud-training/gsp367/* \
  ~/document-ai-challenge/invoices "gs://${PROJECT_ID}-input-invoices/"

echo "${BG_GREEN}${BOLD}✅ Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
