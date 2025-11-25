#!/bin/bash

# CI/CD Pipeline Validation Script
# This script validates the syntax and structure of CI/CD pipeline files

set -e

echo "==================================="
echo "CI/CD Pipeline Validation"
echo "==================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track validation status
VALIDATION_PASSED=true

# Function to print success
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print error
print_error() {
    echo -e "${RED}✗${NC} $1"
    VALIDATION_PASSED=false
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "1. Checking for CI/CD configuration files..."
echo ""

# Check GitLab CI
if [ -f ".gitlab-ci.yml" ]; then
    print_success "GitLab CI configuration found (.gitlab-ci.yml)"
    
    # Basic YAML syntax check
    if command -v yamllint &> /dev/null; then
        if yamllint -d relaxed .gitlab-ci.yml &> /dev/null; then
            print_success "GitLab CI YAML syntax is valid"
        else
            print_error "GitLab CI YAML syntax has issues"
        fi
    else
        print_warning "yamllint not installed, skipping YAML validation"
    fi
    
    # Check for required stages
    if grep -q "stages:" .gitlab-ci.yml; then
        print_success "GitLab CI stages defined"
    else
        print_error "GitLab CI stages not found"
    fi
else
    print_warning "GitLab CI configuration not found"
fi

echo ""

# Check Jenkins
if [ -f "Jenkinsfile" ]; then
    print_success "Jenkins configuration found (Jenkinsfile)"
    
    # Check for pipeline structure
    if grep -q "pipeline {" Jenkinsfile; then
        print_success "Jenkins declarative pipeline structure found"
    else
        print_error "Jenkins pipeline structure not found"
    fi
    
    # Check for required stages
    if grep -q "stages {" Jenkinsfile; then
        print_success "Jenkins stages defined"
    else
        print_error "Jenkins stages not found"
    fi
else
    print_warning "Jenkins configuration not found"
fi

echo ""

# Check GitHub Actions
if [ -f ".github/workflows/ci-cd.yml" ]; then
    print_success "GitHub Actions configuration found (.github/workflows/ci-cd.yml)"
    
    # Basic YAML syntax check
    if command -v yamllint &> /dev/null; then
        if yamllint -d relaxed .github/workflows/ci-cd.yml &> /dev/null; then
            print_success "GitHub Actions YAML syntax is valid"
        else
            print_error "GitHub Actions YAML syntax has issues"
        fi
    else
        print_warning "yamllint not installed, skipping YAML validation"
    fi
    
    # Check for required jobs
    if grep -q "jobs:" .github/workflows/ci-cd.yml; then
        print_success "GitHub Actions jobs defined"
    else
        print_error "GitHub Actions jobs not found"
    fi
else
    print_warning "GitHub Actions configuration not found"
fi

echo ""
echo "2. Checking Maven configuration..."
echo ""

if [ -f "backend/pom.xml" ]; then
    print_success "Maven POM file found (backend/pom.xml)"
    
    # Check for JaCoCo plugin
    if grep -q "jacoco-maven-plugin" backend/pom.xml; then
        print_success "JaCoCo plugin configured for coverage reporting"
    else
        print_error "JaCoCo plugin not found in pom.xml"
    fi
    
    # Check for Surefire plugin
    if grep -q "maven-surefire-plugin" backend/pom.xml; then
        print_success "Surefire plugin configured for test execution"
    else
        print_error "Surefire plugin not found in pom.xml"
    fi
else
    print_error "Maven POM file not found"
fi

echo ""
echo "3. Checking Docker configuration..."
echo ""

# Check Dockerfiles
if [ -f "frontend/Dockerfile" ]; then
    print_success "Frontend Dockerfile found"
else
    print_error "Frontend Dockerfile not found"
fi

if [ -f "backend/Dockerfile" ]; then
    print_success "Backend Dockerfile found"
else
    print_error "Backend Dockerfile not found"
fi

if [ -f "docker-compose.yml" ]; then
    print_success "Docker Compose file found"
else
    print_error "Docker Compose file not found"
fi

echo ""
echo "4. Checking documentation..."
echo ""

if [ -f "docs/CI_CD_SETUP.md" ]; then
    print_success "CI/CD setup documentation found"
else
    print_warning "CI/CD setup documentation not found"
fi

if [ -f "CI_CD_README.md" ]; then
    print_success "CI/CD README found"
else
    print_warning "CI/CD README not found"
fi

echo ""
echo "==================================="
if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "${GREEN}All validations passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Choose your CI/CD platform (GitLab CI, Jenkins, or GitHub Actions)"
    echo "2. Configure required credentials and variables"
    echo "3. Push the configuration files to your repository"
    echo "4. Monitor the first pipeline run"
    exit 0
else
    echo -e "${RED}Some validations failed!${NC}"
    echo ""
    echo "Please fix the issues above before proceeding."
    exit 1
fi
