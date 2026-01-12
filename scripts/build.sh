#!/bin/bash
# This script is not meant to be called directly. Use the Makefile included.

# Exit on any error
set -e

# Is the user sudo?
if [ "$(id -u)" == 0 ]; then
  echo "You cannot run this script as root."
  exit
fi

# Read arguments
IMAGE_NAME=$1
IMAGE_TAG=$2
CONTAINER_HOME=$3
CONTAINER_USER=$4
PCL_VERSION=$5
OPENCV_VERSION=$6

echo "Permissions for container from host user."
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
echo "USER ID:        $USER_ID"
echo "GROUP ID:       $GROUP_ID"
echo "Container User: $CONTAINER_USER"

# echo "CUDA Variables"
# export CUDA_ARCH_SM=${CUDA_ARCH_BIN//./}
# echo "CUDA_ARCH_BIN:  $CUDA_ARCH_BIN"
# echo ""

echo ""
echo "Building:    ${IMAGE_NAME}:${IMAGE_TAG}"
docker build --progress plain \
  --build-arg PCL_VERSION=${PCL_VERSION} \
  --build-arg CONTAINER_HOME=${CONTAINER_HOME} \
  --build-arg CONTAINER_USER=${CONTAINER_USER} \
  --build-arg USER_ID=${USER_ID} \
  --build-arg GROUP_ID=${GROUP_ID} \
  --build-arg OPENCV_VERSION=${OPENCV_VERSION} \
  -t ${IMAGE_NAME}:${IMAGE_TAG} \
  --target runtime \
  -f Dockerfile .
