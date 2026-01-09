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

cat >GenerateImage.py <<EOF_END
import argparse

import vertexai
from vertexai.preview.vision_models import ImageGenerationModel

def generate_image(
    project_id: str, location: str, output_file: str, prompt: str
) -> vertexai.preview.vision_models.ImageGenerationResponse:
    """Generate an image using a text prompt.
    Args:
      project_id: Google Cloud project ID, used to initialize Vertex AI.
      location: Google Cloud region, used to initialize Vertex AI.
      output_file: Local path to the output image file.
      prompt: The text prompt describing what you want to see."""

    vertexai.init(project=project_id, location=location)

    model = ImageGenerationModel.from_pretrained("imagen-3.0-generate-002")

    images = model.generate_images(
        prompt=prompt,
        # Optional parameters
        number_of_images=1,
        seed=1,
        add_watermark=False,
    )

    images[0].save(location=output_file)

    return images

generate_image(
    project_id='$PROJECT_ID',
    location='$REGION',
    output_file='image.jpeg',
    prompt='Create an image of a cricket ground in the heart of Los Angeles',
    )

EOF_END

/usr/bin/python3 /home/student/GenerateImage.py

echo "${BG_GREEN}${BOLD}✅ Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
