#!/bin/bash
# Builds all the images and then pushes them if --push is passed
#
# The images have the following hierahy:
# Dockerfile.scala-cli - base image which installed coursier, then uses that to install scala-cli (publishes to gumjoe/scala-cli)
# |- Dockerfile.slim: Installs common dependecies to all groups: namely Scala Test & Parsley (publishes to gumjoe/wacc-ci-scala:slim)
# 	|- Dockerfile.uber: Installs all the compilers & QEMU simulators for all the various WACC backends (publishes to gumjoe/wacc-ci-scala:uber & gumjoe/wacc-ci-scala:uber-nodeps (nodeps uses scala-cli as base, regular uses slim))
# 	|- Dockerfile: Install compilers & simulators for various WACC backends depending on build args (publishes to gumjoe/wacc-ci-scala:x86, gumjoe/wacc-ci-scala:arm32, gumjoe/wacc-ci-scala:arm64 as needed)
#

# x86 compiler
# x86 doesn't need qemu, so we specify a dummy package
TAG_x86="x86"
BUILD_ARGS_x86="--build-arg COMPILER=gcc --build-arg TEST_COMMAND=gcc --build-arg QEMU_PACKAGE=curl --build-arg QEMU_TEST_COMMAND=curl"

# arm32 - arm-linux-gnueabihf-gcc
TAG_arm32="arm32"
BUILD_ARGS_arm32="--build-arg COMPILER=gcc-arm-linux-gnueabi --build-arg TEST_COMMAND=arm-linux-gnueabi-gcc --build-arg QEMU_PACKAGE=qemu-user --build-arg QEMU_TEST_COMMAND=qemu-arm"

# arm64 - aarch64-linux-gnu-gcc
TAG_arm64="arm64"
BUILD_ARGS_arm64="--build-arg COMPILER=gcc-aarch64-linux-gnu --build-arg TEST_COMMAND=aarch64-linux-gnu-gcc --build-arg QEMU_PACKAGE=qemu-user --build-arg QEMU_TEST_COMMAND=qemu-aarch64"

# Change this as needed
VERSION="2.2.1"

IMAGE_BASE_NAME="gumjoe/wacc-ci-scala"
IMAGE_SCALA_CLI_NAME="gumjoe/scala-cli"

DOCKERFILE="Dockerfile"
DOCKERFILE_SLIM="Dockerfile.slim"
DOCKERFILE_SCALA_CLI="Dockerfile.scala-cli"
DOCKERFILE_UBER="Dockerfile.uber"

TAG_slim="slim"
TAG_uber="uber"
TAG_uber_nodeps="uber-nodeps"


TAG_TO_GET_LATEST_FROM="uber-nodeps"
UBER_BASE_IMAGE="$IMAGE_BASE_NAME:$VERSION-$TAG_slim"

# Check if docker is installed
if ! [ -x "$(command -v docker)" ]; then
	echo "[!] Docker is not installed. Please install docker and try again."
	exit 1
fi

# Check if docker is running
if ! docker info >/dev/null 2>&1; then
	echo "[!] Docker is not running. Please start docker and try again."
	exit 1
fi

# Check if docker image exists
echo Checking if docker image exists...
if docker images | grep -qE "$IMAGE_BASE_NAME\s+$VERSION-$TAG_uber_nodeps"; then
	echo "[!] Docker image found! Please increment the version number and try again."
	exit 1
fi

# From here on out fail the who script if one command fails
set -e

# Build scala-cli image used by all
echo "===> Building scala-cli image as the base of everything..."
echo "===> Building image $IMAGE_SCALA_CLI_NAME:$VERSION"
docker build -f $DOCKERFILE_SCALA_CLI -t "$IMAGE_SCALA_CLI_NAME:$VERSION" .
echo "===> Tagging as latest"
docker tag "$IMAGE_SCALA_CLI_NAME:$VERSION" "$IMAGE_SCALA_CLI_NAME:latest"

# Build slim image needed by all later stages
echo "===> Building slim image..."
echo "===> Building image $IMAGE_BASE_NAME:$VERSION-slim"
docker build -f $DOCKERFILE_SLIM -t "$IMAGE_BASE_NAME:$VERSION-slim" .
echo "===> Tagging as slim"
docker tag "$IMAGE_BASE_NAME:$VERSION-slim" "$IMAGE_BASE_NAME:slim"

# Build docker images for each architecture
echo "===> Building docker images..."
echo "===> Building image $IMAGE_BASE_NAME:$VERSION-$TAG_x86"
docker build -f $DOCKERFILE -t "$IMAGE_BASE_NAME:$VERSION-$TAG_x86" $BUILD_ARGS_x86 .

echo "===> Building image $IMAGE_BASE_NAME:$VERSION-$TAG_arm32"
docker build -f $DOCKERFILE -t "$IMAGE_BASE_NAME:$VERSION-$TAG_arm32" $BUILD_ARGS_arm32 .

echo "===> Building image $IMAGE_BASE_NAME:$VERSION-$TAG_arm64"
docker build -f $DOCKERFILE -t "$IMAGE_BASE_NAME:$VERSION-$TAG_arm64" $BUILD_ARGS_arm64 .

# Uber images
echo "===> Building uber images..."
echo "===> Building uber images with deps"
echo "===> Building uber image $IMAGE_BASE_NAME:$VERSION-$TAG_uber"
docker build -f $DOCKERFILE_UBER -t "$IMAGE_BASE_NAME:$VERSION-$TAG_uber" --build-arg BASE_IMAGE="$UBER_BASE_IMAGE" .
echo "===> Building uber image with no prebundled deps"
docker build -f $DOCKERFILE_UBER -t "$IMAGE_BASE_NAME:$VERSION-$TAG_uber_nodeps" --build-arg BASE_IMAGE="$IMAGE_SCALA_CLI_NAME:$VERSION" .

# Generate latest images
# echo "===> Generating latest images..."
echo "===> Tagging $IMAGE_BASE_NAME:$VERSION-$TAG_x86 as $IMAGE_BASE_NAME:$TAG_x86"
docker tag "$IMAGE_BASE_NAME:$VERSION-$TAG_x86" "$IMAGE_BASE_NAME:$TAG_x86"
echo "===> Tagging $IMAGE_BASE_NAME:$VERSION-$TAG_arm32 as $IMAGE_BASE_NAME:$TAG_arm32"
docker tag "$IMAGE_BASE_NAME:$VERSION-$TAG_arm32" "$IMAGE_BASE_NAME:$TAG_arm32"
echo "===> Tagging $IMAGE_BASE_NAME:$VERSION-$TAG_arm64 as $IMAGE_BASE_NAME:$TAG_arm64"
docker tag "$IMAGE_BASE_NAME:$VERSION-$TAG_arm64" "$IMAGE_BASE_NAME:$TAG_arm64"
echo "===> Tagging $IMAGE_BASE_NAME:$VERSION-$TAG_uber as $IMAGE_BASE_NAME:$TAG_uber"
docker tag "$IMAGE_BASE_NAME:$VERSION-$TAG_uber" "$IMAGE_BASE_NAME:$TAG_uber"
echo "===> Tagging $IMAGE_BASE_NAME:$VERSION-$TAG_uber_nodeps as $IMAGE_BASE_NAME:$TAG_uber_nodeps & also latest"
docker tag "$IMAGE_BASE_NAME:$VERSION-$TAG_uber_nodeps" "$IMAGE_BASE_NAME:$TAG_uber_nodeps"
docker tag "$IMAGE_BASE_NAME:$VERSION-$TAG_uber_nodeps" "$IMAGE_BASE_NAME:latest"

# If we have a --push arg anywhere in cli, push everything
if [[ "$@" == *"--push"* ]]; then
	echo "===> Pushing images..."
	docker push "$IMAGE_SCALA_CLI_NAME" -a
	docker push "$IMAGE_BASE_NAME" -a
fi

