# ZeroTier Moon Docker 镜像自动化构建

[English](AUTOMATION.md) | [简体中文](AUTOMATION.zh-CN.md)

本文档说明如何设置和使用ZeroTier Moon Docker镜像的自动化构建流程。

## 概述

这个自动化流程会：

1. 每天自动检查ZeroTierOne的最新release
2. 与Docker Hub上的当前版本进行比较
3. 如果发现新版本，构建 amd64、arm64 和 arm/v7 镜像
4. 将构建好的镜像推送到Docker Hub

## 设置步骤

### 1. 配置GitHub Secrets

在GitHub仓库的Settings > Secrets and variables > Actions中添加以下secrets：

| Secret名称 | 描述 | 必需 |
|-----------|------|------|
| `DOCKER_USERNAME` | Docker Hub用户名 | 是 |
| `DOCKER_PASSWORD` | Docker Hub密码或访问令牌 | 是 |
| `WEBHOOK_URL` | 通知Webhook URL（可选） | 否 |

#### Docker Hub访问令牌设置

建议使用Docker Hub访问令牌而不是密码：

1. 登录Docker Hub
2. 进入Account Settings > Security
3. 点击"New Access Token"
4. 输入描述和权限（至少需要`Read, Write`权限）
5. 复制生成的令牌并添加到GitHub Secrets

### 2. 启用GitHub Actions

1. 进入GitHub仓库的Actions页面
2. 如果是第一次使用，点击"I understand my workflows, go ahead and enable them"

### 3. 测试工作流

你可以手动触发工作流来测试配置：

1. 进入Actions页面
2. 选择"Update Docker Image"工作流
3. 点击"Run workflow"按钮
4. 选择分支（通常是main或master）
5. 点击"Run workflow"

## 工作流详解

### 定时触发

工作流每天UTC时间08:00（北京时间16:00）自动运行。

### 版本检查流程

1. **获取ZeroTierOne最新版本**：从GitHub API获取最新release tag
2. **获取Docker Hub当前版本**：从Docker Hub API获取当前最新版本tag
3. **版本比较**：使用语义化版本比较逻辑
4. **构建决策**：ZeroTierOne 有新版本，或版本标签与 `latest` 的 manifest digest 不一致时构建

### 构建流程

1. **多架构支持**：构建 `linux/amd64`、`linux/arm64` 和 `linux/arm/v7` 镜像
2. **原生构建优先**：amd64 和 arm64 原生构建；ARMv7 在 ARM64 runner 上通过 QEMU 模拟
3. **可恢复发布**：先推送各平台的不可变 digest，所有平台成功后才发布标签；版本标签与 `latest` 不一致时自动重试
4. **标签策略**：
   - 使用 ZeroTierOne 版本号作为版本标签（例如 `1.16.2`）
   - 将 `latest` 更新为同一个已验证的多平台 manifest
5. **缓存优化**：使用 BuildKit `mode=max` 将全部中间层导出到按架构隔离的 GitHub Actions 缓存，并保留已有 `latest` 的 inline 缓存作为回退

### 通知系统

如果配置了`WEBHOOK_URL`，工作流会在以下情况发送通知：

- 构建成功时
- 构建失败时

支持Slack、Discord等支持Webhook的平台。
Webhook payload 会进行 JSON 转义；HTTP 投递失败会记录为 workflow warning，但不会回滚或阻断已经发布的镜像。

## 故障排除

### 常见问题

1. **工作流失败**
   - 检查GitHub Secrets是否正确配置
   - 确认Docker Hub权限是否足够
   - 查看Actions日志获取详细错误信息

2. **版本比较错误**
   - 确认ZeroTierOne和Docker Hub的版本格式一致
   - 检查版本比较脚本是否正确执行

3. **构建超时**
   - GitHub Actions有超时限制（默认6小时）
   - 大型项目可能需要优化Dockerfile以减少构建时间

### 调试技巧

1. **查看详细日志**：在Actions页面点击具体的工作流运行，查看每个步骤的详细日志
2. **本地测试**：可以在本地运行构建命令测试Dockerfile
3. **分步调试**：可以临时禁用某些步骤来定位问题

## 高级配置

### 自定义构建时间

修改`.github/workflows/update-docker-image.yml`中的cron表达式：

```yaml
schedule:
  - cron: '0 8 * * *'  # 每天08:00 UTC
```

### 添加更多架构

仅在 Alpine 和 ZeroTierOne 支持目标平台时添加 matrix 项。有原生 runner 时优先使用；非原生目标还需添加对应的 QEMU setup 条件。每个平台必须使用唯一的 `arch` 值，因为它同时作为 digest 输出键：

```yaml
- arch: example
  platform: linux/example
  runner: host-runner-label
```

### 自定义通知格式

修改`scripts/notify.sh`中的通知模板来自定义通知内容。

## 安全考虑

1. **保密性**：确保所有敏感信息都存储在GitHub Secrets中
2. **最小权限**：Docker Hub访问令牌只授予必要的权限
3. **审计**：定期审查GitHub Actions的运行日志

## 维护建议

1. **定期检查**：即使有自动化，也建议定期检查构建状态
2. **更新依赖**：保持GitHub Actions版本最新
3. **监控存储**：注意GitHub Actions的存储使用情况

## 许可证

此自动化流程遵循与主项目相同的许可证。
