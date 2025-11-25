#!/bin/bash

# Secret Scanner Script
# Scans the codebase for hardcoded secrets and credentials
# Usage: ./scripts/scan-secrets.sh

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Secret Scanner for E-commerce System${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Initialize counters
TOTAL_ISSUES=0
CRITICAL_ISSUES=0
WARNING_ISSUES=0

# Define patterns to search for
declare -a PATTERNS=(
    "password"
    "passwd"
    "pwd"
    "secret"
    "api_key"
    "apikey"
    "api-key"
    "token"
    "credential"
    "auth"
    "private_key"
    "privatekey"
    "access_key"
    "accesskey"
    "secret_key"
    "secretkey"
    "aws_access_key_id"
    "aws_secret_access_key"
    "bearer"
    "authorization"
)

# Define file extensions to scan
declare -a EXTENSIONS=(
    "*.java"
    "*.yml"
    "*.yaml"
    "*.properties"
    "*.xml"
    "*.json"
    "*.js"
    "*.ts"
    "*.sh"
    "*.py"
    "*.rb"
    "*.go"
    "Dockerfile*"
    "docker-compose*.yml"
)

# Define directories to exclude
EXCLUDE_DIRS=(
    "node_modules"
    "target"
    ".git"
    ".idea"
    ".vscode"
    "build"
    "dist"
    "coverage"
)

# Build find command with exclusions
FIND_CMD="find . -type f \("
for ext in "${EXTENSIONS[@]}"; do
    FIND_CMD="$FIND_CMD -name \"$ext\" -o"
done
FIND_CMD="${FIND_CMD% -o} \)"

for dir in "${EXCLUDE_DIRS[@]}"; do
    FIND_CMD="$FIND_CMD -not -path \"*/$dir/*\""
done

echo -e "${BLUE}Step 1: Scanning for hardcoded secrets...${NC}"
echo ""

# Get list of files to scan
FILES_TO_SCAN=$(eval $FIND_CMD)

if [ -z "$FILES_TO_SCAN" ]; then
    echo -e "${YELLOW}No files found to scan.${NC}"
    exit 0
fi

# Scan for each pattern
for pattern in "${PATTERNS[@]}"; do
    echo -e "Checking for pattern: ${YELLOW}$pattern${NC}"
    
    # Search for pattern (case insensitive)
    RESULTS=$(echo "$FILES_TO_SCAN" | xargs grep -i -n -H "$pattern" 2>/dev/null || true)
    
    if [ ! -z "$RESULTS" ]; then
        # Filter out acceptable uses
        # Acceptable: environment variables (${VAR}), comments (#, //, <!--), documentation
        FILTERED=$(echo "$RESULTS" | \
            grep -v "\${" | \
            grep -v "^\s*#" | \
            grep -v "^\s*//" | \
            grep -v "<!--" | \
            grep -v "\.md:" | \
            grep -v "CONTRIBUTING.md" | \
            grep -v "SECURITY_AUDIT.md" | \
            grep -v "\.example" | \
            grep -v "scan-secrets.sh" || true)
        
        if [ ! -z "$FILTERED" ]; then
            # Check if it's in docker-compose.yml or application.yml (known issues)
            CRITICAL=$(echo "$FILTERED" | grep -E "docker-compose\.yml|application\.yml" || true)
            
            if [ ! -z "$CRITICAL" ]; then
                echo -e "${RED}  ⚠️  CRITICAL: Hardcoded secrets found:${NC}"
                echo "$CRITICAL" | while IFS= read -r line; do
                    echo -e "    ${RED}$line${NC}"
                    ((CRITICAL_ISSUES++))
                    ((TOTAL_ISSUES++))
                done
            fi
            
            # Check for other files
            OTHER=$(echo "$FILTERED" | grep -v -E "docker-compose\.yml|application\.yml" || true)
            if [ ! -z "$OTHER" ]; then
                echo -e "${YELLOW}  ⚠️  WARNING: Potential secrets found:${NC}"
                echo "$OTHER" | while IFS= read -r line; do
                    echo -e "    ${YELLOW}$line${NC}"
                    ((WARNING_ISSUES++))
                    ((TOTAL_ISSUES++))
                done
            fi
        fi
    fi
done

echo ""
echo -e "${BLUE}Step 2: Checking for secret files...${NC}"
echo ""

# Define secret file patterns
declare -a SECRET_FILES=(
    ".env"
    ".env.local"
    ".env.production"
    ".env.staging"
    "credentials.json"
    "secrets.yml"
    "secrets.yaml"
    "private_key.pem"
    "id_rsa"
    "id_dsa"
    "*.key"
    "*.pem"
    "*.p12"
    "*.pfx"
)

FOUND_SECRET_FILES=0

for file_pattern in "${SECRET_FILES[@]}"; do
    FILES=$(find . -name "$file_pattern" \
        -not -path "*/node_modules/*" \
        -not -path "*/.git/*" \
        -not -path "*/target/*" \
        -not -name "*.example" \
        2>/dev/null || true)
    
    if [ ! -z "$FILES" ]; then
        echo -e "${RED}⚠️  Found potential secret file:${NC}"
        echo "$FILES" | while IFS= read -r file; do
            echo -e "  ${RED}$file${NC}"
            ((FOUND_SECRET_FILES++))
            ((TOTAL_ISSUES++))
        done
    fi
done

if [ $FOUND_SECRET_FILES -eq 0 ]; then
    echo -e "${GREEN}✅ No secret files found in repository.${NC}"
fi

echo ""
echo -e "${BLUE}Step 3: Checking .gitignore configuration...${NC}"
echo ""

# Check if .gitignore exists and contains necessary entries
if [ -f ".gitignore" ]; then
    GITIGNORE_OK=true
    
    # Check for .env
    if ! grep -q "^\.env$" .gitignore; then
        echo -e "${YELLOW}⚠️  .gitignore missing: .env${NC}"
        GITIGNORE_OK=false
    fi
    
    # Check for credentials/
    if ! grep -q "credentials/" .gitignore; then
        echo -e "${YELLOW}⚠️  .gitignore missing: credentials/${NC}"
        GITIGNORE_OK=false
    fi
    
    # Check for keys/
    if ! grep -q "keys/" .gitignore; then
        echo -e "${YELLOW}⚠️  .gitignore missing: keys/${NC}"
        GITIGNORE_OK=false
    fi
    
    # Check for secrets/
    if ! grep -q "secrets/" .gitignore; then
        echo -e "${YELLOW}⚠️  .gitignore missing: secrets/${NC}"
        GITIGNORE_OK=false
    fi
    
    if [ "$GITIGNORE_OK" = true ]; then
        echo -e "${GREEN}✅ .gitignore properly configured.${NC}"
    fi
else
    echo -e "${RED}❌ .gitignore file not found!${NC}"
    ((TOTAL_ISSUES++))
fi

echo ""
echo -e "${BLUE}Step 4: Checking for .env.example...${NC}"
echo ""

if [ -f ".env.example" ]; then
    echo -e "${GREEN}✅ .env.example file exists.${NC}"
else
    echo -e "${YELLOW}⚠️  .env.example file not found. Consider creating one.${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Scan Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ $TOTAL_ISSUES -eq 0 ]; then
    echo -e "${GREEN}✅ SUCCESS: No security issues found!${NC}"
    echo ""
    echo -e "Your codebase appears to be free of hardcoded secrets."
    exit 0
else
    echo -e "${RED}❌ ISSUES FOUND: $TOTAL_ISSUES total issues${NC}"
    echo -e "  ${RED}Critical: $CRITICAL_ISSUES${NC}"
    echo -e "  ${YELLOW}Warnings: $WARNING_ISSUES${NC}"
    echo ""
    echo -e "${YELLOW}Recommendations:${NC}"
    echo -e "  1. Move hardcoded secrets to environment variables"
    echo -e "  2. Use .env files for local development (ensure they're gitignored)"
    echo -e "  3. Use Docker secrets or external secrets management for production"
    echo -e "  4. Review SECURITY_AUDIT.md for detailed recommendations"
    echo ""
    
    if [ $CRITICAL_ISSUES -gt 0 ]; then
        echo -e "${RED}⚠️  CRITICAL issues must be resolved before production deployment!${NC}"
        exit 1
    else
        echo -e "${YELLOW}⚠️  Review warnings and address as needed.${NC}"
        exit 0
    fi
fi
