#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track overall status
ALL_CHECKS_PASSED=true

# Temp file to store validated token
TOKEN_FILE="$HOME/.zendesk_ai_gateway_token_temp"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Zendesk Claude Code Workshop - Preflight Check${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "This will check your system is ready for the workshop."
echo "No installations happen during preflight."
echo ""

# Check 1: VPN connectivity
echo -e "${YELLOW}⏳ Checking VPN connection...${NC}"
# Use curl instead of ping since ICMP may be blocked
if curl -s --connect-timeout 5 -o /dev/null -w "%{http_code}" https://ai-gateway.zende.sk | grep -q "302\|200"; then
    echo -e "${GREEN}✓ VPN is connected${NC}"
else
    echo -e "${RED}✗ Cannot reach ai-gateway.zende.sk${NC}"
    echo "  → Please connect to GlobalProtect VPN"
    echo "  → Open GlobalProtect and connect, then re-run this script"
    ALL_CHECKS_PASSED=false
fi
echo ""

# Check 2: GitHub CLI installation and org membership
echo -e "${YELLOW}⏳ Checking GitHub access...${NC}"
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠ GitHub CLI (gh) is not installed${NC}"
    echo "  → The install script will install this for you"
    echo ""
    echo -e "${BLUE}📋 Action needed: Get Zendesk GitHub access${NC}"
    echo "  If you don't already belong to the zendesk GitHub org:"
    echo "  1. Ping your manager or #it-help on Slack"
    echo "  2. Ask to be added to the Zendesk GitHub organization"
    echo "  3. This takes ~15 minutes if you ask today, 2 days if you wait"
    echo ""
    echo "  You'll need this to push to internal repos during the workshop."
else
    echo -e "${GREEN}✓ GitHub CLI is installed${NC}"

    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        echo -e "${YELLOW}⚠ GitHub CLI is not authenticated${NC}"
        echo "  → The install script will handle this for you"
        echo ""
        echo -e "${BLUE}📋 Action needed: Get Zendesk GitHub access${NC}"
        echo "  If you don't already belong to the zendesk GitHub org:"
        echo "  1. Ping your manager or #it-help on Slack"
        echo "  2. Ask to be added to the Zendesk GitHub organization"
        echo "  3. This takes ~15 minutes if you ask today, 2 days if you wait"
        echo ""
        echo "  You'll need this to push to internal repos during the workshop."
    else
        # Check org membership
        if gh api /user/orgs --jq '.[].login' 2>/dev/null | grep -q "^zendesk$"; then
            echo -e "${GREEN}✓ You're a member of the zendesk org${NC}"
        else
            echo -e "${RED}✗ You're not a member of the zendesk GitHub org${NC}"
            echo ""
            echo -e "${BLUE}📋 Action needed: Get Zendesk GitHub access${NC}"
            echo "  1. Ping your manager or #it-help on Slack"
            echo "  2. Ask to be added to the Zendesk GitHub organization"
            echo "  3. This takes ~15 minutes if you ask today, 2 days if you wait"
            echo ""
            echo "  You'll need this to push to internal repos during the workshop."
            ALL_CHECKS_PASSED=false
        fi
    fi
fi
echo ""

# Check 3: AI Gateway token
echo -e "${YELLOW}⏳ Setting up AI Gateway access...${NC}"
echo ""

# Check for existing token first
EXISTING_TOKEN=""
if [ -f ~/.claude/settings.json ]; then
    EXISTING_TOKEN=$(command -v jq &> /dev/null && jq -r '.env.ANTHROPIC_AUTH_TOKEN // empty' ~/.claude/settings.json 2>/dev/null || echo "")
fi

if [[ "$EXISTING_TOKEN" =~ ^zdai_ ]]; then
    echo "Found existing AI Gateway token in Claude Code config."
    echo -e "${YELLOW}  Testing existing token...${NC}"

    # Test existing token
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $EXISTING_TOKEN" \
        https://ai-gateway.zende.sk/bedrock/v1/messages \
        -H "Content-Type: application/json" \
        -d '{"model":"claude-sonnet-4.5","max_tokens":1,"messages":[{"role":"user","content":"test"}]}' 2>/dev/null)

    if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "400" ]]; then
        echo -e "${GREEN}✓ Existing token is valid - will use this${NC}"
        echo "$EXISTING_TOKEN" > "$TOKEN_FILE"
        chmod 600 "$TOKEN_FILE"
    else
        echo -e "${YELLOW}⚠ Existing token is invalid or expired${NC}"
        echo "  → You'll need to provide a fresh token"
        echo ""

        # Continue to prompt for new token below
        EXISTING_TOKEN=""
    fi
fi

# If no valid existing token, prompt for a new one
if [[ ! "$EXISTING_TOKEN" =~ ^zdai_ ]]; then
    echo "You'll need an AI Gateway token to use Claude Code."
    echo ""
    echo -e "${BLUE}To get your token:${NC}"
    echo "  1. Open https://ai-gateway.zende.sk in your browser"
    echo "  2. Log in with your Zendesk credentials"
    echo "  3. Look for your API token (starts with 'zdai_')"
    echo "  4. Copy the entire token"
    echo ""

    # Prompt for token
    read -p "Paste your AI Gateway token here: " AI_GATEWAY_TOKEN

    # Trim whitespace
    AI_GATEWAY_TOKEN=$(echo "$AI_GATEWAY_TOKEN" | xargs)

    # Validate token format
    if [[ ! "$AI_GATEWAY_TOKEN" =~ ^zdai_ ]]; then
        echo -e "${RED}✗ Token doesn't look right (should start with 'zdai_')${NC}"
        echo "  → Please get your token from https://ai-gateway.zende.sk"
        ALL_CHECKS_PASSED=false
    else
        echo -e "${YELLOW}  Testing token...${NC}"

        # Test token against AI Gateway (using bedrock endpoint)
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Authorization: Bearer $AI_GATEWAY_TOKEN" \
            https://ai-gateway.zende.sk/bedrock/v1/messages \
            -H "Content-Type: application/json" \
            -d '{"model":"claude-sonnet-4.5","max_tokens":1,"messages":[{"role":"user","content":"test"}]}')

        if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "400" ]]; then
            # 200 or 400 means auth worked (400 is expected with minimal request)
            echo -e "${GREEN}✓ AI Gateway token is valid${NC}"

            # Store token securely for install script
            echo "$AI_GATEWAY_TOKEN" > "$TOKEN_FILE"
            chmod 600 "$TOKEN_FILE"
        else
            echo -e "${RED}✗ AI Gateway token validation failed (HTTP $HTTP_CODE)${NC}"
            echo "  → Please check your token and try again"
            echo "  → Get a fresh token from https://ai-gateway.zende.sk"
            ALL_CHECKS_PASSED=false
        fi
    fi
fi
echo ""

# Final summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ "$ALL_CHECKS_PASSED" = true ]; then
    echo -e "${GREEN}✓ All checks passed! You're ready for installation.${NC}"
    echo ""
    echo "Next step: Run the install script"
    echo -e "  ${BLUE}bash install.sh${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some checks failed. Please fix the issues above.${NC}"
    echo ""
    echo "Once fixed, run preflight again:"
    echo -e "  ${BLUE}bash preflight.sh${NC}"
    echo ""
    exit 1
fi
