#!/bin/bash

export BG_GREEN=$(tput setab 2)
export BG_MAGENTA=$(tput setab 5)
export BOLD=$(tput bold)
export RESET=$(tput sgr0)

#----------------------------------------------------start--------------------------------------------------#
echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

export PROJECT_ID=$(gcloud config get-value project)

curl -L -o world.jpeg https://raw.githubusercontent.com/myayangs/GCSB/refs/heads/main/JuaraGCP-12/Skill-Badges/V.%20Use%20APIs%20to%20Work%20with%20Cloud%20Storage/world.jpeg

cat >bucket.json <<EOF
{  
   "name": "$PROJECT_ID-bucket-1",
   "location": "us",
   "storageClass": "multi_regional"
}
EOF

cat >bucket2.json <<EOF
{  
   "name": "$PROJECT_ID-bucket-2",
   "location": "us",
   "storageClass": "multi_regional"
}
EOF

cat >public_access.json <<EOF
{
    "entity": "allUsers",
    "role": "READER"
}
EOF



curl -X POST \
	-H "Authorization: Bearer $(gcloud auth print-access-token)" \
	-H "Content-Type: application/json" \
	--data-binary @./bucket.json \
	"https://storage.googleapis.com/storage/v1/b?project=$PROJECT_ID"

curl -X POST \
	-H "Authorization: Bearer $(gcloud auth print-access-token)" \
	-H "Content-Type: application/json" \
	--data-binary @./bucket2.json \
	"https://storage.googleapis.com/storage/v1/b?project=$PROJECT_ID"

sleep 10

curl -X POST \
	-H "Authorization: Bearer $(gcloud auth print-access-token)" \
	-H "Content-Type: image/jpeg" \
	--data-binary @./world.jpeg \
	"https://storage.googleapis.com/upload/storage/v1/b/$PROJECT_ID-bucket-1/o?uploadType=media&name=world.jpeg"

curl -X POST \
	--data-binary @public_access.json \
	-H "Authorization: Bearer $(gcloud auth print-access-token)" \
	-H "Content-Type: application/json" \
	"https://storage.googleapis.com/storage/v1/b/$PROJECT_ID-bucket-1/o/world.jpeg/acl"

curl -X POST \
	-H "Authorization: Bearer $(gcloud auth print-access-token)" \
	-H "Content-Type: application/json" \
	--data '{"destination": "$PROJECT_ID-bucket-2"}' \
	"https://storage.googleapis.com/storage/v1/b/$PROJECT_ID-bucket-1/o/world.jpeg/copyTo/b/$PROJECT_ID-bucket-2/o/world.jpeg"

curl -X DELETE \
	-H "Authorization: Bearer $(gcloud auth print-access-token)" \
	"https://storage.googleapis.com/storage/v1/b/$PROJECT_ID-bucket-1/o/world.jpeg"

curl -X DELETE \
	-H "Authorization: Bearer $(gcloud auth print-access-token)" \
	"https://storage.googleapis.com/storage/v1/b/$PROJECT_ID-bucket-1"

echo "${BG_GREEN}${BOLD}✅ Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
