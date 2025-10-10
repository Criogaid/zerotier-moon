# ZeroTier Moon Docker 镜像自动化构建

本文档说明如何设置和使用ZeroTier Moon Docker镜像的自动化构建流程。

## 概述

这个自动化流程会：

1. 每天自动检查ZeroTierOne的最新release
2. 与Docker Hub上的当前版本进行比较
3. 如果发现新版本，自动构建多架构（amd64和arm64）的Docker镜像
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
4. **构建决策**：仅当ZeroTierOne有新版本时才构建

### 构建流程

1. **多架构支持**：构建amd64和arm64架构的镜像
2. **标签策略**：
   - 使用ZeroTierOne版本号作为标签（如`1.14.0`）
   - 同时更新`latest`标签
3. **缓存优化**：使用GitHub Actions缓存加速构建

### 通知系统

如果配置了`WEBHOOK_URL`，工作流会在以下情况发送通知：

- 构建成功时
- 构建失败时

支持Slack、Discord等支持Webhook的平台。

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

在构建步骤中添加更多平台：

```yaml
platforms: linux/amd64,linux/arm64,linux/arm/v7
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