FROM alpine:latest as builder

# Set timezone to Asia/Shanghai
ENV TZ=Asia/Shanghai

# Set TAG to the value of the TAG argument, or "main" if not provided
ARG TAG=main
ENV TAG=${TAG}

# Set MAKEFLAGS to use all available CPUs
ENV MAKEFLAGS=-j$(nproc)

# Set the working directory to /app
WORKDIR /app

# Update the package database and install necessary packages
RUN set -x \
    && apk update \
    && apk add --no-cache git make curl linux-headers openssl-dev cargo g++ gcc build-base

# Install Rust
RUN set -x \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && source "$HOME/.cargo/env"

# Clone the ZeroTierOne repository
RUN set -x \
    && git clone https://github.com/zerotier/ZeroTierOne.git \
    && cd ZeroTierOne \
    && git checkout ${TAG}

# Build and install ZeroTierOne
RUN set -x \
    && make CPPFLAGS+=-w \
    && make install

# Start ZeroTierOne in daemon mode
RUN zerotier-one -d

# Wait 5 seconds for ZeroTierOne to start
RUN sleep 5s

# Kill any remaining ZeroTierOne processes
RUN ps -ef |grep zerotier-one |grep -v grep |awk '{print $1}' |xargs kill -9

# Use Alpine Linux as the base image
FROM alpine:latest

# Copy the startup.sh script and healthcheck.sh script to the container
COPY ./startup.sh /usr/bin/
COPY ./healthcheck.sh /

# Make the scripts executable
RUN chmod +x /usr/bin/startup.sh
RUN chmod +x /healthcheck.sh

# Install dependencies during build
RUN apk add --no-cache openssl-dev libgcc libstdc++ curl

# Copy ZeroTierOne binary from builder image
COPY --from=builder /app/ZeroTierOne/zerotier-one /usr/sbin/zerotier-one

# Create symlinks for zerotier-cli and zerotier-idtool
RUN cd /usr/sbin && \
    ln -s zerotier-one zerotier-cli && \
    ln -s zerotier-one zerotier-idtool

# Remove any existing ZeroTierOne data
RUN rm -rf /var/lib/zerotier-one

# Expose port 9993/udp
EXPOSE 9993/udp

# Create a volume for ZeroTierOne data
VOLUME /var/lib/zerotier-one

# Set the health check command to /healthcheck.sh
HEALTHCHECK --interval=1s CMD sh /healthcheck.sh

# Set the entrypoint to the startup.sh script
ENTRYPOINT ["startup.sh"]
