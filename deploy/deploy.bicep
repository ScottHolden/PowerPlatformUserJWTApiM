param prefix string = 'Demo-JWTApi'
param location string = resourceGroup().location
@description('This is the audience URI of the application that this API represents, typically this would be: api://<clientId>/')
param audienceUri string
@description('This is the Tenant ID (guid or FQDN format) where the Application Registration above lives')
param tenantID string
param email string = 'noreply@microsoft.com'


var uniqueName = '${prefix}-${uniqueString(prefix, resourceGroup().id)}'

var apiName = 'DemoJWTApi'
var apiPolicyXml = replace(replace(loadTextContent('policies/api-DemoJWTApi.xml'), '{{TenantID}}', tenantID), '{{AudienceUri}}', audienceUri)

var operationName = 'ReflectJWTDetails'
var operationPath = '/reflect'
var operationPolicyXml = loadTextContent('policies/operation-ReflectJWTDetails.xml')

var schemaName = 'JWTDetails'
var schema = {
  type: 'object'
  properties: {
    user: {
      type: 'string'
    }
    details: {
      type: 'object'
    }
  }
}


resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: uniqueName
  location: location
  properties: {}
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: uniqueName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

resource apim 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: uniqueName
  location: location
  sku: {
    capacity: 0
    name: 'Consumption'
  }
  properties: {
    publisherEmail: email
    publisherName: prefix
  }
  resource appInsightsLogger 'loggers@2022-04-01-preview' = {
    name: appInsights.name
    properties: {
      loggerType: 'applicationInsights'
      resourceId: appInsights.id
      credentials: {
        instrumentationKey: appInsights.properties.InstrumentationKey
      }
    }
  }
  resource diagnostics 'diagnostics@2022-04-01-preview' = {
    name: 'applicationinsights'
    properties: {
      alwaysLog: 'allErrors'
      loggerId: appInsightsLogger.id
      sampling: {
        percentage: 100
        samplingType: 'fixed'
      }
    }
  }
  resource api 'apis@2021-08-01' = {
    name: apiName
    properties: {
      displayName: apiName
      protocols: [
        'https'
      ]
      path: apiName
      subscriptionRequired: false
    }
    resource apiPolicy 'policies@2022-04-01-preview' = {
      name: 'policy'
      properties: {
        format: 'rawxml'
        value: apiPolicyXml
      }
    }
    resource reflectSchema 'schemas@2021-08-01' = {
      name: uniqueString(schemaName)
      properties: {
        contentType: 'application/vnd.oai.openapi.components+json'
        document: {
          components: {
            schemas: {
              '${schemaName}': schema
            }
          }
        }
      }
    }
    resource reflectOperation 'operations@2021-08-01' = {
      name: operationName
      properties: {
        displayName: operationName
        method: 'get'
        urlTemplate: operationPath
        responses: [
          {
            statusCode: 200
            description: operationName
            representations: [
              {
                contentType: 'application/json'
                schemaId: uniqueString(schemaName)
                typeName: schemaName
              }
            ]
          }
        ]
      }
      dependsOn: [
        reflectSchema
      ]
      resource policy 'policies@2021-08-01' = {
        name: 'policy'
        properties: {
          format: 'rawxml'
          value: operationPolicyXml
        }
      }
    }
  }
}
