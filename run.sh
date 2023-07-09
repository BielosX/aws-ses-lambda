#!/bin/bash

export AWS_REGION="eu-west-1"

function deploy() {
  if [ "$1" == "" ]; then
    echo "Domain name should be provided"
    exit 255
  fi
  if [ "$2" == "" ]; then
    echo "Sandbox TO email should be provided"
    exit 255
  fi
  ./gradlew clean build || exit
  ./gradlew shadowJar || exit
  artifact_path=$(readlink -f build/libs/aws-ses-lambda-all.jar)
  timestamp=$(date +%s)
  artifact_name="aws-ses-lambda-${timestamp}.jar"
  pushd infra/terraform || exit
  terraform init && terraform apply -auto-approve \
    -var "jar-file-path=${artifact_path}" \
    -var "artifact-name=${artifact_name}" \
    -var "ses-domain=$1" \
    -var "sandbox-to-email=$2"
  popd || exit
}

function destroy() {
  pushd infra/terraform || exit
  terraform destroy -auto-approve
  popd || exit
}

case "$1" in
  "deploy") deploy "$2" "$3" ;;
  "destroy") destroy ;;
esac