# Onboarding script

Bash script to create App registration with federated credential that establishes trust with ***Softip-CES/TF-AZ-CentralLog*** GitHub repository main branch. Assigns RBAC roles for service principal - Contributor and User Access Administrator - for provided scope. 


## Prerequisites

We recommend running this script directly in portal UI, where you are automatically logged in with ***az cli***. Person running this script need to have required RBAC on the scope of subscription or resource group (Owner, User Access Administrator). These roles are nessesary to assign roles to the service principal that is created.

## Running script
Open cloud shell and run following commands:


```bash
git clone https://github.com/Softip-CES/SH-AZ-Onboarding.git # cloning this repository
```
```bash
cd SH-AZ-Onboarding # change directory to cloned repository
```
```bash
chmod u+x onboarding.sh # adding execute permission for the user
```
```bash
./onboarding.sh -n {app_name} -s {scope} # executing script with provided values
```
***app_name*** - is the name of Application that will be created in Azure AD. Service principal will be created with the same name. \
***scope*** -  is the scope for creating role assignment (either on already existing subscription or resource group) in the form:

- /subscriptions/{subscriptionId} 
  
  OR

- /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName} 

 ***If scoped on resource group***, please make sure that these resource providers are already registered on subscription: 
 - Microsoft.KeyVault
 - Microsoft.EventHub
 - Microsoft.OperationalInsights
 - Microsoft.Web
 - microsoft.insights