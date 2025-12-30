# ZeroTier Moon Docker 镜像

[English](README.md) | [简体中文](README.zh-CN.md)

🐳 一键创建 ZeroTier Moon 节点的 Docker 镜像。

## 目录
- [ZeroTier Moon Docker 镜像](#zerotier-moon-docker-镜像)
  - [目录](#目录)
  - [概述](#概述)
  - [构建镜像](#构建镜像)
    - [前置要求](#前置要求)
    - [构建步骤](#构建步骤)
  - [使用方法](#使用方法)
    - [参数说明](#参数说明)
  - [Docker Compose 配置](#docker-compose-配置)
  - [日志输出](#日志输出)
  - [示例](#示例)
  - [自动化构建](#自动化构建)
    - [特性](#特性)
    - [构建状态](#构建状态)
    - [详细信息](#详细信息)
  - [结语](#结语)

## 概述
本仓库提供了一个 Docker 镜像，用于轻松搭建 ZeroTier Moon 节点，它充当 ZeroTier 网络的控制平面。通过此镜像，您可以以最少的配置快速部署 ZeroTier Moon。

## 构建镜像

### 前置要求
请确保您的机器上已安装 Docker。

### 构建步骤
1. 打开 `Dockerfile` 并找到 `ARG TAG=main` 这一行。
2. 将 `main` 替换为所需的 ZeroTier 发布标签，例如 `1.14.1` 或 `1.14.0`。
3. 使用以下命令构建 Docker 镜像：
   ```bash
   docker build -t your-image-name .
   ```

## 使用方法
要运行 ZeroTier Moon，请执行以下命令：

```bash
docker run --rm \
  --name zerotier-moon \
  -p 9993:9993/udp \
  -v ./zerotier-one:/var/lib/zerotier-one \
  --device /dev/net/tun \
  --cap-add NET_ADMIN \
  --cap-add SYS_ADMIN \
  criogaid/zerotier-moon \
  -4 你的IPv4地址 \
  -6 你的IPv6地址如果有的话 \
  -p 9993
```

### 参数说明
- `你的IPv4地址`：替换为您的实际 IPv4 地址。如果您没有 IPv4 地址，可以省略此参数。
- `你的IPv6地址如果有的话`：如果有 IPv6 地址，请替换为您的实际 IPv6 地址。如果没有，可以省略此参数。

## Docker Compose 配置
为了简化部署流程，您可以使用 Docker Compose。以下是示例配置：

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
      - ZEROTIER_JOIN_NETWORKS= # 可选，指定要加入的网络 ID
      - ZEROTIER_API_SECRET= # 可选，用于 ZeroTier Central API 访问
      - ZEROTIER_IDENTITY_PUBLIC= # 可选，自定义 identity
      - ZEROTIER_IDENTITY_SECRET= # 可选，自定义 identity
    devices:
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
      - SYS_ADMIN
    command:
      - "-4"
      - "你的IPv4地址" # 可选，如果没有 IPv4 地址，删除此行
      - "-6"
      - "你的IPv6地址如果有的话" # 可选，如果没有 IPv6 地址，删除此行
      - "-p"
      - "9993" # 可选，指定要使用的端口
```

## 日志输出
成功启动后，您应该会看到类似以下的日志：

```bash
IPv4 address: xxx.xxx.xxx.xxx
IPv6 address is unset, automatically catching the IPv6 address
Failed to catch the IPv6 address.
=> Configuring networks to join
Your ZeroTier moon ID is xxxxxxxxxx. You can orbit the moon using "zerotier-cli orbit xxxxxxxxx xxxxxxxxx"
Starting Control Plane...
Starting V6 Control Plane...
```

## 示例
要加入特定的 ZeroTier 网络，您可以在 Docker Compose 配置中设置 `ZEROTIER_JOIN_NETWORKS` 环境变量。例如：

```yaml
environment:
  - ZEROTIER_JOIN_NETWORKS=888888888888888 666666666666666 999999999999999
```

在此示例中，ZeroTier Moon 将加入网络 ID 为 `888888888888888`、`666666666666666` 和 `999999999999999` 的网络。您可以指定多个网络 ID，用空格分隔。

## 自动化构建

本项目使用 GitHub Actions 实现自动化构建流程，每天会自动检查 ZeroTierOne 的最新 release 并构建 Docker 镜像。

### 特性

- **自动检查更新**：每天自动检查 ZeroTierOne 的最新 release
- **多架构支持**：构建 amd64 和 arm64 架构的镜像
- **版本比较**：智能比较版本号，仅在有新版本时构建
- **自动推送**：构建完成后自动推送到 Docker Hub

### 构建状态

[![GitHub Actions](https://github.com/criogaid/zerotier-moon/workflows/Update%20Docker%20Image/badge.svg)](https://github.com/criogaid/zerotier-moon/actions)

### 详细信息

关于自动化构建的详细设置和使用说明，请参阅 [AUTOMATION.zh-CN.md](AUTOMATION.zh-CN.md)。

## 结语
此 Docker 镜像简化了 ZeroTier Moon 的搭建过程，让您可以专注于构建您的网络。如有任何问题或贡献，欢迎在本仓库中提交 issue 或 pull request。祝您网络搭建愉快！
