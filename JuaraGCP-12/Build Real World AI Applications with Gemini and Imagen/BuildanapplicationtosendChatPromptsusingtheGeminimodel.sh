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

cat > SendChatwithoutStream.py <<EOF_END
from google import genai
from google.genai.types import HttpOptions, ModelContent, Part, UserContent

import logging
from google.cloud import logging as gcp_logging

# Initialize GCP logging
gcp_logging_client = gcp_logging.Client()
gcp_logging_client.setup_logging()

client = genai.Client(
    vertexai=True,
    project='${PROJECT_ID}',
    location='${REGION}',
    http_options=HttpOptions(api_version="v1")
)
chat = client.chats.create(
    model="gemini-2.0-flash-001",
    history=[
        UserContent(parts=[Part(text="Hello")]),
        ModelContent(
            parts=[Part(text="Great to meet you. What would you like to know?")],
        ),
    ],
)
response = chat.send_message("What are all the colors in a rainbow?")
logging.info(f'Received response 1: {response.text}') # Added logging
print(response.text)

response = chat.send_message("Why does it appear when it rains?")
logging.info(f'Received response 2: {response.text}') # Added logging
print(response.text)

EOF_END

/usr/bin/python3 /home/student/SendChatwithoutStream.py


cat > SendChatwithStream.py <<EOF_END
from google import genai
from google.genai.types import HttpOptions

import logging
from google.cloud import logging as gcp_logging

# Initialize GCP logging
gcp_logging_client = gcp_logging.Client()
gcp_logging_client.setup_logging()

client = genai.Client(
    vertexai=True,
    project='${PROJECT_ID}',
    location='${REGION}',
    http_options=HttpOptions(api_version="v1")
)
chat = client.chats.create(model="gemini-2.0-flash-001")
response_text = ""

logging.info("Sending streaming prompt...") # Added logging
print("Streaming response:") # Added for clarity
for chunk in chat.send_message_stream("What are all the colors in a rainbow?"):
    print(chunk.text, end="")
    response_text += chunk.text
print() # Add a newline after streaming output
logging.info(f"Received full streaming response: {response_text}") # Added logging

EOF_END

/usr/bin/python3 /home/student/SendChatwithStream.py

echo "${BG_GREEN}${BOLD}✅ Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
