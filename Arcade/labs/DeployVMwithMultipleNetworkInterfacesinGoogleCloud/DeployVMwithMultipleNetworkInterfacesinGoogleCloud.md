Then run the following commands:

```bash
ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])") && gcloud compute instances create multi-nic-vm --zone=$ZONE --machine-type=e2-medium --network-interface=network=my-vpc1,subnet=subnet-a --network-interface=network=my-vpc2,subnet=subnet-b