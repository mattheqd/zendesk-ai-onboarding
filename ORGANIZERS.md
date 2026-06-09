# Workshop Organizer Guide

## 📧 How to Share Setup with Designers

Just send them the GitHub Pages URL:

```
https://mattheqd.github.io/zendesk-ai-onboarding/
```

That's it! The page has everything they need.

---

## 📅 Timeline

**2 weeks before:**
- [ ] Test setup on a clean Mac (create test user account)
- [ ] Review and customize the GitHub Pages site if needed

**1 week before:**
Send email:

```
Subject: Claude Code Workshop - Setup Required

Hi team!

Please complete the setup before the workshop (~10 minutes):

https://mattheqd.github.io/zendesk-ai-onboarding/

Make sure to request GitHub access early if you don't have it yet.

See you at the workshop!
```

**3 days before:**
Post in Slack:

```
:wave: Workshop reminder - please complete setup if you haven't yet:

https://mattheqd.github.io/zendesk-ai-onboarding/

Takes ~10 minutes. Thread any issues below!
```

**Day of workshop:**
Opening script:

> "Welcome! Before we dive in, who has completed the setup? Raise your hand.
>
> If you haven't set up yet, open: **mattheqd.github.io/zendesk-ai-onboarding**
>
> [Show slide with URL and QR code]
>
> For those ready, open Terminal and run `claude --version` to verify."

---

## 🔧 Updating the Setup

All changes go through GitHub:

```bash
# Edit the page
code docs/index.html

# Commit and push
git add docs/index.html
git commit -m "Update workshop setup page"
git push

# GitHub Pages auto-deploys in 1-2 minutes
```

---

## 📊 Tracking Setup Completion

Post in workshop Slack channel:

```
Quick poll - setup status:

:white_check_mark: Setup complete
:construction: In progress
:question: Haven't started
:sos: Hit an issue

React below!
```

---

## 🆘 Common Issues on Workshop Day

**"claude command not found"**
→ Open a **new** terminal window, or run: `source ~/.zshrc`

**"Cannot reach ai-gateway"**
→ Connect to GlobalProtect VPN

**"GitHub authentication fails"**
→ Choose: GitHub.com, HTTPS, Login with web browser

**"Not in zendesk org"**
→ Too late for workshop - they can pair with someone who has access

**"Marketplace command fails"**
→ Make sure `gh auth status` shows they're authenticated. The marketplace uses HTTPS (not SSH) via GitHub CLI credentials from setup.

---

## 📁 Files in This Repo

- **docs/index.html** - GitHub Pages site (main setup page)
- **setup-wizard.sh** - Interactive setup script
- **preflight.sh** - Checks-only phase
- **install.sh** - Installation phase
- **README.md** - Full documentation
- **TESTING.md** - Testing guide for organizers
- **ORGANIZERS.md** - This file

---

## 🔗 Quick Links

- **Setup page:** https://mattheqd.github.io/zendesk-ai-onboarding/
- **GitHub repo:** https://github.com/mattheqd/zendesk-ai-onboarding
- **AI Gateway:** https://ai-gateway.zende.sk
