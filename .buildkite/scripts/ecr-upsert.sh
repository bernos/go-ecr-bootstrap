#!/bin/bash -e
: ${1?docker image is required as first positional argument}

DOCKER_IMAGE=$1
ECR_REGION=$(cut -d '.' -f 4 <<< "${DOCKER_IMAGE}")
ECR_ACCOUNT_ID=$(cut -d '.' -f 1 <<< "${DOCKER_IMAGE}")
ECR_REGISTRY=$(cut -d '/' -f 1 <<< "${DOCKER_IMAGE}")
ECR_REPOSITORY=$(cut -d '/' -f 2- <<< "${DOCKER_IMAGE}" | cut -d ':' -f 1)
SCRIPT_DIR=$(cd $(dirname $BASH_SOURCE) && pwd)
POLICY_TEXT=$(cat "${SCRIPT_DIR}/ecr-repository-policy.json")
LIFECYCLE_POLICY_TEXT=$(cat "${SCRIPT_DIR}/ecr-repository-lifecycle-policy.json")

EXISTING_REPO_NAME=$(aws ecr describe-repositories       \
                         --registry-id ${ECR_ACCOUNT_ID} \
                         --region ${ECR_REGION}          \
                         --output text                   \
                         --query "repositories[?repositoryName == '${ECR_REPOSITORY}'].repositoryName | [0]")

if [ "${EXISTING_REPO_NAME}" = "None" ]; then

    echo "creating repository for '${DOCKER_IMAGE}'"
    aws ecr create-repository                  \
        --repository-name ${ECR_REPOSITORY} \
        --region ${ECR_REGION}

else
    echo "repository for '${DOCKER_IMAGE}' exists"
fi

echo "setting repository permissions for project ECR repo '${DOCKER_IMAGE}'"
aws ecr set-repository-policy              \
    --registry-id ${ECR_ACCOUNT_ID}        \
    --repository-name ${ECR_REPOSITORY} \
    --policy-text "${POLICY_TEXT}"         \
    --region ${ECR_REGION}

echo "setting repository lifecycle policy for '${DOCKER_IMAGE}'"
aws ecr put-lifecycle-policy                           \
    --registry-id ${ECR_ACCOUNT_ID}                    \
    --repository-name ${ECR_REPOSITORY}             \
    --lifecycle-policy-text "${LIFECYCLE_POLICY_TEXT}" \
    --region ${ECR_REGION}

echo "Logging into ECR"
aws ecr get-authorization-token                      \
    --registry-ids ${ECR_ACCOUNT_ID}                 \
    --region ${ECR_REGION}                           \
    --query 'authorizationData[].authorizationToken' \
    --output text                                    \
    | base64 --decode                                \
    | cut -d: -f2                                    \
    | docker login -u AWS --password-stdin https://${ECR_REGISTRY}
