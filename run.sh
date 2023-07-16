#!/bin/bash

export AWS_REGION="eu-west-1"
BACKEND_STACK_NAME="terraform-backend"
export AWS_PAGER=""

function deploy_terraform_backend() {
  pushd infra/terraform || exit
  aws cloudformation deploy --template-file backend.yaml \
    --stack-name "$BACKEND_STACK_NAME" || exit
  popd || exit
}

function get_exports() {
  exports=$(aws cloudformation list-exports | jq -r '.Exports')
}

# 1: CloudFormation exports JSON
function get_backend_bucket() {
  backend_bucket_name=$(jq -r 'map(select(.Name == "TerraformStateBucketName")) | .[0].Value' <<< "$1")
  echo "Backend bucket: ${backend_bucket_name}"
}

# 1: CloudFormation exports JSON
function get_lock_table() {
  lock_table_name=$(jq -r 'map(select(.Name == "TerraformLockTableName")) | .[0].Value' <<< "$1")
  echo "Lock table name: ${lock_table_name}"
}

# 1: CloudFormation exports JSON
function get_artifacts_bucket_name() {
  artifacts_bucket_name=$(jq -r 'map(select(.Name == "artifacts-bucket-name")) | .[0].Value' <<< "$1")
  echo "Artifacts bucket name: ${artifacts_bucket_name}"
}

function deploy_artifacts_bucket_terraform() {
  pushd infra/terraform/modules/artifacts-bucket || exit
  get_exports
  get_backend_bucket "$exports"
  get_lock_table "$exports"
  terraform init -backend-config="bucket=$backend_bucket_name" \
    -backend-config="dynamodb_table=$lock_table_name" || exit
  terraform apply -auto-approve || exit
  artifacts_bucket_name=$(terraform output -raw "bucket-name")
  popd || exit
}

# 1: S3 Bucket Name
function deploy_app() {
  ./gradlew clean build shadowJar || exit
  artifact_path=$(readlink -f build/libs/aws-ses-lambda-all.jar)
  timestamp=$(date +%s)
  artifact_name="aws-ses-lambda-${timestamp}.jar"
  bucket_name="$1"
  aws s3 cp "$artifact_path" "s3://${bucket_name}/${artifact_name}"
}

# 1: SES Domain
# 2: Trusted sandbox TO email
# 3: S3 Artifact Name
# 4: S3 Artifact Bucket ARN
function deploy_lambda_app_terraform() {
  ses_domain="$1"
  sandbox_to_email="$2"
  artifact_name="$3"
  artifact_bucket_arn="$4"
  pushd infra/terraform/modules/lambda-app || exit
  get_exports
  get_backend_bucket "$exports"
  get_lock_table "$exports"
  terraform init -backend-config="bucket=$backend_bucket_name" \
    -backend-config="dynamodb_table=$lock_table_name" || exit
  terraform apply -auto-approve \
    -var "artifact-name=${artifact_name}" \
    -var "artifact-bucket-arn=${artifact_bucket_arn}" \
    -var "ses-domain=${ses_domain}" \
    -var "sandbox-to-email=${sandbox_to_email}" || exit
  popd || exit
}

# 1: SES Domain
# 2: SES Sandbox TO email
function deploy_terraform() {
  deploy_terraform_backend
  deploy_artifacts_bucket_terraform
  ses_domain="$1"
  sandbox_to_email="$2"
  if [ "$ses_domain" = "" ]; then
    echo "SES domain should be provided."
    exit 255
  fi
  if [ "$sandbox_to_email" = "" ]; then
    echo "Sandbox email address should be provided."
    exit 255
  fi
  deploy_app "$artifacts_bucket_name"
  deploy_lambda_app_terraform "$ses_domain" \
    "$sandbox_to_email" \
    "$artifact_name" \
    "$artifacts_bucket_name"
}

# 1: S3 Bucket to clean
function clean_bucket() {
  bucket="$1"
  echo "Cleaning bucket: ${bucket}"
  versions=$(aws s3api list-object-versions \
    --bucket "$bucket" \
    --output=json \
    --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')
  aws s3api delete-objects --bucket "$bucket" --delete "$versions"
}

function destroy_terraform() {
  pushd infra/terraform/modules/lambda-app || exit
  Echo "Destroying lambda-app module"
  terraform destroy -auto-approve || exit
  popd || exit
  pushd infra/terraform/modules/artifacts-bucket || exit
  Echo "Destroying artifacts-bucket module"
  terraform destroy -auto-approve || exit
  popd || exit
  get_exports
  get_backend_bucket "$exports"
  clean_bucket "$backend_bucket_name"
  aws cloudformation delete-stack \
    --stack-name "$BACKEND_STACK_NAME"
  aws cloudformation wait stack-delete-complete \
    --stack-name "$BACKEND_STACK_NAME"
}

NPX="npx ts-node --prefer-ts-exts"

function deploy_cdk_artifacts_bucket() {
  pushd infra/cdk || exit
  cdk bootstrap --app "$NPX bin/artifacts.ts" || exit
  cdk deploy --app "$NPX bin/artifacts.ts" || exit
  popd || exit
}

# 1: SES Domain
# 2: SES Sandbox TO email
# 3: S3 artifact name
function deploy_cdk_lambda_app() {
  pushd infra/cdk || exit
  cdk bootstrap --app "$NPX bin/lambda.ts" \
  -c "domain=$1" \
  -c "sandboxToEmail=$2" \
  -c "artifactName=$3" || exit
  cdk deploy --app "$NPX bin/lambda.ts" \
    -c "domain=$1" \
    -c "sandboxToEmail=$2" \
    -c "artifactName=$3" || exit
  popd || exit
}


function deploy_cdk() {
  ses_domain="$1"
  sandbox_to_email="$2"
  if [ "$ses_domain" = "" ]; then
    echo "SES domain should be provided."
    exit 255
  fi
  if [ "$sandbox_to_email" = "" ]; then
    echo "Sandbox email address should be provided."
    exit 255
  fi
  pushd infra/cdk || exit
  echo "CDK Bootstrap"
  popd || exit
  echo "Deploying artifacts bucket"
  deploy_cdk_artifacts_bucket
  get_exports
  get_artifacts_bucket_name "$exports"
  deploy_app "$artifacts_bucket_name"
  echo "Deploying Lambda App"
  deploy_cdk_lambda_app "$ses_domain" "$sandbox_to_email" "$artifact_name"
}

function destroy_cdk() {
  pushd infra/cdk || exit
  cdk destroy --app "$NPX bin/lambda.ts" \
    -c "domain=temp" \
    -c "sandboxToEmail=temp" \
    -c "artifactName=temp" || exit
  cdk destroy --app "$NPX bin/artifacts.ts" || exit
  popd || exit
}

case "$1" in
  "deploy-terraform") deploy_terraform "$2" "$3" ;;
  "destroy-terraform") destroy_terraform ;;
  "deploy-cdk") deploy_cdk "$2" "$3" ;;
  "destroy-cdk") destroy_cdk ;;
esac