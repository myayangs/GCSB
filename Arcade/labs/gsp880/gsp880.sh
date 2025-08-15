#!/bin/bash

export BLACK=$(tput setaf 0)
export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export YELLOW=$(tput setaf 3)
export BLUE=$(tput setaf 4)
export MAGENTA=$(tput setaf 5)
export CYAN=$(tput setaf 6)
export WHITE=$(tput setaf 7)
export BG_BLACK=$(tput setab 0)
export BG_RED=$(tput setab 1)
export BG_GREEN=$(tput setab 2)
export BG_YELLOW=$(tput setab 3)
export BG_BLUE=$(tput setab 4)
export BG_MAGENTA=$(tput setab 5)
export BG_CYAN=$(tput setab 6)
export BG_WHITE=$(tput setab 7)
export BOLD=$(tput bold)
export RESET=$(tput sgr0)

#----------------------------------------------------start--------------------------------------------------#

echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

export PROJECT_ID=$(gcloud config get-value project)

export REGION=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-region])")

mkdir -p ff-app && cd ff-app

echo '{
  "name": "ff-app",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}' >package.json

npm install @google-cloud/functions-framework

cat > index.js <<'EOF'
exports.validateTemperature = async (req, res) => {

 try {

   // add this if statement below line #2
   if (!req.body.temp) {
     throw "Temperature is undefined \n";
   }

   if (req.body.temp < 100) {
     res.status(200).send("Temperature OK \n");
   } else {
     res.status(200).send("Too hot \n");
   }
 } catch (error) {
   //return an error
   console.log("got error: ", error);
   res.status(500).send(error);
 }
};
EOF

gcloud functions deploy validateTemperature \
  --trigger-http \
  --runtime nodejs20 \
  --gen2 \
  --allow-unauthenticated \
  --region $REGION \
  --service-account developer-sa@$PROJECT_ID.iam.gserviceaccount.com


echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
