# Release Automation

This project automatically builds and releases new images when upstream CRI-O or Kubernetes versions are released, similar to how the official KIND project works.

## How It Works

### 1. Automatic Release Pipeline (`auto-release.yml`)

**Triggers:**
- **Weekly checks** every Monday at 6 AM UTC for new upstream versions
- **Manual dispatch** for forced releases
- **Repository dispatch** events from upstream webhooks

**Rationale:** 
- CRI-O releases roughly monthly
- Kubernetes releases every ~3-4 months
- Weekly checks ensure we catch releases within 7 days maximum
- Webhooks provide immediate response when configured

**Process:**
1. **Check upstream versions** from GitHub APIs (CRI-O and Kubernetes)
2. **Compare with current versions** in Dockerfile
3. **🛑 STOP if no changes** - pipeline ends here, no resources wasted
4. **🚀 CONTINUE if changes found** - proceed with build and release:
   - Build multi-arch images (linux/amd64, linux/arm64)
   - Push to GitHub Container Registry with multiple tags
   - Create GitHub release with detailed changelog
   - Commit version updates back to repository

**Smart Stopping Logic:**
- ✅ **Releases found**: Full pipeline runs
- ⏭️ **No releases**: Pipeline stops after version check (saves time/resources)
- 🔄 **Duplicate release**: Skips if release tag already exists

**Image Tags Created:**
- `ghcr.io/[username]/crio-in-kind:v1.34.0` (CRI-O version)
- `ghcr.io/[username]/crio-in-kind:v1.34.0-k8s-v1.32.0` (Full version)
- `ghcr.io/[username]/crio-in-kind:latest` (Latest release)

### 2. Upstream Release Triggers (`upstream-release-trigger.yml`)

**Purpose:** React immediately to upstream releases instead of waiting for daily checks

**Setup Options:**

#### Option A: Repository Webhooks (Recommended)
Set up webhooks in your repository settings to trigger on:
- CRI-O releases: `https://api.github.com/repos/[username]/crio-in-kind/dispatches`
- Kubernetes releases: `https://api.github.com/repos/[username]/crio-in-kind/dispatches`

#### Option B: External Monitoring
Use services like GitHub Actions marketplace actions or external tools to monitor upstream releases.

#### Option C: Manual Triggers
Manually trigger when you notice new releases:
```bash
# Via GitHub CLI
gh workflow run upstream-release-trigger.yml -f upstream_repo=cri-o -f version=v1.34.0

# Via API
curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/[username]/crio-in-kind/dispatches \
  -d '{"event_type":"crio-release","client_payload":{"version":"v1.34.0"}}'
```

### 3. Backup PR-based Updates (`version-update.yml`)

**Purpose:** Weekly backup system that creates PRs for manual review

**When to use:**
- Auto-release system fails
- Want manual review before release
- Testing version compatibility

## Release Frequency

### Automatic Releases
- **CRI-O releases**: Within 1 week of upstream release (or immediately via webhook)
- **Kubernetes releases**: Within 1 week of upstream release (or immediately via webhook)
- **Combined updates**: When both have new versions
- **Scheduled checks**: Weekly on Mondays as backup

### Release Lifecycle Context
- **CRI-O**: Releases approximately monthly
- **Kubernetes**: Major releases every ~3-4 months, patch releases more frequently
- **KIND**: Releases follow Kubernetes releases
- **This project**: Follows both CRI-O and Kubernetes releases

### Manual Releases
- **Security patches**: As needed
- **Bug fixes**: As needed
- **Feature updates**: As needed

## Version Strategy

### Primary Versioning
Images are primarily versioned by **CRI-O version** since that's the main differentiator from standard KIND images.

### Tag Examples
```bash
# Latest CRI-O with latest compatible Kubernetes
ghcr.io/[username]/crio-in-kind:v1.34.0

# Specific CRI-O + Kubernetes combination
ghcr.io/[username]/crio-in-kind:v1.34.0-k8s-v1.32.0

# Always latest
ghcr.io/[username]/crio-in-kind:latest
```

### Compatibility Matrix
| CRI-O Version | Kubernetes Versions | Image Tags |
|---------------|-------------------|------------|
| v1.34.x | v1.32.x, v1.31.x | `v1.34.0`, `v1.34.0-k8s-v1.32.0` |
| v1.33.x | v1.31.x, v1.30.x | `v1.33.0`, `v1.33.0-k8s-v1.31.0` |

## Monitoring and Notifications

### Success Indicators
- ✅ GitHub release created
- ✅ Docker images pushed to registry
- ✅ Multi-arch builds successful
- ✅ Basic smoke tests pass

### Failure Handling
- 🚨 Automatic issue creation on failures
- 📧 GitHub notifications to repository watchers
- 🔄 Retry logic for transient failures

### Manual Verification
```bash
# Check latest release
gh release list --limit 5

# Verify image exists
docker pull ghcr.io/[username]/crio-in-kind:latest
docker run --rm ghcr.io/[username]/crio-in-kind:latest crio version

# Test with KIND
kind create cluster --image ghcr.io/[username]/crio-in-kind:latest
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}'
```

## Configuration

### Environment Variables
```yaml
# In workflow files
REGISTRY: ghcr.io
IMAGE_NAME: ${{ github.repository }}
```

### Secrets Required
- `GITHUB_TOKEN`: Automatically provided (packages:write, contents:write)

### Permissions Needed
```yaml
permissions:
  contents: write    # Create releases and commit updates
  packages: write    # Push to GitHub Container Registry
```

## Comparison with KIND

| Feature | KIND Official | CRI-O KIND (This Project) |
|---------|---------------|---------------------------|
| **Release Trigger** | Manual + Scheduled | Auto + Manual + Webhook |
| **Frequency** | Per K8s release | Per CRI-O + K8s release |
| **Multi-arch** | ✅ Yes | ✅ Yes |
| **Container Registry** | Docker Hub + GCR | GitHub Container Registry |
| **Version Tags** | K8s version | CRI-O version (primary) |
| **Automation Level** | Semi-automatic | Fully automatic |

## Troubleshooting

### Common Issues

1. **Build Failures**
   - Check CRI-O package availability
   - Verify Kubernetes base image exists
   - Review build logs for dependency issues

2. **Registry Push Failures**
   - Verify GITHUB_TOKEN permissions
   - Check registry authentication
   - Ensure repository packages are enabled

3. **Version Detection Issues**
   - GitHub API rate limiting
   - Upstream release format changes
   - Network connectivity problems

### Debug Commands
```bash
# Check current versions
grep "ARG.*VERSION" Dockerfile

# Test version detection
curl -s https://api.github.com/repos/cri-o/cri-o/releases/latest | jq -r '.tag_name'
curl -s https://api.github.com/repos/kubernetes/kubernetes/releases | jq -r '.[0].tag_name'

# Manual workflow trigger
gh workflow run auto-release.yml -f force_release=true
```

## Future Enhancements

### Planned Features
- [ ] **Slack/Discord notifications** for releases
- [ ] **Security scanning** integration
- [ ] **Performance benchmarks** in releases
- [ ] **Compatibility testing** matrix
- [ ] **Rollback mechanisms** for failed releases

### Integration Opportunities
- [ ] **Dependabot** for base image updates
- [ ] **Renovate** for dependency management
- [ ] **SBOM generation** for security compliance
- [ ] **Cosign signing** for image verification

---

This automation ensures that CRI-O KIND images are always up-to-date with the latest upstream releases, providing developers with the most current testing environment for Kubernetes features that behave differently between container runtimes.