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

task1() {
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
    prompt='Create an image containing a bouquet of 2 sunflowers and 3 roses',
)
EOF_END

	/usr/bin/python3 /home/student/GenerateImage.py

}

task2(){
cat >genai.py <<EOF_END
import vertexai
from vertexai.generative_models import GenerativeModel, Part, Image, Content
import sys

def analyze_bouquet_image(project_id: str, location: str):
    # Initialize Vertex AI
    vertexai.init(project=project_id, location=location)
    
    # Load the Gemini multimodal model
    model = GenerativeModel("gemini-2.0-flash-001")
    
    # Load image part
    image_path = "/home/student/image.jpeg"
    image_part = Part.from_image(Image.load_from_file(image_path))
    
    # Initial image analysis with streaming
    print("📷 Image Analysis: ", end="", flush=True)
    response_stream = model.generate_content(
        [
            image_part,
            Part.from_text("What is shown in this image?")
        ],
        stream=True
    )
    
    # Print streamed response
    full_response = ""
    for chunk in response_stream:
        if chunk.text:
            print(chunk.text, end="", flush=True)
            full_response += chunk.text
    print("\n")
    
    # Start chat with proper history format
    chat_history = [
        Content(role="user", parts=[image_part, Part.from_text("What is shown in this image?")]),
        Content(role="model", parts=[Part.from_text(full_response)])
    ]
    
    chat = model.start_chat(history=chat_history)
    
# Set your project and location
project_id = "$ID"
location = "$REGION"

# Run the function
analyze_bouquet_image(project_id, location)
EOF_END

/usr/bin/python3 /home/student/genai.py
}

task1 
task2 

echo "${BG_GREEN}${BOLD}✅ Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
