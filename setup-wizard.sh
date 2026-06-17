#!/bin/bash

# Zendesk Claude Code - Setup Wizard for Designer AI Enablement
# One-file interactive installer for designers

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Wizard state
STEP=1
TOTAL_STEPS=6

# Track status
ALL_CHECKS_PASSED=true
INSTALL_SUCCESS=true
AI_GATEWAY_TOKEN=""
TOKEN_FILE="$HOME/.zendesk_ai_gateway_token_temp"
USED_EXISTING_TOKEN=false

# Track failed installations
FAILED_INSTALLS=()

# Helper functions
show_header() {
    clear
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                        ║${NC}"
    echo -e "${CYAN}║     ${BOLD}Claude Code + Designer AI Tools Setup${NC}${CYAN}        ║${NC}"
    echo -e "${CYAN}║                                                        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Step $STEP of $TOTAL_STEPS${NC}"
    echo ""
}

show_step() {
    echo ""
    echo -e "${BOLD}$1${NC}"
    echo -e "${BLUE}────────────────────────────────────────────────────────${NC}"
    echo ""
}

press_to_continue() {
    echo ""
    read -p "Press Enter to continue..."
}

# Step 1: Welcome
step_welcome() {
    show_header
    show_step "👋 Welcome!"

    echo "This wizard will set up Claude Code and AI utilities for designers."
    echo ""
    echo "What we'll do:"
    echo "  1. Check your VPN connection"
    echo "  2. Verify GitHub access"
    echo "  3. Set up your AI Gateway token"
    echo "  4. Install required tools (Homebrew, Node, VS Code, etc.)"
    echo "  5. Install Claude Code"
    echo ""
    echo "Time needed: About 10 minutes"
    echo ""

    press_to_continue
    ((STEP++))
}

# Step 2: VPN Check
step_vpn_check() {
    show_header
    show_step "🔒 Checking VPN Connection"

    if curl -s --connect-timeout 5 -o /dev/null -w "%{http_code}" https://ai-gateway.zende.sk | grep -q "302\|200"; then
        echo -e "${GREEN}✓ VPN is connected${NC}"
        echo ""
        press_to_continue
    else
        echo -e "${RED}✗ Cannot reach ai-gateway.zende.sk${NC}"
        echo ""
        echo "Please connect to GlobalProtect VPN and try again."
        echo ""
        read -p "Press Enter after connecting to VPN..."

        # Retry
        if curl -s --connect-timeout 5 -o /dev/null -w "%{http_code}" https://ai-gateway.zende.sk | grep -q "302\|200"; then
            echo -e "${GREEN}✓ VPN is now connected${NC}"
            echo ""
            press_to_continue
        else
            echo -e "${RED}✗ Still can't reach the AI Gateway${NC}"
            echo "Please make sure GlobalProtect is running and connected."
            echo ""
            read -p "Try again? (y/N): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                step_vpn_check
                return
            else
                echo "Setup cancelled."
                exit 1
            fi
        fi
    fi

    ((STEP++))
}

# Step 3: GitHub Check
step_github_check() {
    show_header
    show_step "🐙 Checking GitHub Access"

    if ! command -v gh &> /dev/null; then
        echo -e "${YELLOW}⚠ GitHub CLI is not installed yet${NC}"
        echo "  → We'll install this for you later"
        echo ""
        echo -e "${BLUE}📋 Important: Get Zendesk GitHub access${NC}"
        echo ""
        echo "If you don't already belong to the zendesk GitHub org:"
        echo "  1. Request access via Okta Zendesk Hub → Productiv"
        echo "  2. Ask to be added to the Zendesk GitHub organization"
        echo "  3. This takes ~15 minutes if you ask today, 2 days if you wait"
        echo ""
        echo "You'll need this to access internal Zendesk repositories."
        echo ""
        press_to_continue
    elif ! gh auth status &> /dev/null; then
        echo -e "${YELLOW}⚠ GitHub CLI is not authenticated${NC}"
        echo "  → We'll set this up for you later"
        echo ""
        echo -e "${BLUE}📋 Important: Get Zendesk GitHub access${NC}"
        echo ""
        echo "If you don't already belong to the zendesk GitHub org:"
        echo "  1. Request access via Okta Zendesk Hub → Productiv"
        echo "  2. Ask to be added to the Zendesk GitHub organization"
        echo "  3. This takes ~15 minutes if you ask today, 2 days if you wait"
        echo ""
        press_to_continue
    elif gh api /user/orgs --jq '.[].login' 2>/dev/null | grep -q "^zendesk$"; then
        echo -e "${GREEN}✓ GitHub CLI is installed${NC}"
        echo -e "${GREEN}✓ You're a member of the zendesk org${NC}"
        echo ""
        press_to_continue
    else
        echo -e "${RED}✗ You're not a member of the zendesk GitHub org${NC}"
        echo ""
        echo -e "${BLUE}📋 Action needed before continuing:${NC}"
        echo ""
        echo "  1. Request access via Okta Zendesk Hub → Productiv"
        echo "  2. Ask to be added to the Zendesk GitHub organization"
        echo "  3. This takes ~15 minutes if you ask today, 2 days if you wait"
        echo ""
        echo "You'll need this access to use Claude Code at Zendesk."
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Setup cancelled. Come back after getting GitHub access!"
            exit 1
        fi
    fi

    ((STEP++))
}

# Step 4: AI Gateway Token
step_token_setup() {
    show_header
    show_step "🔑 Setting Up AI Gateway Access"

    # Check if user already has a token in existing Claude Code config
    if [ -f ~/.claude/settings.json ]; then
        EXISTING_TOKEN=$(jq -r '.env.ANTHROPIC_AUTH_TOKEN // empty' ~/.claude/settings.json 2>/dev/null)
        if [[ "$EXISTING_TOKEN" =~ ^zdai_ ]]; then
            echo "Found existing AI Gateway token in Claude Code config."
            echo ""
            echo -e "${YELLOW}Testing existing token...${NC}"

            # Test existing token
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
                -H "Authorization: Bearer $EXISTING_TOKEN" \
                https://ai-gateway.zende.sk/bedrock/v1/messages \
                -H "Content-Type: application/json" \
                -d '{"model":"claude-sonnet-4.5","max_tokens":1,"messages":[{"role":"user","content":"test"}]}' 2>/dev/null)

            if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "400" ]]; then
                echo -e "${GREEN}✓ Existing token is valid!${NC}"
                echo ""
                read -p "Use this token? (Y/n): " -n 1 -r
                echo ""
                if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                    AI_GATEWAY_TOKEN="$EXISTING_TOKEN"
                    USED_EXISTING_TOKEN=true
                    echo "$AI_GATEWAY_TOKEN" > "$TOKEN_FILE"
                    chmod 600 "$TOKEN_FILE"
                    press_to_continue
                    ((STEP++))
                    return
                fi
            else
                echo -e "${YELLOW}⚠ Existing token is invalid or expired${NC}"
                echo "Let's get a fresh one."
                echo ""
            fi
        fi
    fi

    # No valid existing token, proceed to get a new one
    echo "You'll need an AI Gateway token to use Claude Code."
    echo ""
    echo -e "${BLUE}To get your token:${NC}"
    echo "  1. Open https://ai-gateway.zende.sk in your browser"
    echo "  2. Log in with your Zendesk credentials"
    echo "  3. Look for your API token (starts with 'zdai_')"
    echo "  4. Copy the entire token"
    echo ""

    # Open browser for them
    read -p "Open AI Gateway in browser now? (Y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        open "https://ai-gateway.zende.sk" 2>/dev/null || true
        echo "Browser opened. Copy your token and come back here."
        echo ""
    fi

    read -p "Paste your AI Gateway token here: " AI_GATEWAY_TOKEN

    # Trim whitespace
    AI_GATEWAY_TOKEN=$(echo "$AI_GATEWAY_TOKEN" | xargs)

    # Validate token format
    if [[ ! "$AI_GATEWAY_TOKEN" =~ ^zdai_ ]]; then
        echo ""
        echo -e "${RED}✗ Token doesn't look right (should start with 'zdai_')${NC}"
        echo ""
        read -p "Try again? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            step_token_setup
            return
        else
            echo "Setup cancelled."
            exit 1
        fi
    fi

    echo ""
    echo -e "${YELLOW}Testing token...${NC}"

    # Test token against AI Gateway
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $AI_GATEWAY_TOKEN" \
        https://ai-gateway.zende.sk/bedrock/v1/messages \
        -H "Content-Type: application/json" \
        -d '{"model":"claude-sonnet-4.5","max_tokens":1,"messages":[{"role":"user","content":"test"}]}')

    if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "400" ]]; then
        echo -e "${GREEN}✓ AI Gateway token is valid!${NC}"
        echo ""

        # Store token for later use
        echo "$AI_GATEWAY_TOKEN" > "$TOKEN_FILE"
        chmod 600 "$TOKEN_FILE"

        press_to_continue
    else
        echo -e "${RED}✗ Token validation failed (HTTP $HTTP_CODE)${NC}"
        echo ""
        read -p "Try again? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            step_token_setup
            return
        else
            echo "Setup cancelled."
            exit 1
        fi
    fi

    ((STEP++))
}

# Step 5: Install Tools
step_install_tools() {
    show_header
    show_step "📦 Installing Required Tools"

    echo "This will install:"
    echo "  • Homebrew (package manager)"
    echo "  • Node.js 20+"
    echo "  • GitHub CLI"
    echo "  • jq (JSON processor)"
    echo "  • VS Code"
    echo ""
    echo "This takes about 5-10 minutes depending on your internet."
    echo ""

    press_to_continue

    # Install Homebrew
    echo ""
    echo -e "${YELLOW}⏳ Checking Homebrew...${NC}"
    if ! command -v brew &> /dev/null; then
        echo "  Installing Homebrew..."
        echo ""
        echo -e "${BLUE}  Note: You may be asked for your Mac password.${NC}"
        echo -e "${BLUE}  The password won't show as you type (not even dots) - this is normal.${NC}"
        echo -e "${BLUE}  Just type your password and press Enter.${NC}"
        echo ""
        if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            # Add brew to PATH for Apple Silicon
            if [[ $(uname -m) == "arm64" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
        else
            echo -e "${RED}✗ Homebrew installation failed${NC}"
            INSTALL_SUCCESS=false
            FAILED_INSTALLS+=("Homebrew")
        fi
    else
        echo -e "${GREEN}✓ Homebrew already installed${NC}"
    fi

    # Install jq
    echo ""
    echo -e "${YELLOW}⏳ Checking jq...${NC}"
    if ! command -v jq &> /dev/null; then
        echo "  Installing jq..."
        if brew install jq; then
            echo -e "${GREEN}✓ jq installed${NC}"
        else
            echo -e "${RED}✗ jq installation failed${NC}"
            INSTALL_SUCCESS=false
            FAILED_INSTALLS+=("jq")
        fi
    else
        echo -e "${GREEN}✓ jq already installed${NC}"
    fi

    # Install Node.js
    echo ""
    echo -e "${YELLOW}⏳ Checking Node.js...${NC}"
    if ! command -v node &> /dev/null; then
        echo "  Installing Node.js 20..."
        if brew install node@20 && brew link --force node@20; then
            echo -e "${GREEN}✓ Node.js installed${NC}"
        else
            echo -e "${RED}✗ Node.js installation failed${NC}"
            INSTALL_SUCCESS=false
            FAILED_INSTALLS+=("Node.js")
        fi
    else
        NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -lt 20 ]; then
            echo "  Upgrading Node.js to version 20..."
            if brew install node@20 && brew link --force node@20; then
                echo -e "${GREEN}✓ Node.js upgraded${NC}"
            else
                echo -e "${RED}✗ Node.js upgrade failed${NC}"
                INSTALL_SUCCESS=false
                FAILED_INSTALLS+=("Node.js upgrade")
            fi
        else
            echo -e "${GREEN}✓ Node.js 20+ already installed${NC}"
        fi
    fi

    # Install GitHub CLI
    echo ""
    echo -e "${YELLOW}⏳ Checking GitHub CLI...${NC}"
    if ! command -v gh &> /dev/null; then
        echo "  Installing GitHub CLI..."
        if brew install gh; then
            echo -e "${GREEN}✓ GitHub CLI installed${NC}"
        else
            echo -e "${RED}✗ GitHub CLI installation failed${NC}"
            INSTALL_SUCCESS=false
            FAILED_INSTALLS+=("GitHub CLI")
        fi
    else
        echo -e "${GREEN}✓ GitHub CLI already installed${NC}"
    fi

    # Authenticate GitHub CLI
    if command -v gh &> /dev/null && ! gh auth status &> /dev/null; then
        echo ""
        echo -e "${BLUE}Let's connect your GitHub account...${NC}"
        echo ""
        echo "This will open your browser to log in with GitHub."
        echo ""

        # Retry loop for GitHub authentication
        MAX_RETRIES=3
        RETRY_COUNT=0
        AUTH_SUCCESS=false

        while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$AUTH_SUCCESS" = false ]; do
            if [ $RETRY_COUNT -gt 0 ]; then
                echo ""
                echo -e "${YELLOW}Attempt $((RETRY_COUNT + 1)) of $MAX_RETRIES${NC}"
                echo ""
            fi

            # Auto-select HTTPS protocol and web browser login
            if gh auth login -h github.com -p https -w; then
                AUTH_SUCCESS=true
                echo ""
                echo -e "${GREEN}✓ GitHub authentication successful!${NC}"
            else
                ((RETRY_COUNT++))
                if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                    echo ""
                    echo -e "${RED}✗ Authentication failed${NC}"
                    echo ""
                    read -p "Try again? (Y/n): " -n 1 -r
                    echo ""
                    if [[ $REPLY =~ ^[Nn]$ ]]; then
                        break
                    fi
                fi
            fi
        done

        if [ "$AUTH_SUCCESS" = false ]; then
            echo ""
            echo -e "${RED}✗ GitHub authentication failed after $RETRY_COUNT attempts${NC}"
            echo ""
            echo "Don't worry! You can authenticate later by running:"
            echo -e "  ${BLUE}gh auth login${NC}"
            echo ""
            echo "The rest of the setup will continue."
            INSTALL_SUCCESS=false
            FAILED_INSTALLS+=("GitHub authentication")

            read -p "Press Enter to continue..."
        else
            # GitHub auth succeeded - marketplace will use HTTPS
            echo ""
            echo -e "${GREEN}✓ GitHub authentication successful!${NC}"
            echo "  → Marketplace will use HTTPS with your GitHub login"
            echo ""
        fi
    fi

    # Install VS Code
    echo ""
    echo -e "${YELLOW}⏳ Checking VS Code...${NC}"
    if [ ! -d "/Applications/Visual Studio Code.app" ]; then
        echo "  Installing VS Code..."
        if brew install --cask visual-studio-code; then
            echo -e "${GREEN}✓ VS Code installed${NC}"
        else
            echo -e "${RED}✗ VS Code installation failed${NC}"
            INSTALL_SUCCESS=false
            FAILED_INSTALLS+=("VS Code")
        fi
    else
        echo -e "${GREEN}✓ VS Code already installed${NC}"
    fi

    echo ""
    press_to_continue
    ((STEP++))
}

# Step 6: Install Claude Code
step_install_claude() {
    show_header
    show_step "🤖 Installing Claude Code"

    if ! command -v claude &> /dev/null; then
        echo "Setting up Claude Code configuration..."
        echo ""

        # Create settings
        mkdir -p ~/.claude

        cat > ~/.claude/settings.json << EOF
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "true",
    "ANTHROPIC_BEDROCK_BASE_URL": "https://ai-gateway.zende.sk/bedrock",
    "CLAUDE_CODE_SKIP_BEDROCK_AUTH": "true",
    "ANTHROPIC_AUTH_TOKEN": "$AI_GATEWAY_TOKEN",
    "DISABLE_PROMPT_CACHING": "false"
  }
}
EOF

        echo -e "${GREEN}✓ Configuration saved${NC}"
        echo ""

        # Add SSL cert handling
        echo "Setting up SSL certificates..."
        grep -qF 'NODE_USE_SYSTEM_CA=1' ~/.zprofile 2>/dev/null || echo 'export NODE_USE_SYSTEM_CA=1' >> ~/.zprofile
        grep -qF 'NODE_USE_SYSTEM_CA=1' ~/.bash_profile 2>/dev/null || echo 'export NODE_USE_SYSTEM_CA=1' >> ~/.bash_profile
        echo -e "${GREEN}✓ SSL configured${NC}"
        echo ""

        # Install Claude Code
        echo "Downloading Claude Code (this may take a minute)..."
        echo ""
        if curl -fsSL https://downloads.claude.ai/claude-code-releases/bootstrap.sh | bash; then
            echo ""
            echo -e "${GREEN}✓ Claude Code installed!${NC}"

            # Add to PATH
            if ! command -v claude &> /dev/null; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
                export PATH="$HOME/.local/bin:$PATH"
            fi

            # === MARKETPLACE SETUP ===
            echo ""
            echo -e "${BLUE}🏪 Setting up Zendesk Marketplace...${NC}"
            echo ""

            # Source shell config to pick up PATH changes
            if [ -f ~/.zshrc ]; then
                source ~/.zshrc 2>/dev/null || true
            fi

            # Use explicit path to Claude binary
            CLAUDE_BIN="$HOME/.local/bin/claude"

            # Check if marketplace is already configured
            if [ -f ~/.claude/plugins/known_marketplaces.json ] && grep -q "zendesk" ~/.claude/plugins/known_marketplaces.json 2>/dev/null; then
                echo -e "${GREEN}✓ Zendesk Marketplace already configured!${NC}"
                echo "  → You can install plugins when you open Claude in your terminal like:"
                echo -e "    ${BLUE}/plugin install zendeskdev-article-writer${NC}"
                echo ""
            elif [ ! -f "$CLAUDE_BIN" ]; then
                echo "  The marketplace provides Zendesk-specific plugins."
                echo "  This is optional - we'll continue if it fails."
                echo ""
                echo -e "${YELLOW}⚠ Claude binary not found yet - skipping marketplace${NC}"
                echo "  → You can add it manually after opening a new terminal"
                echo ""
            elif ! command -v gh &> /dev/null || ! gh auth status &> /dev/null 2>&1 || ! gh api /user/orgs --jq '.[].login' 2>/dev/null | grep -q "^zendesk$"; then
                echo "  The marketplace provides Zendesk-specific plugins."
                echo "  This is optional - we'll continue if it fails."
                echo ""
                echo -e "${YELLOW}⚠ GitHub not authenticated or not in zendesk org - skipping marketplace${NC}"
                echo "  → Authenticate with 'gh auth login' and join zendesk org, then add marketplace manually"
                echo ""
            else
                echo "  The marketplace provides Zendesk-specific plugins."
                echo "  This is optional - we'll continue if it fails."
                echo ""
                # Try to add marketplace
                echo "  Adding zendesk/claude-code-marketplace..."

                # Set GIT_CONFIG_COUNT to force HTTPS for this command only (doesn't affect global config)
                if GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.https://github.com/.insteadOf" GIT_CONFIG_VALUE_0="git@github.com:" "$CLAUDE_BIN" plugin marketplace add zendesk/claude-code-marketplace 2>&1; then
                    echo ""
                    echo -e "${GREEN}✓ Marketplace added successfully!${NC}"
                    echo "  → You can now install plugins when you open Claude in your terminal like:"
                    echo -e "    ${BLUE}/plugin install zendeskdev-article-writer${NC}"
                    echo ""
                else
                    MARKETPLACE_EXIT=$?
                    echo ""
                    echo -e "${YELLOW}⚠ Marketplace setup skipped (exit code: $MARKETPLACE_EXIT)${NC}"
                    echo ""
                    echo "  Common reasons:"
                    echo "    • Network timeout or VPN issues"
                    echo "    • Repository access permissions"
                    echo ""
                    echo "  You can add it manually later:"
                    echo -e "    ${BLUE}claude${NC}"
                    echo -e "    ${BLUE}/plugin marketplace add zendesk/claude-code-marketplace${NC}"
                    echo ""
                fi
            fi
            # === END MARKETPLACE SETUP ===
        else
            echo ""
            echo -e "${RED}✗ Claude Code installation failed${NC}"
            INSTALL_SUCCESS=false
            FAILED_INSTALLS+=("Claude Code")
        fi
    else
        echo -e "${GREEN}✓ Claude Code already installed${NC}"
        echo ""

        # Only update config if they provided a NEW token (not if they reused existing)
        if [ "$USED_EXISTING_TOKEN" = "true" ]; then
            echo "Token already configured - no changes needed."
        else
            # They provided a new token, offer to update the config
            echo -e "${BLUE}Would you like to update your AI Gateway token?${NC}"
            echo "  → Say yes if you got a fresh token"
            echo "  → Say no to keep your existing token"
            echo ""
            read -p "Update token? (y/N): " -n 1 -r
            echo ""

            if [[ $REPLY =~ ^[Yy]$ ]]; then
                if [ -f ~/.claude/settings.json ]; then
                    jq --arg token "$AI_GATEWAY_TOKEN" '.env.ANTHROPIC_AUTH_TOKEN = $token' ~/.claude/settings.json > ~/.claude/settings.json.tmp && mv ~/.claude/settings.json.tmp ~/.claude/settings.json
                    echo -e "${GREEN}  ✓ Token updated${NC}"
                else
                    echo -e "${YELLOW}  ⚠ Settings file not found${NC}"
                fi
            else
                echo "  Keeping your existing token"
            fi
        fi

        # === MARKETPLACE SETUP (for existing Claude) ===
        echo ""
        echo -e "${BLUE}🏪 Checking Zendesk Marketplace...${NC}"
        echo ""

        # Check if marketplace is already configured
        if [ -f ~/.claude/plugins/known_marketplaces.json ] && grep -q "zendesk" ~/.claude/plugins/known_marketplaces.json 2>/dev/null; then
            echo -e "${GREEN}✓ Zendesk Marketplace already configured!${NC}"
            echo "  → You can install plugins when you open Claude in your terminal like:"
            echo -e "    ${BLUE}/plugin install zendeskdev-article-writer${NC}"
            echo ""
        elif ! command -v gh &> /dev/null || ! gh auth status &> /dev/null 2>&1 || ! gh api /user/orgs --jq '.[].login' 2>/dev/null | grep -q "^zendesk$"; then
            echo "  The marketplace provides Zendesk-specific plugins."
            echo "  This is optional - we'll continue if it fails."
            echo ""
            echo -e "${YELLOW}⚠ GitHub not authenticated or not in zendesk org - skipping marketplace${NC}"
            echo "  → Authenticate with 'gh auth login' and join zendesk org, then add marketplace manually"
            echo ""
        else
            echo "  The marketplace provides Zendesk-specific plugins."
            echo "  This is optional - we'll continue if it fails."
            echo ""
            # Try to add marketplace
            echo "  Adding zendesk/claude-code-marketplace..."

            # Set GIT_CONFIG_COUNT to force HTTPS for this command only (doesn't affect global config)
            if GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.https://github.com/.insteadOf" GIT_CONFIG_VALUE_0="git@github.com:" claude plugin marketplace add zendesk/claude-code-marketplace 2>&1; then
                echo ""
                echo -e "${GREEN}✓ Marketplace added successfully!${NC}"
                echo "  → You can now install plugins when you open Claude in your terminal like:"
                echo -e "    ${BLUE}/plugin install zendeskdev-article-writer${NC}"
                echo ""
            else
                MARKETPLACE_EXIT=$?
                echo ""
                echo -e "${YELLOW}⚠ Marketplace setup skipped (exit code: $MARKETPLACE_EXIT)${NC}"
                echo ""
                echo "  Common reasons:"
                echo "    • Network timeout or VPN issues"
                echo "    • Repository access permissions"
                echo ""
                echo "  You can add it manually later:"
                echo -e "    ${BLUE}claude${NC}"
                echo -e "    ${BLUE}/plugin marketplace add zendesk/claude-code-marketplace${NC}"
                echo ""
            fi
        fi
        # === END MARKETPLACE SETUP ===
    fi

    echo ""
    press_to_continue
    ((STEP++))
}

# Step 7: Final Check
step_final_check() {
    show_header
    show_step "✅ Final Check"

    echo "Verifying everything is working..."
    echo ""

    # Check all tools
    if command -v claude &> /dev/null; then
        CLAUDE_VERSION=$(claude --version 2>&1 || echo "unknown")
        echo -e "${GREEN}✓ Claude Code: $CLAUDE_VERSION${NC}"
    else
        echo -e "${RED}✗ Claude Code not found${NC}"
        INSTALL_SUCCESS=false
    fi

    if command -v gh &> /dev/null; then
        GH_VERSION=$(gh --version | head -n 1)
        echo -e "${GREEN}✓ $GH_VERSION${NC}"
    else
        echo -e "${RED}✗ GitHub CLI not found${NC}"
        INSTALL_SUCCESS=false
    fi

    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        echo -e "${GREEN}✓ Node.js: $NODE_VERSION${NC}"
    else
        echo -e "${RED}✗ Node.js not found${NC}"
        INSTALL_SUCCESS=false
    fi

    if curl -s --connect-timeout 5 -o /dev/null -w "%{http_code}" https://ai-gateway.zende.sk | grep -q "302\|200"; then
        echo -e "${GREEN}✓ AI Gateway reachable${NC}"
    else
        echo -e "${RED}✗ AI Gateway not reachable${NC}"
        INSTALL_SUCCESS=false
    fi

    # Check marketplace configuration (optional)
    if [ -f ~/.claude/plugins/known_marketplaces.json ] && grep -q "zendesk" ~/.claude/plugins/known_marketplaces.json 2>/dev/null; then
        echo -e "${GREEN}✓ Zendesk Marketplace configured${NC}"
    else
        echo -e "${YELLOW}⚠ Zendesk Marketplace not configured (optional)${NC}"
        echo -e "  → You can add it later with: ${BLUE}claude plugin marketplace add zendesk/claude-code-marketplace${NC}"
    fi

    echo ""

    # Clean up token file
    rm -f "$TOKEN_FILE"

    if [ "$INSTALL_SUCCESS" = true ]; then
        echo -e "${GREEN}${BOLD}🎉 All set! You're ready to use Claude Code!${NC}"
        echo ""
        echo "Quick start:"
        echo -e "  ${BLUE}1. Open a new terminal (to load updated PATH)${NC}"
        echo -e "  ${BLUE}2. Run: claude${NC}"
        echo ""
        echo "Happy building with AI! 🚀"
    else
        echo -e "${RED}${BOLD}⚠️  Some installations failed${NC}"
        echo ""
        echo "The following components had issues:"
        for failed in "${FAILED_INSTALLS[@]}"; do
            echo -e "  ${RED}✗ $failed${NC}"
        done
        echo ""
        echo "Common fixes:"
        echo "  • Check your internet connection"
        echo "  • Make sure you have enough disk space"
        echo "  • Try running the wizard again"
        echo ""
        echo "If problems persist, contact your team lead with"
        echo "the specific error messages shown above."
    fi

    echo ""
}

# Main wizard flow
main() {
    step_welcome
    step_vpn_check
    step_github_check
    step_token_setup
    step_install_tools
    step_install_claude
    step_final_check
}

# Run the wizard
main
