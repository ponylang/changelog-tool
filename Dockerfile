FROM ghcr.io/ponylang/ponyc:release-alpine AS build

WORKDIR /src/changelog-tool

COPY Makefile LICENSE VERSION corral.json /src/changelog-tool/

WORKDIR /src/changelog-tool/changelog-tool

COPY changelog-tool /src/changelog-tool/changelog-tool/

WORKDIR /src/changelog-tool

RUN make arch=x86-64 static=true linker=bfd \
 && make install

FROM scratch

COPY --from=build /usr/local/bin/changelog-tool /usr/local/bin/changelog-tool

CMD changelog-tool
