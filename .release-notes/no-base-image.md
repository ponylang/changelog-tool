## Stop having a base image

Previously we were using Alpine 3.20 as the base image for the changelog-tool container image. We've switched to using the `scratch` image instead. This means that the container image is now much smaller and only contains the `changelog-tool` binary.
