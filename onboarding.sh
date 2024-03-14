#!/bin/bash

# Get input parametes based on flags
while getopts "n:s:" flag; do
    case "${flag}" in
        n) app_name=${OPTARG};;
        s) scope=${OPTARG};;
    esac
done

# Check if required options are missing
if [ -z "$app_name" ] || [ -z "$scope" ]; then
    echo "Error: Both -n (app_name) and -s (scope) options are required."
    exit 1
fi

# Regex patterns for subscription and resource group
pattern_sub="/subscriptions/[a-fA-F0-9-]+$"  # hex string with dashes
pattern_rg="/subscriptions/[a-fA-F0-9-]+/resourceGroups/[a-zA-Z0-9_.()-]+[^/.]$" # Resource group names can only include alphanumeric, underscore, parentheses, hyphen, period (except at end), and Unicode characters that match the allowed characters.

# Validate right format for scope
if [[  $scope =~ $pattern_sub ||  $scope =~ $pattern_rg ]]; then
    IFS='/' read -ra parts <<< "$scope"
    sub_capture="${parts[2]}" # capture subscription id
    rg_capture="${parts[4]:-NoResourceGroup}" # if resource group is not provided, set it to "NoResourceGroup"
else
    echo "Invalid format: $scope, input is expected in form of /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName} or /subscriptions/{subscriptionId}"
    exit 1
fi

# Error handling and information messages
info() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
    else
        echo "$2"
    fi
}

# Create app, capture output
az_create_app_out=$(az ad app create --display-name $app_name)
info "Error: Failed to create Azure AD app." "Azure AD app created successfully."

# Get app id and tenant id from output
appId=$(echo "$az_create_app_out" | jq -r '.appId')

tenantId=$(az account show | jq -r '.tenantId')

# Create service principal with associated application and get objectId
objectId=$(az ad sp create --id $appId | jq -r '.id')
info "Error: Failed to create Service principal for AD app." "Azure Service principal created successfully."

# Create federated credential for appplication
az ad app federated-credential create --id $appId \
    --parameters '{"name": "gh-token-softip-ces-tf-az-centrallog","issuer": "https://token.actions.githubusercontent.com/","subject": "repo:Softip-CES/TF-AZ-CentralLog:ref:refs/heads/main","description": "Federated credential for Softip-CES/TF-AZ-CentralLog repository","audiences": ["api://AzureADTokenExchange"]}' > /dev/null 2>&1
info "Error: Failed to create Federated credential for Application: $appId" "Federated credential for Application: $appId created successfully."

# Create role assignment "Contributor" for specified scope
az role assignment create --assignee $objectId \
    --role "Contributor" \
    --scope $scope > /dev/null 2>&1
info "Error: Failed to create role assignemnt at a $scope." "Role assignment Contributor created at $scope."

# Create role assignment "User Access Administrator" for specified scope
az role assignment create --assignee $objectId \
    --role "User Access Administrator" \
    --scope $scope > /dev/null 2>&1
info "Error: Failed to create role assignemnt at a $scope." "Role assignment User Access Administrator created at $scope."

# Output app id, tenant id and objectId
echo -e "\n\n\nCopy this and send it to the responsible person\n"
echo "###################################################"
echo "client_id: $appId"
echo "tenant_id: $tenantId"
echo "subscription_id: $sub_capture"
echo "resourceGroup: $rg_capture"
echo "###################################################"
echo -e "\nCopy this and send it to the responsible person.\n\n\n"
