FROM ponylang/ponyc:latest

WORKDIR /src/changelog-tool

COPY Makefile LICENSE bundle.json /src/changelog-tool/
COPY *.pony /src/changelog-tool/

RUN make \
  && make install \
  && make clean

WORKDIR /src/main

CMD changelog-tool
