#!/bin/bash

# Zendesk Claude Code Workshop - Setup Wizard
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

# Helper functions
show_header() {
    clear
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                        ║${NC}"
    echo -e "${CYAN}║     ${BOLD}Zendesk Claude Code Workshop Setup${NC}${CYAN}            ║${NC}"
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

    echo "This wizard will get your Mac ready for the Claude Code workshop."
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
        echo "  1. Ping your manager or #it-help on Slack"
        echo "  2. Ask to be added to the Zendesk GitHub organization"
        echo "  3. This takes ~15 minutes if you ask today, 2 days if you wait"
        echo ""
        echo "You'll need this to push to internal repos during the workshop."
        echo ""
        press_to_continue
    elif ! gh auth status &> /dev/null; then
        echo -e "${YELLOW}⚠ GitHub CLI is not authenticated${NC}"
        echo "  → We'll set this up for you later"
        echo ""
        echo -e "${BLUE}📋 Important: Get Zendesk GitHub access${NC}"
        echo ""
        echo "If you don't already belong to the zendesk GitHub org:"
        echo "  1. Ping your manager or #it-help on Slack"
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
        echo "  1. Ping your manager or #it-help on Slack"
        echo "  2. Ask to be added to the Zendesk GitHub organization"
        echo "  3. This takes ~15 minutes if you ask today, 2 days if you wait"
        echo ""
        echo "You'll need this access to use Claude Code in the workshop."
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
    echo "  • Superwhisper"
    echo ""
    echo "This takes about 5-10 minutes depending on your internet."
    echo ""

    press_to_continue

    # Install Homebrew
    echo ""
    echo -e "${YELLOW}⏳ Checking Homebrew...${NC}"
    if ! command -v brew &> /dev/null; then
        echo "  Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
            echo -e "${RED}✗ Homebrew installation failed${NC}"
            INSTALL_SUCCESS=false
        }

        # Add brew to PATH for Apple Silicon
        if [[ $(uname -m) == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        echo -e "${GREEN}✓ Homebrew already installed${NC}"
    fi

    # Install jq
    echo ""
    echo -e "${YELLOW}⏳ Checking jq...${NC}"
    if ! command -v jq &> /dev/null; then
        echo "  Installing jq..."
        brew install jq || {
            echo -e "${RED}✗ jq installation failed${NC}"
            INSTALL_SUCCESS=false
        }
    else
        echo -e "${GREEN}✓ jq already installed${NC}"
    fi

    # Install Node.js
    echo ""
    echo -e "${YELLOW}⏳ Checking Node.js...${NC}"
    if ! command -v node &> /dev/null; then
        echo "  Installing Node.js 20..."
        brew install node@20 || {
            echo -e "${RED}✗ Node.js installation failed${NC}"
            INSTALL_SUCCESS=false
        }
        brew link --force node@20 || true
    else
        NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -lt 20 ]; then
            echo "  Upgrading Node.js to version 20..."
            brew install node@20 || {
                echo -e "${RED}✗ Node.js upgrade failed${NC}"
                INSTALL_SUCCESS=false
            }
            brew link --force node@20 || true
        else
            echo -e "${GREEN}✓ Node.js 20+ already installed${NC}"
        fi
    fi

    # Install GitHub CLI
    echo ""
    echo -e "${YELLOW}⏳ Checking GitHub CLI...${NC}"
    if ! command -v gh &> /dev/null; then
        echo "  Installing GitHub CLI..."
        brew install gh || {
            echo -e "${RED}✗ GitHub CLI installation failed${NC}"
            INSTALL_SUCCESS=false
        }
    else
        echo -e "${GREEN}✓ GitHub CLI already installed${NC}"
    fi

    # Authenticate GitHub CLI
    if command -v gh &> /dev/null && ! gh auth status &> /dev/null; then
        echo ""
        echo -e "${BLUE}Let's connect your GitHub account...${NC}"
        echo ""
        gh auth login || {
            echo -e "${RED}✗ GitHub authentication failed${NC}"
            INSTALL_SUCCESS=false
        }
    fi

    # Install VS Code
    echo ""
    echo -e "${YELLOW}⏳ Checking VS Code...${NC}"
    if [ ! -d "/Applications/Visual Studio Code.app" ]; then
        echo "  Installing VS Code..."
        brew install --cask visual-studio-code || {
            echo -e "${RED}✗ VS Code installation failed${NC}"
            INSTALL_SUCCESS=false
        }
    else
        echo -e "${GREEN}✓ VS Code already installed${NC}"
    fi

    # Install Superwhisper
    echo ""
    echo -e "${YELLOW}⏳ Checking Superwhisper...${NC}"
    if [ ! -d "/Applications/Superwhisper.app" ]; then
        echo "  Installing Superwhisper..."
        brew install --cask superwhisper || {
            echo -e "${RED}✗ Superwhisper installation failed${NC}"
            INSTALL_SUCCESS=false
        }
    else
        echo -e "${GREEN}✓ Superwhisper already installed${NC}"
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
        else
            echo ""
            echo -e "${RED}✗ Claude Code installation failed${NC}"
            INSTALL_SUCCESS=false
        fi
    else
        echo -e "${GREEN}✓ Claude Code already installed${NC}"
        echo ""

        # Prompt to update token
        echo -e "${BLUE}Your existing Claude Code setup was detected.${NC}"
        echo ""
        echo "Would you like to update your AI Gateway access token?"
        echo "  → Only say yes if your current token has expired or stopped working"
        echo "  → If Claude Code is working fine for you, you can skip this"
        echo ""
        read -p "Update token? (y/N): " -n 1 -r
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [ -f ~/.claude/settings.json ]; then
                jq --arg token "$AI_GATEWAY_TOKEN" '.env.ANTHROPIC_AUTH_TOKEN = $token' ~/.claude/settings.json > ~/.claude/settings.json.tmp && mv ~/.claude/settings.json.tmp ~/.claude/settings.json
                echo -e "${GREEN}  ✓ Token updated${NC}"
            fi
        else
            echo "  Keeping your existing token"
        fi
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

    echo ""

    # Clean up token file
    rm -f "$TOKEN_FILE"

    if [ "$INSTALL_SUCCESS" = true ]; then
        echo -e "${GREEN}${BOLD}🎉 All set! You're ready for the workshop!${NC}"
        echo ""
        echo "Quick start:"
        echo -e "  ${BLUE}1. Open a new terminal (to load updated PATH)${NC}"
        echo -e "  ${BLUE}2. Run: claude${NC}"
        echo ""
        echo "See you at the workshop!"
    else
        echo -e "${RED}Some installations had issues.${NC}"
        echo "Please contact the workshop organizers for help."
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
