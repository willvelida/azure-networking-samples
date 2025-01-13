@description('The name of the virtual network')
param vnetName string

@description('The region where our virtual network will be deployed. Default is resource group location')
param location string = resourceGroup().location

@description('The tags that will be applied to the virtual network resource')
param tags object = {}

var subnet1Name = 'GatewaySubnet'
var subnet2Name = 'DatabaseSubnet'
var subnet3Name = 'CoreServicesSubnet'

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: subnet3Name
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }

  resource subnet1 'subnets' existing = {
    name: subnet1Name
  }

  resource subnet2 'subnets' existing = {
    name: subnet2Name
  }

  resource subnet3 'subnets' existing = {
    name: subnet3Name
  }
}

@description('The resource ID of subnet 1')
output subnet1Id string = vnet::subnet1.id

@description('The resource ID of subnet 2')
output subnet2Id string = vnet::subnet2.id

@description('The resource ID of subnet 3')
output subnet3Id string = vnet::subnet3.id
