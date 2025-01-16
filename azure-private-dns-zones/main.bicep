param domain string = 'private.<your-domain>'
param location string = resourceGroup().location
param vnetName string = 'vnet-prod-ae-wv-001'
param vnetLinkName string = 'myVNetLink'
param subnetName string = 'mySubnet'
param vmName string = 'vmprodaewv001'
param adminUsername string = ''
param adminPassword string = ''
var nsgName = 'nsg-prod-ae-wv-001'
var nicName = 'nic-prod-ae-wv-001'
var vmSize = 'Standard_DS1_v2'

resource dnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: domain
  location: 'global'
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
    subnets: [
      { 
        name: subnetName
        properties: {
          addressPrefix: '10.2.0.0/24'
        }
      }
    ]
  }

  resource subnet 'subnets' existing = {
    name: subnetName
  }
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: vnetLinkName
  parent: dnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: true
  }
}

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowRDP'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: nicName
  location: location
  properties: {
      ipConfigurations: [
          {
              name: 'ipconfig1'
              properties: {
                  subnet: {
                      id: virtualNetwork.properties.subnets[0].id
                  }
                  privateIPAllocationMethod: 'Dynamic'
              }
          }
      ]
      networkSecurityGroup: {
        id: nsg.id
      }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: location
  properties: {
      hardwareProfile: {
          vmSize: vmSize
      }
      osProfile: {
          computerName: vmName
          adminUsername: adminUsername
          adminPassword: adminPassword
      }
      networkProfile: {
          networkInterfaces: [
              {
                  id: nic.id
              }
          ]
      }
      storageProfile: {
          imageReference: {
              publisher: 'MicrosoftWindowsServer'
              offer: 'WindowsServer'
              sku: '2019-Datacenter'
              version: 'latest'
          }
          osDisk: {
              createOption: 'FromImage'
          }
      }
  }
}
