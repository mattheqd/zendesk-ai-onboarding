# Workshop Email Template

Copy this to send to designers before the workshop:

---

**Subject:** Zendesk Claude Code Workshop - Setup Instructions

Hi everyone! 👋

To make sure we can jump right into the workshop, please complete this **one-time setup** on your Mac before we meet. It takes about **10 minutes**.

## 🚀 Setup Instructions

**Step 1:** Connect to **GlobalProtect VPN**

**Step 2:** Open **Terminal** and paste this command:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mattheqd/zendesk-ai-onboarding/main/setup-wizard.sh)
```

**Step 3:** Follow the wizard! It will:
- Check your VPN connection
- Help you get your AI Gateway token
- Install all required tools
- Set up Claude Code

---

## ⚠️ Important: GitHub Access

**If you're not already in the Zendesk GitHub org**, you'll need access to push code during the workshop.

**Action:** Ping **#it-help** on Slack NOW and say:

> "Hi! I need to be added to the Zendesk GitHub organization for the Claude Code workshop. My GitHub username is [YOUR_GITHUB_USERNAME]"

⏰ This takes ~15 minutes if you ask today, but **2 days if you wait until the workshop day**!

---

## 🔑 Getting Your AI Gateway Token

The wizard will help you with this, but here's what you'll need to do:

1. Open https://ai-gateway.zende.sk
2. Log in with your Zendesk credentials
3. Copy your API token (starts with `zdai_`)
4. Paste it into the wizard when prompted

---

## ❓ Troubleshooting

**"Cannot reach ai-gateway.zende.sk"**  
→ Make sure GlobalProtect VPN is connected

**"Not a member of zendesk org"**  
→ See the GitHub Access section above

**Other issues?**  
→ Reply to this email or ping me on Slack

---

## 📚 Documentation

Full setup guide: https://github.com/mattheqd/zendesk-ai-onboarding

---

See you at the workshop!

[Your Name]
