#!/bin/bash

# Is the user sudo?
if [ "$(id -u)" == 0 ]; then
  echo "You cannot run this script as root."
  exit
fi

IMAGE_NAME=$1
IMAGE_TAG=$2
CONTAINER_HOME=$3
CONTAINER_USER=$4
SHARED_DIR=$5


CONTAINER_ID=$(docker ps -aqf "name=^/${IMAGE_NAME}$")

# Echo back current config
echo "Container name         : ${IMAGE_NAME}"
echo "Container Tag          : ${IMAGE_TAG}"
echo "Container ID           : ${CONTAINER_ID}"
echo "Host data directory    : ${SHARED_DIR}"
# echo "Target data directory  : ${CONTAINER_REPO_DIR}"
echo "Container Home         : ${CONTAINER_HOME}"
echo "*******************************************"
echo "* ALL DATA STORED LOCALLY IN THIS         *"
echo "* CONTAINER WILL BE REFLECTED LOCALLY     *"
echo "*******************************************"
echo ""

if [ -z "${CONTAINER_ID}" ]; then
  echo "Creating new container."
  # Which GPUs to use; see https://github.com/NVIDIA/nvidia-docker
  GPUS="all"

  echo "Sharing screen permissions"
  XSOCK=/tmp/.X11-unix
  XAUTH=/tmp/.docker.xauth
  xhost +local:docker
  touch $XAUTH
  xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -

  echo "Starting image in interactive mode."
  docker run --rm -it --privileged \
    --network host \
    --runtime=nvidia \
    --gpus $GPUS \
    --name $IMAGE_NAME \
    --env "XAUTHORITY=${XAUTH}" \
    --env "DISPLAY=${DISPLAY}" \
    --volume /dev/input:/dev/input:rw \
    --volume $XSOCK:$XSOCK:rw \
    --volume $XAUTH:$XAUTH:rw \
    --user ${CONTAINER_USER} \
    --mount type=bind,src=$SHARED_DIR,dst=$CONTAINER_HOME \
    "${IMAGE_NAME}:${IMAGE_TAG}" /bin/bash
    # --gpus $GPUS \
else
  echo "Found running ${IMAGE_NAME} container, attaching bash..."
  docker exec -it ${CONTAINER_ID} /bin/bash
fi
