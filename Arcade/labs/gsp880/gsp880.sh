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

mkdir -p ff-app && cd ff-app

cat >package.json <<EOF
{
  "name": "ff-app",
  "version": "1.0.0",
  "description": "Functions Framework App",
  "main": "index.js",
  "scripts": {
    "start": "functions-framework --target=validateTemperature"
  },
  "license": "ISC"
}
EOF

cat >index.js <<'EOF'
exports.validateTemperature = async (req, res) => {
  try {
    if (!req.body.temp) {
      throw "Temperature is undefined\n";
    }
    if (req.body.temp < 100) {
      res.status(200).send("Temperature OK\n");
    } else {
      res.status(200).send("Too hot\n");
    }
  } catch (error) {
    console.error("got error: ", error);
    res.status(500).send(error);
  }
};
EOF

npm install @google-cloud/functions-framework

gcloud functions deploy validateTemperature \
    --trigger-http \
    --runtime nodejs20 \
    --gen2 \
    --allow-unauthenticated \
    --region "$REGION" \
    --service-account "developer-sa@$PROJECT_ID.iam.gserviceaccount.com"

echo "${BG_GREEN}${BOLD}✅ Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
