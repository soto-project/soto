FROM swift:5.2 as builder

RUN apt-get -qq update && apt-get install -y \
  libssl-dev zlib1g-dev \
  && rm -r /var/lib/apt/lists/*
