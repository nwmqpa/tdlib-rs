FROM debian:stable-slim AS builder

ARG COMMIT_SHA=master

RUN apt-get update && apt-get upgrade
RUN apt-get install -y make git zlib1g-dev libssl-dev gperf php-cli cmake clang libc++-dev libc++abi-dev

WORKDIR /tdlib

RUN git clone https://github.com/tdlib/td.git --branch $COMMIT_SHA --single-branch
RUN mkdir -p /tdlib/td/build

WORKDIR /tdlib/td/build

RUN CXXFLAGS="-stdlib=libc++" CC=/usr/bin/clang CXX=/usr/bin/clang++ cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr/local ..
RUN cmake --build . --target install

FROM debian:stable-slim AS runtime

RUN apt-get update && apt-get upgrade
RUN apt-get install -y libssl3 libc++abi1 libc++1

COPY --from=builder /usr/local/include/td /usr/local/include/td
COPY --from=builder /usr/local/lib/libtd* /usr/local/lib
COPY --from=builder /usr/local/lib/cmake/Td /usr/local/lib/cmake/Td
COPY --from=builder /usr/local/lib/pkgconfig /usr/local/lib/pkgconfig
