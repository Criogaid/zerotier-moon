# ZeroTier Moon Docker Image

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
  - [自动化构建](#自动化构建)
    - [特性](#特性)
    - [构建状态](#构建状态)
    - [详细信息](#详细信息)
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
version: '3'

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
      - -4 YourIPv4Address # Optional, if you don't have an IPv4 address, remove this line
      - -6 YourIPv6AddressIfYouHaveOne # Optional, if you don't have an IPv6 address, remove this line
      - -p 9993 # Optional, specify the port to use
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

## 自动化构建

本项目使用GitHub Actions实现自动化构建流程，每天会自动检查ZeroTierOne的最新release并构建Docker镜像。

### 特性

- **自动检查更新**：每天自动检查ZeroTierOne的最新release
- **多架构支持**：构建amd64和arm64架构的镜像
- **版本比较**：智能比较版本号，仅在有新版本时构建
- **自动推送**：构建完成后自动推送到Docker Hub

### 构建状态

[![GitHub Actions](https://github.com/criogaid/zerotier-moon/workflows/Update%20Docker%20Image/badge.svg)](https://github.com/criogaid/zerotier-moon/actions)

### 详细信息

关于自动化构建的详细设置和使用说明，请参阅[AUTOMATION.md](AUTOMATION.md)。

## Conclusion
This Docker image simplifies the process of setting up a ZeroTier moon, allowing you to focus on building your network. For any issues or contributions, feel free to open an issue or pull request in this repository. Happy networking!