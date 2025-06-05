## Drop x86-64 Apple support

We no longer support Apple on Intel.

## Use Alpine 3.20 as our base image

Previously we were using Alpine 3.18 which has reached it's end-of-life. The change to 3.20 should have no impact on anyone unless they are using this image as the base image for another image.

## Stop having a base image

Previously we were using Alpine 3.20 as the base image for the changelog-tool container image. We've switched to using the `scratch` image instead. This means that the container image is now much smaller and only contains the `changelog-tool` binary.

## Add arm64 Linux builds

We've added nightly and release builds for arm64 Linux.

