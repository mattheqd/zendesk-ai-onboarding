# Distribution Guide for Workshop Organizers

## 📦 What You Have

Your onboarding system is now live at:
**https://github.com/mattheqd/zendesk-ai-onboarding**

## 🎯 The One-Liner (Main Command)

Give designers this single command:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mattheqd/zendesk-ai-onboarding/main/setup-wizard.sh)
```

---

## 📧 Communication Templates

### 1. **Email to Designers** (1 week before)
Use: [`WORKSHOP-EMAIL.md`](WORKSHOP-EMAIL.md)

Key points:
- VPN requirement
- One-line setup command
- GitHub access (must do early!)
- AI Gateway token info

### 2. **Slack Announcement** (3 days before)
Use: [`SLACK-MESSAGE.md`](SLACK-MESSAGE.md)

Post in team channel with:
- Quick copy-paste command
- GitHub access reminder
- Link to docs

### 3. **Quick Reference** (day of workshop)
Use: [`ONE-PAGER.md`](ONE-PAGER.md)

Print or share as PDF for quick reference

---

## 🖼️ QR Code for Slides

**Create a QR code** pointing to the setup wizard:

### Option A: QR to raw script URL
```
https://raw.githubusercontent.com/mattheqd/zendesk-ai-onboarding/main/setup-wizard.sh
```

### Option B: QR to GitHub repo (more readable)
```
https://github.com/mattheqd/zendesk-ai-onboarding
```

**Tools:**
- Online: https://qr-code-generator.com
- Command line: `brew install qrencode`

**Add to your slides:**
"Can't make the setup work? Scan this QR code →"

---

## 📊 Pre-Workshop Checklist

Send this checklist to designers **1 week before**:

- [ ] GlobalProtect VPN installed and working
- [ ] Zendesk GitHub org access (ping #it-help if not)
- [ ] AI Gateway token ready (https://ai-gateway.zende.sk)
- [ ] Run the setup wizard: `bash <(curl -fsSL ...)`
- [ ] Test Claude Code works: `claude --version`

---

## 🎤 Workshop Day Script

### Opening (5 min)

> "Before we dive in, let's make sure everyone has Claude Code working.
>
> If you did the pre-setup, great! Open Terminal and run `claude` to verify.
>
> If you didn't do the setup yet, open Terminal now and run this command..."
>
> **[Show slide with one-liner and QR code]**

### Troubleshooting Station

Have someone available to help with:
- VPN connection issues
- GitHub authentication
- Token problems
- Path not found errors

Common fixes:
```bash
# If claude command not found after install
source ~/.zshrc
# or open a new Terminal window

# If token expired
# Re-run wizard, it will update the token
```

---

## 🔄 Updates After Workshop

If you need to fix scripts or update docs:

```bash
cd /Users/matthew.duong/zendesk-ai-onboarding
# Make your changes
git add .
git commit -m "Your update message"
git push
```

The one-liner automatically gets the latest version from GitHub.

---

## 📈 Success Metrics

Track these to improve future workshops:

- **Pre-setup completion rate** (survey designers: "Did you complete setup before the workshop?")
- **Setup time** (how long did the wizard take?)
- **Failure points** (where did people get stuck?)
- **GitHub access issues** (how many needed last-minute access?)

---

## 🆘 Support Channels

**Before workshop:**
- Questions → workshop organizer email
- GitHub access → #it-help Slack
- VPN issues → IT support

**During workshop:**
- Troubleshooting station
- Pair designers who got it working with those who didn't

---

## 📚 All Resources

| File | Purpose | Share With |
|------|---------|------------|
| [README.md](README.md) | Full documentation | Everyone |
| [QUICKSTART.md](QUICKSTART.md) | Simple instructions | Designers |
| [ONE-PAGER.md](ONE-PAGER.md) | Visual guide | Print/PDF |
| [WORKSHOP-EMAIL.md](WORKSHOP-EMAIL.md) | Email template | Organizers |
| [SLACK-MESSAGE.md](SLACK-MESSAGE.md) | Slack template | Organizers |
| [TESTING.md](TESTING.md) | Testing guide | Organizers |
| [DISTRIBUTION.md](DISTRIBUTION.md) | This file | Organizers |

---

## 🎯 Recommended Timeline

**2 weeks before:**
- [ ] Test setup on clean Mac user account
- [ ] Update any Zendesk-specific instructions
- [ ] Create GitHub access list (who needs it?)

**1 week before:**
- [ ] Send email to all designers ([WORKSHOP-EMAIL.md](WORKSHOP-EMAIL.md))
- [ ] Post Slack announcement ([SLACK-MESSAGE.md](SLACK-MESSAGE.md))
- [ ] Follow up on GitHub access requests

**3 days before:**
- [ ] Remind designers to complete setup
- [ ] Check who's done vs. not done
- [ ] Prepare troubleshooting station materials

**Day of:**
- [ ] Have QR code ready on slides
- [ ] Test one-liner still works
- [ ] Troubleshooting station ready
- [ ] Extra time in schedule for setup help

---

## 🔐 Security Notes

- The one-liner runs a bash script from GitHub
- Designers should verify the URL matches your repo
- Token is stored locally in `~/.claude/settings.json`
- No credentials are sent to external services
- Scripts are open source for review

---

## 🎉 Success Criteria

You'll know it worked when:
- ✅ 90%+ of designers complete pre-setup
- ✅ Workshop starts on time (no 30-min setup delay)
- ✅ Everyone can run `claude` and get a response
- ✅ GitHub authentication is working for everyone

---

**Questions?** Open an issue on the repo or update this guide for future organizers!
