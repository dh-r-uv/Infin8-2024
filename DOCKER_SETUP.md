# Docker Username Param configuration Setup

## Quick Start

```bash
# 1. Set environment variable
export DOCKER_REGISTRY_USER=dhruvk321  # or your username

# 2. Run any script - it will use your username
./build_canary_image.sh v1.2
./auto_canary.sh
```

## Jenkins Setup

Set environment variable in Jenkins:
1. **Manage Jenkins** → **System** → **Global properties**
2. Check "Environment variables"
3. Add: `DOCKER_REGISTRY_USER` = `dhruvk321`

Or set in pipeline:
```groovy
environment {
    DOCKER_REGISTRY_USER = 'your-username'
}
```

## Files Updated
- ✅ `.env` - Contains DOCKER_REGISTRY_USER=dhruvk321
- ✅ `.env.template` - Template for others to copy
- ✅ `Jenkinsfile` - Uses ${env.DOCKER_REGISTRY_USER}
- ✅ `build_canary_image.sh` - Reads from environment
- ✅ `auto_canary.sh` - Reads from environment
- ✅ `ansible/playbook.yaml` - Uses Ansible lookup

All files have backwards-compatible defaults to `dhruvk321`.
