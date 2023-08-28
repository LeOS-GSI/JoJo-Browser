FROM debian:bookworm
ARG TARGET=linux

ENV DOCKER=1

ADD . /bsys6
WORKDIR /bsys6

RUN ./bsys6 prepare clean

RUN rm -rf /bsys6
