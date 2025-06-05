## Fix Using with Github Actions

When we switched to have no base image, we forgot that the standard way to use the changelog-tool image in Github Actions is as a service container. This means that all tools need to be included in the image. This includes tools needed to check out code etc. Given this, we have switched back to having a base image, but this time it is Alpine 3.21.
