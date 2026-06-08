#!/bin/bash

# Test harness for onboarding scripts
# Creates a sandboxed environment to test without affecting your system

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Onboarding Script Test Environment${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Create a test directory structure
TEST_DIR="$HOME/.zendesk_onboarding_test"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo -e "${YELLOW}Setting up test environment in $TEST_DIR${NC}"
echo ""

# Create mock scripts that simulate different scenarios
cat > test-preflight-vpn-fail.sh << 'EOF'
#!/bin/bash
# Test: VPN disconnected scenario
alias ping='false'
export -f ping
bash ../preflight.sh
EOF

cat > test-preflight-no-gh.sh << 'EOF'
#!/bin/bash
# Test: GitHub CLI missing scenario
PATH="/usr/bin:/bin"
bash ../preflight.sh
EOF

cat > test-preflight-success.sh << 'EOF'
#!/bin/bash
# Test: All checks pass (you'll need to provide real token)
bash ../preflight.sh
EOF

chmod +x test-*.sh

echo -e "${GREEN}✓ Test scripts created in $TEST_DIR${NC}"
echo ""
echo "Available tests:"
echo ""
echo "1. Test VPN failure:"
echo -e "   ${BLUE}cd $TEST_DIR && ./test-preflight-vpn-fail.sh${NC}"
echo ""
echo "2. Test missing GitHub CLI:"
echo -e "   ${BLUE}cd $TEST_DIR && ./test-preflight-no-gh.sh${NC}"
echo ""
echo "3. Test successful preflight:"
echo -e "   ${BLUE}cd $TEST_DIR && ./test-preflight-success.sh${NC}"
echo ""
echo "4. Manual testing with modified PATH:"
echo -e "   ${BLUE}PATH=/usr/bin:/bin bash preflight.sh${NC}"
echo ""
echo "5. Dry-run install (see what would happen):"
echo -e "   ${BLUE}DRY_RUN=1 bash install.sh${NC}"
echo ""
echo "6. Clean up test environment:"
echo -e "   ${BLUE}rm -rf $TEST_DIR${NC}"
echo ""
