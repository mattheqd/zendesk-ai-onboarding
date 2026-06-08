# Testing the Onboarding Scripts

Since you don't have a fresh Mac, here are several ways to test the scripts safely:

## 1. Dry Run Mode (Safest)

Test the install script without actually installing anything:

```bash
DRY_RUN=1 bash install.sh
```

This will show you what would happen without making any changes.

## 2. Docker Container Testing

Create a clean Mac-like environment using Docker:

```bash
# Use an Ubuntu container (closest to Mac environment)
docker run -it --rm ubuntu:22.04 bash

# Inside the container, install basic tools and run your scripts
apt-get update && apt-get install -y curl
curl -O <your-script-url>/preflight.sh
bash preflight.sh
```

## 3. Virtual Machine

Use UTM (free) or Parallels to create a macOS VM:
- Download macOS from App Store
- Create a fresh VM
- Snapshot before testing
- Test scripts
- Restore snapshot to test again

## 4. Partial Testing on Your Mac

Test individual components without full installation:

### Test Preflight Script
```bash
# This only checks, doesn't install
bash preflight.sh
```

### Test VPN Check
```bash
ping -c 1 ai-gateway.zende.sk
```

### Test GitHub Auth
```bash
gh auth status
gh api /user/orgs | grep zendesk
```

### Test Token Format
```bash
# Manually validate token format
echo "zdai_test123" | grep -q "^zdai_" && echo "Valid format" || echo "Invalid"
```

### Test AI Gateway Connection
```bash
curl -I https://ai-gateway.zende.sk/v1/messages \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 5. Mock Environment Testing

Create aliases to simulate missing tools:

```bash
# Test "missing GitHub CLI" scenario
alias gh='command_not_found' bash preflight.sh

# Test "missing Node" scenario  
alias node='command_not_found' DRY_RUN=1 bash install.sh
```

## 6. Test with a Colleague

Ask a colleague who is willing to test on their Mac:
- Give them the scripts
- Have them run with `set -x` for debug output:
  ```bash
  bash -x preflight.sh
  ```
- Watch the output together over screen share

## 7. Isolated PATH Testing

Run scripts with limited PATH to simulate missing tools:

```bash
# Only use system binaries
PATH=/usr/bin:/bin bash preflight.sh

# This will show how the script handles missing brew, gh, etc.
```

## 8. Create a Test User Account

On your Mac, create a fresh user account:
1. System Preferences → Users & Groups → Add User
2. Log in as that user
3. Run the scripts
4. Delete the user when done

This gives you a clean environment without affecting your main account.

## 9. Test Configuration Files Only

Test the Claude Code config generation without running the installer:

```bash
# Just test the config file creation
mkdir -p /tmp/test-claude
cat > /tmp/test-claude/settings.json << EOF
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "true",
    "ANTHROPIC_BEDROCK_BASE_URL": "https://ai-gateway.zende.sk/bedrock",
    "CLAUDE_CODE_SKIP_BEDROCK_AUTH": "true",
    "ANTHROPIC_AUTH_TOKEN": "zdai_test123",
    "DISABLE_PROMPT_CACHING": "false"
  }
}
EOF

cat /tmp/test-claude/settings.json | jq .
```

## 10. Unit Test Individual Functions

Extract and test individual checks:

```bash
# Test VPN check
check_vpn() {
    if ping -c 1 -W 2 ai-gateway.zende.sk > /dev/null 2>&1; then
        echo "✓ VPN connected"
    else
        echo "✗ VPN not connected"
    fi
}
check_vpn

# Test token format
check_token() {
    local token="$1"
    if [[ "$token" =~ ^zdai_ ]]; then
        echo "✓ Token format valid"
    else
        echo "✗ Invalid token format"
    fi
}
check_token "zdai_test123"
```

## Recommended Testing Order

1. **Start with dry run** on your Mac: `DRY_RUN=1 bash install.sh`
2. **Test preflight** (safe, only checks): `bash preflight.sh`
3. **Create test user** on your Mac for full flow
4. **Test with colleague** for real-world validation
5. **Deploy** and have one designer test before the workshop

## What to Watch For

- ✓ Clear error messages when tools are missing
- ✓ Graceful handling of existing installations
- ✓ Token validation catches bad formats
- ✓ PATH updates work correctly
- ✓ Shell profile updates don't break existing configs
- ✓ Progress indicators show up correctly
- ✓ Final summary is accurate

## Quick Validation Commands

After running the scripts, validate everything works:

```bash
# Check all tools are installed and in PATH
command -v brew && echo "✓ brew"
command -v node && echo "✓ node"
command -v gh && echo "✓ gh"
command -v claude && echo "✓ claude"
command -v jq && echo "✓ jq"

# Check Claude Code config
cat ~/.claude/settings.json | jq .

# Check shell profiles were updated
grep NODE_USE_SYSTEM_CA ~/.zprofile
grep PATH ~/.zshrc

# Test Claude Code works
claude --version

# Test AI Gateway connectivity
ping -c 1 ai-gateway.zende.sk
```
