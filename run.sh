#!/bin/bash

export AWS_REGION="eu-west-1"

function deploy() {
  ./gradlew clean build || exit
  ./gradlew shadowJar || exit
  artifact_path=$(readlink -f build/libs/aws-ses-lambda-all.jar)
  timestamp=$(date +%s)
  artifact_name="aws-ses-lambda-${timestamp}.jar"
  pushd infra/terraform || exit
  terraform init && terraform apply -auto-approve \
    -var "jar-file-path=${artifact_path}" \
    -var "artifact-name=${artifact_name}"
  popd || exit
}

function destroy() {
  pushd infra/terraform || exit
  terraform destroy -auto-approve
  popd || exit
}

case "$1" in
  "deploy") deploy ;;
  "destroy") destroy ;;
esac