#!/bin/bash

export BG_GREEN=$(tput setab 2)
export BG_MAGENTA=$(tput setab 5)
export BOLD=$(tput bold)
export RESET=$(tput sgr0)

#----------------------------------------------------start--------------------------------------------------#
echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

export PROJECT_ID=$(gcloud config get-value project)
export REGION=$(gcloud compute project-info describe \
	--format="value(commonInstanceMetadata.items[google-compute-default-region])")

export GOOGLE_CLOUD_PROJECT=''"${PROJECT_ID}"''
export GOOGLE_CLOUD_LOCATION=''"${REGION}"''
export GOOGLE_GENAI_USE_VERTEXAI=True

cat >genai.py <<EOF_END
from google import genai
from google.genai.types import HttpOptions, Part

client = genai.Client(http_options=HttpOptions(api_version="v1"))
response = client.models.generate_content(
    model="gemini-2.0-flash-001",
    contents=[
        "What is shown in this image?",
        Part.from_uri(
            file_uri="https://storage.googleapis.com/cloud-samples-data/generative-ai/image/scones.jpg",
            mime_type="image/jpeg",
        ),
    ],
)
print(response.text)
EOF_END

/usr/bin/python3 /home/student/genai.py

echo "${BG_GREEN}${BOLD}✅ Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
