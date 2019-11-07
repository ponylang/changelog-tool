#!/bin/bash

# x86-64-unknown-linux release:
#
# - Builds release package
# - Uploads to Cloudsmith
#
# Tools required in the environment that runs this:
#
# - bash
# - cloudsmith-cli
# - GNU gzip
# - GNU make
# - ponyc (musl based version)
# - GNU tar

set -o errexit
set -o nounset

# Verify ENV is set up correctly
# We validate all that need to be set in case, in an absolute emergency,
# we need to run this by hand. Otherwise the GitHub actions environment should
# provide all of these if properly configured
if [[ -z "${CLOUDSMITH_API_KEY}" ]]; then
  echo -e "\e[31mCloudsmith API key needs to be set in CLOUDSMITH_API_KEY. Exiting."
  exit 1
fi

TODAY=$(date +%Y%m%d)

# Compiler target parameters
ARCH=x86-64

# Triple construction
VENDOR=unknown
OS=linux
TRIPLE=${ARCH}-${VENDOR}-${OS}

# Build parameters
BUILD_PREFIX=$(mktemp -d)
APPLICATION_VERSION="nightly-${TODAY}"
BUILD_DIR=${BUILD_PREFIX}/${APPLICATION_VERSION}

# Asset information
PACKAGE_DIR=$(mktemp -d)
PACKAGE=changelog-tool-${TRIPLE}

# Cloudsmith configuration
CLOUDSMITH_VERSION=${TODAY}
ASSET_OWNER=ponylang
ASSET_REPO=nightlies
ASSET_PATH=${ASSET_OWNER}/${ASSET_REPO}
ASSET_FILE=${PACKAGE_DIR}/${PACKAGE}.tar.gz
ASSET_SUMMARY="Tool for modifying the 'standard pony' changelogs"
ASSET_DESCRIPTION="https://github.com/ponylang/changelog-tool"

# Build application installation
echo -e "\e[34mBuilding application..."
make install prefix="${BUILD_DIR}" arch=${ARCH} \
  version="${APPLICATION_VERSION}" static=true linker=bfd

# Package it all up
echo -e "\e[34mCreating .tar.gz of application..."
pushd "${BUILD_PREFIX}" || exit 1
tar -cvzf "${ASSET_FILE}" *
popd || exit 1

# Ship it off to cloudsmith
echo -e "\e[34mUploading package to cloudsmith..."
cloudsmith push raw --version "${CLOUDSMITH_VERSION}" \
  --api-key "${CLOUDSMITH_API_KEY}" --summary "${ASSET_SUMMARY}" \
  --description "${ASSET_DESCRIPTION}" ${ASSET_PATH} "${ASSET_FILE}"
