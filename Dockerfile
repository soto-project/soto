FROM ubuntu:14.04

RUN apt-get update -y
RUN apt-get install -y clang \
  libicu-dev \
  uuid-dev \
  git \
  libxml2-dev \
  libxslt1-dev \
  python-dev \
  libcurl4-openssl-dev \
  wget

ENV SWIFT_VERSION="4.1.2"
ENV SWIFTFILE="swift-$SWIFT_VERSION-RELEASE-ubuntu14.04"

RUN wget https://swift.org/builds/swift-$SWIFT_VERSION-release/ubuntu1404/swift-$SWIFT_VERSION-RELEASE/$SWIFTFILE.tar.gz
RUN tar -zxf $SWIFTFILE.tar.gz
ENV PATH $PWD/$SWIFTFILE/usr/bin:"${PATH}"

COPY . aws-sdk-swift

WORKDIR aws-sdk-swift

CMD swift test
