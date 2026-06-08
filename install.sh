#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Dry run mode (set DRY_RUN=1 to test without installing)
DRY_RUN=${DRY_RUN:-0}

if [ "$DRY_RUN" = "1" ]; then
    echo -e "${YELLOW}🔍 DRY RUN MODE - No installations will be performed${NC}"
    echo ""
fi

# Token file from preflight
TOKEN_FILE="$HOME/.zendesk_ai_gateway_token_temp"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Zendesk Claude Code Workshop - Installation${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "This will install all required tools for the workshop."
echo "Grab a coffee ☕ — this takes about 5-10 minutes."
echo ""

# Check if token file exists
if [ ! -f "$TOKEN_FILE" ]; then
    echo -e "${RED}✗ AI Gateway token not found${NC}"
    echo "  → Please run preflight.sh first"
    echo -e "  → ${BLUE}bash preflight.sh${NC}"
    exit 1
fi

# Load the validated token
AI_GATEWAY_TOKEN=$(cat "$TOKEN_FILE")

# Track installation status
INSTALL_SUCCESS=true
FAILED_INSTALLS=()

# Install Homebrew if missing
echo -e "${YELLOW}⏳ Checking Homebrew...${NC}"
if ! command -v brew &> /dev/null; then
    if [ "$DRY_RUN" = "1" ]; then
        echo "  [DRY RUN] Would install Homebrew"
    else
        echo "  Installing Homebrew (this may take a few minutes)..."
        if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            # Add brew to PATH for Apple Silicon Macs
            if [[ $(uname -m) == "arm64" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
        else
            echo -e "${RED}✗ Homebrew installation failed${NC}"
            INSTALL_SUCCESS=false
            FAILED_INSTALLS+=("Homebrew")
        fi
    fi
else
    echo -e "${GREEN}✓ Homebrew already installed${NC}"
fi
echo ""

# Install jq (needed for updating Claude Code settings)
echo -e "${YELLOW}⏳ Checking jq...${NC}"
if ! command -v jq &> /dev/null; then
    if [ "$DRY_RUN" = "1" ]; then
        echo "  [DRY RUN] Would install jq"
    else
        echo "  Installing jq..."
        if ! brew install jq; then
            echo -e "${RED}✗ jq installation failed${NC}"
            INSTALL_SUCCESS=false
            FAILED_INSTALLS+=("jq")
        fi
    fi
else
    echo -e "${GREEN}✓ jq already installed${NC}"
fi
echo ""

# Install Node.js 20+
echo -e "${YELLOW}⏳ Checking Node.js...${NC}"
if ! command -v node &> /dev/null; then
    if [ "$DRY_RUN" = "1" ]; then
        echo "  [DRY RUN] Would install Node.js 20"
    else
        echo "  Installing Node.js 20..."
        if brew install node@20 && brew link --force node@20; then
            echo -e "${GREEN}✓ Node.js installed${NC}"
        else
            echo -e "${RED}✗ Node.js installation failed${NC}"
            INSTALL_SUCCESS=false
            FAILED_INSTALLS+=("Node.js")
        fi
    fi
else
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 20 ]; then
        if [ "$DRY_RUN" = "1" ]; then
            echo "  [DRY RUN] Would upgrade Node.js to version 20"
        else
            echo "  Upgrading Node.js to version 20..."
            if brew install node@20 && brew link --force node@20; then
                echo -e "${GREEN}✓ Node.js upgraded${NC}"
            else
                echo -e "${RED}✗ Node.js upgrade failed${NC}"
                INSTALL_SUCCESS=false
                FAILED_INSTALLS+=("Node.js upgrade")
            fi
        fi
    else
        echo -e "${GREEN}✓ Node.js 20+ already installed${NC}"
    fi
fi
echo ""

# Install GitHub CLI
echo -e "${YELLOW}⏳ Checking GitHub CLI...${NC}"
if ! command -v gh &> /dev/null; then
    if [ "$DRY_RUN" = "1" ]; then
        echo "  [DRY RUN] Would install GitHub CLI"
    else
        echo "  Installing GitHub CLI..."
        if ! brew install gh; then
            echo -e "${RED}✗ GitHub CLI installation failed${NC}"
            INSTALL_SUCCESS=false
            FAILED_INSTALLS+=("GitHub CLI")
        fi
    fi
else
    echo -e "${GREEN}✓ GitHub CLI already installed${NC}"
fi

# Authenticate GitHub CLI if needed
if [ "$DRY_RUN" != "1" ] && command -v gh &> /dev/null && ! gh auth status &> /dev/null; then
    echo ""
    echo -e "${BLUE}Let's connect your GitHub account...${NC}"
    echo ""
    if ! gh auth login; then
        echo -e "${RED}✗ GitHub authentication failed${NC}"
        INSTALL_SUCCESS=false
        FAILED_INSTALLS+=("GitHub authentication")
    fi
elif [ "$DRY_RUN" = "1" ] && ! gh auth status &> /dev/null 2>&1; then
    echo "  [DRY RUN] Would prompt for GitHub authentication"
fi
echo ""

# Install VS Code
echo -e "${YELLOW}⏳ Checking VS Code...${NC}"
if [ ! -d "/Applications/Visual Studio Code.app" ]; then
    if [ "$DRY_RUN" = "1" ]; then
        echo "  [DRY RUN] Would install VS Code"
    else
        echo "  Installing VS Code..."
        if ! brew install --cask visual-studio-code; then
            echo -e "${RED}✗ VS Code installation failed${NC}"
            INSTALL_SUCCESS=false
            FAILED_INSTALLS+=("VS Code")
        fi
    fi
else
    echo -e "${GREEN}✓ VS Code already installed${NC}"
fi
echo ""


# Install Claude Code via AI Gateway
echo -e "${YELLOW}⏳ Installing Claude Code...${NC}"

if ! command -v claude &> /dev/null; then
    if [ "$DRY_RUN" = "1" ]; then
        echo "  [DRY RUN] Would create Claude Code configuration at ~/.claude/settings.json"
        echo "  [DRY RUN] Would add NODE_USE_SYSTEM_CA=1 to shell profiles"
        echo "  [DRY RUN] Would download and install Claude Code"
    else
        echo "  Setting up Claude Code configuration..."

        # Create Claude Code settings with AI Gateway (Bedrock) configuration
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

        echo "  ✓ Configuration saved"

        # Add NODE_USE_SYSTEM_CA to shell profiles for certificate handling
        echo "  Setting up SSL certificates..."
        grep -qF 'NODE_USE_SYSTEM_CA=1' ~/.zprofile 2>/dev/null || echo 'export NODE_USE_SYSTEM_CA=1' >> ~/.zprofile
        grep -qF 'NODE_USE_SYSTEM_CA=1' ~/.bash_profile 2>/dev/null || echo 'export NODE_USE_SYSTEM_CA=1' >> ~/.bash_profile

        # Download and install Claude Code
        echo "  Downloading Claude Code (this may take a minute)..."
        if curl -fsSL https://downloads.claude.ai/claude-code-releases/bootstrap.sh | bash; then
            echo -e "${GREEN}✓ Claude Code installed${NC}"

            # Add to PATH if needed
            if ! command -v claude &> /dev/null; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
                export PATH="$HOME/.local/bin:$PATH"
            fi
        else
            echo -e "${RED}✗ Claude Code installation failed${NC}"
            INSTALL_SUCCESS=false
            FAILED_INSTALLS+=("Claude Code")
        fi
    fi
else
    echo -e "${GREEN}✓ Claude Code already installed${NC}"

    if [ "$DRY_RUN" = "1" ]; then
        echo "  [DRY RUN] Would prompt to update AI Gateway token in existing config"
    else
        # Prompt to update token in existing config
        echo ""
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
                # Use a temp file to safely update the token
                jq --arg token "$AI_GATEWAY_TOKEN" '.env.ANTHROPIC_AUTH_TOKEN = $token' ~/.claude/settings.json > ~/.claude/settings.json.tmp && mv ~/.claude/settings.json.tmp ~/.claude/settings.json
                echo -e "${GREEN}  ✓ Token updated${NC}"
            else
                echo -e "${YELLOW}  ⚠ Settings file not found, skipping token update${NC}"
            fi
        else
            echo "  Keeping your existing token"
        fi
    fi
fi
echo ""

# Final sanity checks
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Running final checks...${NC}"
echo ""

# Check claude
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>&1 || echo "unknown")
    echo -e "${GREEN}✓ Claude Code: $CLAUDE_VERSION${NC}"
else
    echo -e "${RED}✗ Claude Code not found${NC}"
    INSTALL_SUCCESS=false
fi

# Check gh
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version | head -n 1)
    echo -e "${GREEN}✓ $GH_VERSION${NC}"
else
    echo -e "${RED}✗ GitHub CLI not found${NC}"
    INSTALL_SUCCESS=false
fi

# Check VPN
if curl -s --connect-timeout 5 -o /dev/null -w "%{http_code}" https://ai-gateway.zende.sk | grep -q "302\|200"; then
    echo -e "${GREEN}✓ AI Gateway reachable${NC}"
else
    echo -e "${RED}✗ AI Gateway not reachable (check VPN)${NC}"
    INSTALL_SUCCESS=false
fi
echo ""

# Clean up token file
rm -f "$TOKEN_FILE"

# Final summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ "$INSTALL_SUCCESS" = true ]; then
    echo -e "${GREEN}✓ Installation complete! You're ready for the workshop! 🎉${NC}"
    echo ""
    echo "Quick start:"
    echo -e "  ${BLUE}1. Open a new terminal (to load updated PATH)${NC}"
    echo -e "  ${BLUE}2. Run: claude${NC}"
    echo ""
    echo "See you at the workshop!"
else
    echo -e "${RED}⚠️  Some installations failed${NC}"
    echo ""
    echo "The following components had issues:"
    for failed in "${FAILED_INSTALLS[@]}"; do
        echo -e "  ${RED}✗ $failed${NC}"
    done
    echo ""
    echo "Common fixes:"
    echo "  • Check your internet connection"
    echo "  • Make sure you have enough disk space"
    echo "  • Try running the installer again"
    echo ""
    echo "If problems persist, contact the workshop organizers with"
    echo "the specific error messages shown above."
    echo ""
    exit 1
fi
