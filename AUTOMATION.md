# ZeroTier Moon Docker Image Automated Build

[English](AUTOMATION.md) | [简体中文](AUTOMATION.zh-CN.md)

This document explains how to set up and use the automated build process for the ZeroTier Moon Docker image.

## Overview

This automated workflow will:

1. Automatically check for the latest ZeroTierOne release daily
2. Compare with the current version on Docker Hub
3. If a new version is found, automatically build multi-architecture (amd64 and arm64) Docker images
4. Push the built images to Docker Hub

## Setup Steps

### 1. Configure GitHub Secrets

Add the following secrets in your GitHub repository under Settings > Secrets and variables > Actions:

| Secret Name | Description | Required |
|------------|-------------|----------|
| `DOCKER_USERNAME` | Docker Hub username | Yes |
| `DOCKER_PASSWORD` | Docker Hub password or access token | Yes |
| `WEBHOOK_URL` | Notification webhook URL (optional) | No |

#### Docker Hub Access Token Setup

It's recommended to use a Docker Hub access token instead of a password:

1. Log in to Docker Hub
2. Go to Account Settings > Security
3. Click "New Access Token"
4. Enter a description and permissions (at least `Read, Write` permissions required)
5. Copy the generated token and add it to GitHub Secrets

### 2. Enable GitHub Actions

1. Go to the Actions page of your GitHub repository
2. If this is your first time, click "I understand my workflows, go ahead and enable them"

### 3. Test the Workflow

You can manually trigger the workflow to test your configuration:

1. Go to the Actions page
2. Select the "Update Docker Image" workflow
3. Click the "Run workflow" button
4. Select the branch (usually main or master)
5. Click "Run workflow"

## Workflow Details

### Scheduled Trigger

The workflow runs automatically daily at 08:00 UTC (16:00 Beijing time).

### Version Check Process

1. **Get Latest ZeroTierOne Version**: Fetch the latest release tag from GitHub API
2. **Get Current Docker Hub Version**: Fetch the current latest version tag from Docker Hub API
3. **Version Comparison**: Use semantic version comparison logic
4. **Build Decision**: Only build when a new ZeroTierOne version is available

### Build Process

1. **Multi-Architecture Support**: Build images for amd64 and arm64 architectures
2. **Tag Strategy**:
   - Use ZeroTierOne version number as tag (e.g., `1.14.0`)
   - Also update the `latest` tag
3. **Cache Optimization**: Use GitHub Actions cache to speed up builds

### Notification System

If `WEBHOOK_URL` is configured, the workflow will send notifications in the following cases:

- When build succeeds
- When build fails

Supports platforms that support webhooks, such as Slack and Discord.

## Troubleshooting

### Common Issues

1. **Workflow Failure**
   - Check if GitHub Secrets are configured correctly
   - Verify Docker Hub permissions are sufficient
   - Review Actions logs for detailed error information

2. **Version Comparison Error**
   - Ensure ZeroTierOne and Docker Hub version formats are consistent
   - Check if version comparison script executes correctly

3. **Build Timeout**
   - GitHub Actions has timeout limits (default 6 hours)
   - Large projects may need Dockerfile optimization to reduce build time

### Debugging Tips

1. **View Detailed Logs**: Click on a specific workflow run in the Actions page to view detailed logs for each step
2. **Local Testing**: You can run build commands locally to test the Dockerfile
3. **Step-by-Step Debugging**: Temporarily disable certain steps to isolate issues

## Advanced Configuration

### Customize Build Time

Modify the cron expression in `.github/workflows/update-docker-image.yml`:

```yaml
schedule:
  - cron: '0 8 * * *'  # Daily at 08:00 UTC
```

### Add More Architectures

Add more platforms in the build step:

```yaml
platforms: linux/amd64,linux/arm64,linux/arm/v7
```

### Customize Notification Format

Modify the notification template in `scripts/notify.sh` to customize notification content.

## Security Considerations

1. **Confidentiality**: Ensure all sensitive information is stored in GitHub Secrets
2. **Least Privilege**: Only grant necessary permissions to Docker Hub access tokens
3. **Auditing**: Regularly review GitHub Actions run logs

## Maintenance Recommendations

1. **Regular Checks**: Even with automation, it's recommended to regularly check build status
2. **Update Dependencies**: Keep GitHub Actions versions up to date
3. **Monitor Storage**: Pay attention to GitHub Actions storage usage

## License

This automated workflow follows the same license as the main project.
