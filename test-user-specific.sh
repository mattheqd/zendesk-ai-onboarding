#!/bin/bash

# Test script to verify user-specific setup
# Run this in your test user account to verify the important bits

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}Testing User-Specific Setup${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: Claude Code config
echo -e "${YELLOW}1. Checking Claude Code configuration...${NC}"
if [ -f ~/.claude/settings.json ]; then
    echo -e "${GREEN}✓ Config file exists${NC}"

    # Check if it has the right structure
    if cat ~/.claude/settings.json | jq -e '.env.ANTHROPIC_AUTH_TOKEN' > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Token field present${NC}"

        # Check if token starts with zdai_
        TOKEN=$(cat ~/.claude/settings.json | jq -r '.env.ANTHROPIC_AUTH_TOKEN')
        if [[ "$TOKEN" =~ ^zdai_ ]]; then
            echo -e "${GREEN}✓ Token format valid${NC}"
        else
            echo -e "${RED}✗ Token doesn't start with zdai_${NC}"
        fi
    else
        echo -e "${RED}✗ Token field missing${NC}"
    fi

    # Check other required fields
    if cat ~/.claude/settings.json | jq -e '.env.CLAUDE_CODE_USE_BEDROCK' > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Bedrock config present${NC}"
    else
        echo -e "${RED}✗ Bedrock config missing${NC}"
    fi

    echo ""
    echo "Config contents:"
    cat ~/.claude/settings.json | jq .
else
    echo -e "${RED}✗ Config file not found at ~/.claude/settings.json${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 2: Shell profile updates
echo -e "${YELLOW}2. Checking shell profile updates...${NC}"

if grep -q "NODE_USE_SYSTEM_CA=1" ~/.zprofile 2>/dev/null; then
    echo -e "${GREEN}✓ NODE_USE_SYSTEM_CA in .zprofile${NC}"
else
    echo -e "${YELLOW}⚠ NODE_USE_SYSTEM_CA not in .zprofile${NC}"
fi

if grep -q "NODE_USE_SYSTEM_CA=1" ~/.bash_profile 2>/dev/null; then
    echo -e "${GREEN}✓ NODE_USE_SYSTEM_CA in .bash_profile${NC}"
else
    echo -e "${YELLOW}⚠ NODE_USE_SYSTEM_CA not in .bash_profile${NC}"
fi

if grep -q '.local/bin' ~/.zshrc 2>/dev/null; then
    echo -e "${GREEN}✓ PATH update in .zshrc${NC}"
else
    echo -e "${YELLOW}⚠ PATH update not in .zshrc (might not be needed if claude is in system PATH)${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 3: Claude Code binary
echo -e "${YELLOW}3. Checking Claude Code installation...${NC}"

if command -v claude &> /dev/null; then
    echo -e "${GREEN}✓ Claude command found in PATH${NC}"

    CLAUDE_PATH=$(which claude)
    echo "  Location: $CLAUDE_PATH"

    # Try to get version
    if claude --version &> /dev/null; then
        VERSION=$(claude --version 2>&1 || echo "unknown")
        echo -e "${GREEN}✓ Claude version: $VERSION${NC}"
    else
        echo -e "${YELLOW}⚠ Claude command exists but --version failed${NC}"
    fi
else
    echo -e "${RED}✗ Claude command not found in PATH${NC}"
    echo "  Current PATH: $PATH"

    # Check if it exists in common locations
    if [ -f ~/.local/bin/claude ]; then
        echo -e "${YELLOW}⚠ Found at ~/.local/bin/claude but not in PATH${NC}"
        echo "  → Try: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 4: AI Gateway connectivity (using config token)
echo -e "${YELLOW}4. Testing AI Gateway connection...${NC}"

if [ -f ~/.claude/settings.json ]; then
    TOKEN=$(cat ~/.claude/settings.json | jq -r '.env.ANTHROPIC_AUTH_TOKEN')

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $TOKEN" \
        https://ai-gateway.zende.sk/bedrock/v1/messages \
        -H "Content-Type: application/json" \
        -d '{"model":"claude-sonnet-4.5","max_tokens":1,"messages":[{"role":"user","content":"test"}]}' 2>/dev/null)

    if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "400" ]]; then
        echo -e "${GREEN}✓ Token works with AI Gateway (HTTP $HTTP_CODE)${NC}"
    else
        echo -e "${RED}✗ Token validation failed (HTTP $HTTP_CODE)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Skipped (no config file)${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 5: GitHub CLI authentication
echo -e "${YELLOW}5. Checking GitHub authentication...${NC}"

if command -v gh &> /dev/null; then
    if gh auth status &> /dev/null; then
        echo -e "${GREEN}✓ GitHub CLI authenticated${NC}"

        # Check org membership
        if gh api /user/orgs --jq '.[].login' 2>/dev/null | grep -q "^zendesk$"; then
            echo -e "${GREEN}✓ Member of zendesk org${NC}"
        else
            echo -e "${YELLOW}⚠ Not a member of zendesk org${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ GitHub CLI not authenticated${NC}"
    fi
else
    echo -e "${YELLOW}⚠ GitHub CLI not installed${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Summary
echo -e "${BLUE}${BOLD}Summary:${NC}"
echo ""
echo "User-specific setup checks complete."
echo ""
echo "Next: Try running Claude Code in a NEW terminal window:"
echo -e "  ${GREEN}claude${NC}"
echo ""
echo "If it doesn't work, check the failures above."
