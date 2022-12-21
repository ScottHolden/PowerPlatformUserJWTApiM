# Power Platform Per User (On-Behalf-Of) OAuth with API-M JWT validation

[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FScottHolden%2FPowerPlatformUserJWTApiM%2Fmaster%2Fdeploy.generated.json)

## Overview

This is a small demo to show how per-user connections can be established on Custom Connectors within Power Platform.

_Note: This demo is designed to allow API-M to be deployed in a completely different AAD tenant to your Power Platform enviroment if required._  

## Setup Instructions _(__Note: these are still in-review!__)_

### 1. Create a [new application registration](https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/CreateApplicationBlade/quickStartType~/null/isMSAApp~/false) within the tenant that your Power Platform enviroment is connected to with the following configuration. This application will be used for our API (for validation within API-M):  
- Single-tenant (this organization directory only)  
- Set an Application ID URI (in the 'Expose an API' tab)  
- Add a scope (eg: `Api.Access`), allow both users and admins to concent, and enable it  
- Make note of the following items: __Tenant ID__ (found in 'Overview'), __Application ID URI__ (found in 'Expose an API'), __Scope Name__ (found in 'Expose an API', you created this in point 3)  

### 2. [Deploy the template](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FScottHolden%2FPowerPlatformUserJWTApiM%2Fmaster%2Fdeploy.generated.json) above, filling in the following parameters (_This can be deployed in any Azure Subscription, it does __not__ need to be in the same tenant_):  
- __audienceUri__: set this to the __Application ID URI__ noted in step 1  
- __tenantID__: set this to the __Tenant ID__ noted in step 1  

### 3. Create another [new application registration](https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/CreateApplicationBlade/quickStartType~/null/isMSAApp~/false) within the same tenant as step 1. This application will be used for the Custom Connector:  
- Single-tenant (this organization directory only)  
- Add an API permission, __delegated__, pointing to the Application and Scope set above.  
- Add a Client secret (_copy the value before navigating away!_)  
- Make note of the following items: __Tenant ID__ (found in 'Overview'), __Client ID__ (found in 'Overview'), __Client Secret__ (only visible when you create the secret)

### 4. Export the OpenAPI 2.0 Spec from API-M  
- Navigate to the API Managment resource that was deployed in step 2  
- Open the 'APIs' blade, then click the 3 dots (...) next to 'DemoJWTApi' and click 'Export'  
- From the export screen select 'OpenAPI v2 (JSON)' and take note of where the file is downloaded to  

### 5. Create the Custom Connector within Power Platform  
- Open [make.powerapps.com](https://make.powerapps.com) and under 'Dataverse' select 'Custom Connectors' (If this is your first time using Dataverse in this environment you will need to create a database and wait for it to complete)  
- Click the '+ New custom connector' option in the top right, and select 'Import an OpenAPI file'  
- Give the connector a name (eg: `DemoJWTApi`) and import the file downloaded in step 4  
- Naviagte to the '2. Security' tab at the top, set 'Authentication Type' to 'OAuth 2.0' and fill in the following parameters:  
  - __Identity Provider__: set this to 'Azure Active Directory'
  - __Client ID__: set this to the __Client ID__ noted in __step 3__
  - __Client Secret__: set this to the __Client Secret__ noted in __step 3__
  - __Tenant ID__: set this to the __Tenant ID__ noted in __step 3__
  - __Resource URL__: set this to the __Application ID URI__ noted in __step 1__
  - __Enable on-behalf-of login__: set this to 'true'
  - __Scope__: set this to the __Scope Name__ noted in __step 1__  
- Once you are done select 'Create Connector' in the top left
- Navigate back into the custom connector you just created once the operation is complete
- Make note of the following items: __Redirect URL__ (found within the '2. Security' tab once the connector has been created)

### 6. Update the Custom Connector App Registration
- Open the Application Registration you created in __step 3__
- Navigate to the 'Authentication' tab and select 'Add a platform'
- Select 'Web', enter the __Redirect URL__ you noted in __step 5__, and click 'Configure'

### 7. Create a Connection
- Create a Connection within Power Platform via any of the following methods:
  - Navigate to the '5. Test' tab within the Custom Connector screen and select 'New Connection' __OR__
  - Click the '+' button next to the connector you created within the 'Custom Connectors' list __OR__
  - Nativate to 'Connections', click '+ New connection', and find your connector within the list (normally at the bottom)
- Click the create button and login

### 8. Test the connection
- Navigate to 'Custom Connectors' and edit the custom connector you created in __step 5__ (pencil icon next to the connector)
- Navigate to the '5. Test' tab within the custom connector
- Select the connection you created in __step 7__, and click 'Test operation'. (_If you haven't tested within the past few minutes it may take a few seconds to show as API-M is deployed in Consumption mode_)
- The 'Body' section under the 'Response' tab will show you what infomration was within the JWT that API-M validated.

### 9. _Optional_ Extras
- Add an 'App Role' within the API application (step 1), and assign a user to the role via the 'Enterprise Application', this will show as a 'Roles' claim on the JWT
- Add additional claims validation to the API policy beyond audience (this could include issuer, or even claims such as role)

### 10. _Optional_ Clean-up
- Delete the custom connector and any connections within your Power Platform enviroment
- Delete the Azure resources deployed (API-M, Application Insights, Log Analytics Workspace)
- Delete the 2 Application Registrations created in __step 1__ and __step 3__

## Debugging

An application insights resource is deployed alongside API-M, this will allow you to view logs for API requests.
