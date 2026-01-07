#!/bin/bash
# Azure Virtual Desktop Demo - Deployment Script
# Bash Version

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parameters
PARAMETERS_FILE="${1:-../parameters/avd-demo.parameters.json}"
LOCATION="${2:-westeurope}"

echo -e "${CYAN}🚀 Azure Virtual Desktop Demo - Deployment${NC}"
echo -e "${CYAN}===========================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI not found${NC}"
    echo -e "${YELLOW}Install from: https://docs.microsoft.com/cli/azure/install-azure-cli${NC}"
    exit 1
fi

# Check Azure login
echo -e "${YELLOW}🔐 Checking Azure login...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ Not logged in. Running az login...${NC}"
    az login
fi

ACCOUNT=$(az account show --query user.name -o tsv)
SUBSCRIPTION=$(az account show --query name -o tsv)

echo -e "${GREEN}✅ Logged in as: ${ACCOUNT}${NC}"
echo -e "${CYAN}📋 Subscription: ${SUBSCRIPTION}${NC}"
echo ""

# Confirm deployment
read -p "Deploy to this subscription? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled${NC}"
    exit 0
fi

# Check for existing resource group
RG_NAME="rg-avd-demo"
if az group show --name $RG_NAME &> /dev/null; then
    echo -e "${YELLOW}⚠️  Resource group '$RG_NAME' already exists${NC}"
    read -p "Delete and redeploy? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🗑️  Deleting resource group...${NC}"
        az group delete --name $RG_NAME --yes --no-wait
        echo -e "${YELLOW}⏳ Waiting 30 seconds...${NC}"
        sleep 30
    else
        echo -e "${RED}❌ Deployment cancelled${NC}"
        exit 1
    fi
fi

# Validate template
echo -e "${YELLOW}🔍 Validating Bicep template...${NC}"
DEPLOYMENT_NAME="avd-demo-$(date +%Y%m%d-%H%M%S)"

if az deployment sub validate \
    --location $LOCATION \
    --template-file ../bicep/main.bicep \
    --parameters @$PARAMETERS_FILE \
    --query 'properties.provisioningState' -o tsv &> /dev/null; then
    echo -e "${GREEN}✅ Template validation successful${NC}"
else
    echo -e "${RED}❌ Template validation failed${NC}"
    exit 1
fi

# Deploy
echo ""
echo -e "${CYAN}🚀 Starting deployment...${NC}"
echo -e "${YELLOW}⏱️  This will take 10-15 minutes. Please wait...${NC}"
echo ""

if az deployment sub create \
    --location $LOCATION \
    --template-file ../bicep/main.bicep \
    --parameters @$PARAMETERS_FILE \
    --name $DEPLOYMENT_NAME; then
    
    echo ""
    echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
    echo ""
    
    # Get outputs
    echo -e "${CYAN}📊 Outputs:${NC}"
    az deployment sub show --name $DEPLOYMENT_NAME --query 'properties.outputs' -o table
    
else
    echo ""
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
fi

# Post-deployment instructions
echo ""
echo -e "${CYAN}🎯 Next Steps:${NC}"
echo ""
echo -e "${NC}1️⃣  Wait 5-10 minutes for session hosts to become 'Available'${NC}"
echo ""
echo -e "${NC}2️⃣  Assign users to the application group:${NC}"
echo -e "${YELLOW}   APP_GROUP_ID=\$(az desktopvirtualization applicationgroup show --name avddemo-dag --resource-group rg-avd-demo --query id -o tsv)${NC}"
echo -e "${YELLOW}   az role assignment create --assignee user@domain.com --role 'Desktop Virtualization User' --scope \$APP_GROUP_ID${NC}"
echo ""
echo -e "${NC}3️⃣  Assign VM login permissions:${NC}"
echo -e "${YELLOW}   VM_ID=\$(az vm show --resource-group rg-avd-demo --name avddemo-sh-0 --query id -o tsv)${NC}"
echo -e "${YELLOW}   az role assignment create --assignee user@domain.com --role 'Virtual Machine User Login' --scope \$VM_ID${NC}"
echo ""
echo -e "${NC}4️⃣  Connect at: https://client.wvd.microsoft.com${NC}"
echo ""
echo -e "${CYAN}📝 For detailed instructions, see docs/DEPLOYMENT-GUIDE.md${NC}"
echo ""
