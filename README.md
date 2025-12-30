# ZeroTier Moon Docker Image

[English](README.md) | [简体中文](README.zh-CN.md)

🐳 A Docker image for creating a ZeroTier moon in a single step.

## Table of Contents
- [ZeroTier Moon Docker Image](#zerotier-moon-docker-image)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Building the Image](#building-the-image)
    - [Prerequisites](#prerequisites)
    - [Steps](#steps)
  - [Usage](#usage)
    - [Parameters](#parameters)
  - [Docker Compose Configuration](#docker-compose-configuration)
  - [Log Output](#log-output)
  - [Example](#example)
  - [Automated Build](#automated-build)
    - [Features](#features)
    - [Build Status](#build-status)
    - [More Information](#more-information)
  - [Conclusion](#conclusion)

## Overview
This repository provides a Docker image to easily set up a ZeroTier moon, which acts as a control plane for your ZeroTier network. With this image, you can quickly deploy a ZeroTier moon with minimal configuration.

## Building the Image

### Prerequisites
Ensure you have Docker installed on your machine.

### Steps
1. Open the `Dockerfile` and locate the line `ARG TAG=main`.
2. Replace `main` with the desired ZeroTier release tag, such as `1.14.1` or `1.14.0`.
3. Build the Docker image using the following command:
   ```bash
   docker build -t your-image-name .
   ```

## Usage
To run the ZeroTier moon, execute the following command:

```bash
docker run --rm \
  --name zerotier-moon \
  -p 9993:9993/udp \
  -v ./zerotier-one:/var/lib/zerotier-one \
  --device /dev/net/tun \
  --cap-add NET_ADMIN \
  --cap-add SYS_ADMIN \
  criogaid/zerotier-moon \
  -4 YourIPv4Address \
  -6 YourIPv6AddressIfYouHaveOne \
  -p 9993
```

### Parameters
- `YourIPv4Address`: Replace with your actual IPv4 address. If you do not have one, you can omit this parameter.
- `YourIPv6AddressIfYouHaveOne`: Replace with your actual IPv6 address if available. If not, you can omit this parameter.

## Docker Compose Configuration
For a more streamlined setup, you can use Docker Compose. Below is a sample configuration:

```yaml
services:
  zerotier-moon:
    image: criogaid/zerotier-moon
    restart: unless-stopped
    container_name: zerotier-moon
    ports:
      - "9993:9993/udp"
    volumes:
      - ./zerotier-one:/var/lib/zerotier-one
    environment:
      - ZEROTIER_JOIN_NETWORKS= # Optional, specify the network ID(s) to join
      - ZEROTIER_API_SECRET= # Optional, for ZeroTier Central API access
      - ZEROTIER_IDENTITY_PUBLIC= # Optional, for custom identity
      - ZEROTIER_IDENTITY_SECRET= # Optional, for custom identity
    devices:
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
      - SYS_ADMIN
    command:
      - "-4"
      - "YourIPv4Address" # Optional, if you don't have an IPv4 address, remove this line
      - "-6"
      - "YourIPv6AddressIfYouHaveOne" # Optional, if you don't have an IPv6 address, remove this line
      - "-p"
      - "9993" # Optional, specify the port to use
```

## Log Output
Upon successful startup, you should see logs similar to the following:

```bash
IPv4 address: xxx.xxx.xxx.xxx
IPv6 address is unset, automatically catching the IPv6 address
Failed to catch the IPv6 address.
=> Configuring networks to join
Your ZeroTier moon ID is xxxxxxxxxx. You can orbit the moon using "zerotier-cli orbit xxxxxxxxx xxxxxxxxx"
Starting Control Plane...
Starting V6 Control Plane...
```

## Example
To join specific ZeroTier networks, you can set the `ZEROTIER_JOIN_NETWORKS` environment variable in your Docker Compose configuration. For example:

```yaml
environment:
  - ZEROTIER_JOIN_NETWORKS=888888888888888 666666666666666 999999999999999
```

In this example, the ZeroTier moon will join the networks with IDs `888888888888888`, `666666666666666`, and `999999999999999`. You can specify multiple network IDs separated by spaces.

## Automated Build

This project uses GitHub Actions to automate the build process, checking for the latest ZeroTierOne release daily and building Docker images automatically.

### Features

- **Automatic Update Checks**: Daily checks for the latest ZeroTierOne releases
- **Multi-Architecture Support**: Builds images for both amd64 and arm64 architectures
- **Version Comparison**: Intelligently compares version numbers, building only when new versions are available
- **Automatic Push**: Automatically pushes built images to Docker Hub

### Build Status

[![GitHub Actions](https://github.com/criogaid/zerotier-moon/workflows/Update%20Docker%20Image/badge.svg)](https://github.com/criogaid/zerotier-moon/actions)

### More Information

For detailed setup and usage instructions regarding automated builds, please refer to [AUTOMATION.md](AUTOMATION.md).

## Conclusion
This Docker image simplifies the process of setting up a ZeroTier moon, allowing you to focus on building your network. For any issues or contributions, feel free to open an issue or pull request in this repository. Happy networking!