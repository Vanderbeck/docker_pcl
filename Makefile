# Build, run, execute into simulation the environment from this makefile
#
# Author: Lindsay Vanderbeck
# ------------------------------------------------

# Load the build arguments. If a custom .arglist does not exist, use the default arglist
ifneq ("$(wildcard .arglist)","")
	include .arglist
	export $(shell sed 's/=.*//' .arglist)
else
	include .arglist.default
	export $(shell sed 's/=.*//' .arglist.default)
endif

# Define the home directory based on the user 
CONTAINER_HOME := /home/${CONTAINER_USER}

# Get the repo directory to determine if we are on the local machine, or in the container.
REPO_DIRECTORY := $(shell pwd)

# Define the build recipes
.PHONY: build
build:
	./scripts/build.sh \
		${IMAGE_NAME} \
		${IMAGE_TAG} \
		${CONTAINER_HOME} \
		${CONTAINER_USER} \
		${PCL_VERSION} \
		${OPENCV_VERSION}

.PHONY: run
run:
	./scripts/run.sh \
		${IMAGE_NAME} \
		${IMAGE_TAG} \
		${CONTAINER_HOME} \
		${CONTAINER_USER} \
		${SHARED_DIR}
