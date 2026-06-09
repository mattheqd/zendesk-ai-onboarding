# Zendesk Claude Code Workshop - Onboarding Scripts

Automated setup scripts to get Zendesk designers ready for the Claude Code workshop in ~10 minutes.

## 🚀 Quick Start (One-Line Setup)

**Copy and paste this into Terminal:**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mattheqd/zendesk-ai-onboarding/main/setup-wizard.sh)
```

Make sure **GlobalProtect VPN is connected** first!

---

## 🧙 Interactive Setup Wizard (Recommended)

**Or download and run locally:**

```bash
curl -O https://raw.githubusercontent.com/mattheqd/zendesk-ai-onboarding/main/setup-wizard.sh
bash setup-wizard.sh
```

The wizard will guide you through:
1. ✓ VPN connection check
2. ✓ GitHub access verification
3. ✓ AI Gateway token setup (opens browser for you!)
4. ✓ Tool installation (Homebrew, Node, VS Code, etc.)
5. ✓ SSH key setup for GitHub (for marketplace access)
6. ✓ Claude Code installation
7. ✓ Final verification

**Features:**
- 🎨 Clean, designer-friendly interface
- ↩️ Retry options if something fails
- 🌐 Opens browser to get your token
- 📋 Clear instructions for GitHub access
- ✅ Validates everything at the end

---

## 🔧 Advanced: Two-Phase Setup (Alternative)

If you prefer more control, use the two-phase approach:

```bash
bash preflight.sh && bash install.sh
```

### Phase 1: preflight.sh (Checks Only)
- ✓ GlobalProtect VPN connectivity
- ✓ GitHub CLI + zendesk org membership
- ✓ AI Gateway token validation

### Phase 2: install.sh (Installations)
- Homebrew (if missing)
- Node.js 20+
- GitHub CLI (gh) + authentication
- VS Code
- Claude Code (via AI Gateway)

---

## Requirements

- **Mac** (macOS 10.15+)
- **GlobalProtect VPN** connected
- **Zendesk email** for GitHub access
- **AI Gateway token** from https://ai-gateway.zende.sk

---

## Troubleshooting

### VPN Issues
- Open GlobalProtect and connect before running scripts
- The AI Gateway should be reachable at https://ai-gateway.zende.sk

### GitHub Access
**If you see warnings about GitHub access:**
1. Ping your manager or **#it-help** on Slack
2. Ask to be added to the **Zendesk GitHub organization**
3. This takes ~15 minutes if you ask today, 2 days if you wait

**You'll need this to push to internal repos during the workshop.**

### Token Issues
- Get a fresh token from https://ai-gateway.zende.sk
- Token should start with `zdai_`
- Make sure you're logged in with your Zendesk credentials

### SSH & Marketplace Issues

**Most common: SSH key needs SSO authorization**

If marketplace fails with "permission denied" or "authentication failed":

1. Go to https://github.com/settings/keys
2. Find your SSH key (named "Zendesk Workshop - [hostname]")
3. Click **Configure SSO** next to it
4. Click **Authorize** for the "zendesk" organization

**Why?** Zendesk GitHub uses Okta SSO. SSH keys need explicit org-level authorization to access private repos like the marketplace. The setup wizard prompts you to do this, but if you skipped it, use the steps above.

**If marketplace fails with "SSH host key not in known_hosts":**
```bash
ssh -T git@github.com
```
Type `yes` when asked about the fingerprint, then retry the marketplace command.

### Install Failures
- Check your internet connection
- Some tools may require admin approval on first launch
- Contact workshop organizers if problems persist

---

## Manual Testing

### Test with Dry Run (Safe - No Changes)
```bash
DRY_RUN=1 bash install.sh
```

### Test Preflight Only
```bash
bash preflight.sh
```

### Test Individual Components
```bash
# Test VPN
curl -I https://ai-gateway.zende.sk

# Test GitHub org
gh api /user/orgs | grep zendesk

# Test token validation
curl -I https://ai-gateway.zende.sk/bedrock/v1/messages \
  -H "Authorization: Bearer zdai_YOUR_TOKEN"
```

See [TESTING.md](TESTING.md) for comprehensive testing guide.

---

## Time Estimates

- **Interactive Wizard**: ~10 minutes (fully guided)
- **Two-Phase Setup**: ~10 minutes (more manual)
- **Manual Setup**: ~45 minutes (what we're replacing!)

---

## What Gets Installed

| Tool | Purpose | Size |
|------|---------|------|
| **Homebrew** | Package manager for Mac | ~100 MB |
| **Node.js 20+** | JavaScript runtime (required by Claude Code) | ~50 MB |
| **GitHub CLI** | Command-line tool for GitHub | ~15 MB |
| **jq** | JSON processor (for config updates) | ~1 MB |
| **VS Code** | Code editor for the workshop | ~150 MB |
| **Claude Code** | AI coding assistant | ~30 MB |

**Total:** ~350 MB (plus download time)

---

## After Installation

### Start Claude Code
```bash
# Open a new terminal first (to load updated PATH)
claude
```

### Verify Installation
```bash
# Check versions
claude --version
gh --version
node --version

# Check Claude Code config
cat ~/.claude/settings.json | jq .

# Test AI Gateway connectivity
curl -I https://ai-gateway.zende.sk
```

---

## Support

**During the workshop:**
- Ask the workshop organizers for help

**Before the workshop:**
- For GitHub access: Ping **#it-help** on Slack
- For VPN issues: Contact IT
- For script issues: Contact the workshop organizers

---

## Files in This Repo

- **`setup-wizard.sh`** - Interactive setup wizard (recommended)
- **`preflight.sh`** - Validation checks only
- **`install.sh`** - Installation phase
- **`README.md`** - This file
- **`TESTING.md`** - Testing guide for organizers

---

## Quick Links

- 🔑 Get AI Gateway token: https://ai-gateway.zende.sk
- 🐙 Zendesk GitHub org: https://github.com/zendesk
- 💬 IT support: #it-help on Slack
