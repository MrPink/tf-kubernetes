# create key
aws kms --region=us-west-1 create-key --description="kube-aws assets"

# Create alias 
aws kms create-alias --profile KeyAdmin --alias-name alias/SensitivePANKey --target-key-id
