param location string = resourceGroup().location

// VNET 1 RESOURCES
param primaryVnetName string = 'vnet-prod-ae-wv-001'
param primaryVnetAddressPrefix string = '10.30.0.0/16'
param primarySubnetName string = 'PrimarySubnet'
param primarySubnetPrefix string = '10.30.10.0/24'
param primaryVMName string = 'vmprodaewv001'
param primaryNicName string = 'nic-prod-ae-wv-001'
param primaryNsgName string = 'nsg-prod-ae-wv-001'

// VNET 2 Resources
param secondaryVnetName string = 'vnet-prod-ae-wv-002'
param secondaryVnetAddressPrefix string = '10.20.0.0/16'
param secondarySubnetName string = 'SecondarySubnet'
param secondarySubnetPrefix string = '10.20.20.0/24'
param secondaryVMName string = 'vmprodasewv001'
param secondaryNicName string = 'nic-prod-ae-wv-002'

var vmSize = 'Standard_DS1_v2'
var publicIpName = 'pip-prod-ae-wv-001'
var adminUsername = ''
var adminPassword = ''

resource primaryVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: primaryVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        primaryVnetAddressPrefix
      ]
    }
    subnets: [
      { 
        name: primarySubnetName
        properties: {
          addressPrefix: primarySubnetPrefix
        }
      }
    ]
  }

  resource primarySubnet 'subnets' existing = {
    name: primarySubnetName
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIpName
  location: location
  sku: {
      name: 'Standard'
  } 
  properties: {
      publicIPAllocationMethod: 'Static'
  }
}

resource primaryNic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: primaryNicName
  location: location
  properties: {
      ipConfigurations: [
          {
              name: 'ipconfig1'
              properties: {
                  subnet: {
                      id: primaryVnet.properties.subnets[0].id
                  }
                  privateIPAllocationMethod: 'Dynamic'
                  publicIPAddress: {
                    id: publicIP.id
                  }
              }
          }
      ]
      networkSecurityGroup: {
        id: nsg.id
      }
  }
}

resource primaryVM 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: primaryVMName
  location: location
  properties: {
      hardwareProfile: {
          vmSize: vmSize
      }
      osProfile: {
          computerName: primaryVMName
          adminUsername: adminUsername
          adminPassword: adminPassword
      }
      networkProfile: {
          networkInterfaces: [
              {
                  id: primaryNic.id
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

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: primaryNsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-rdp'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource peerToSecondary 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  name: 'peer-to-secondary'
  parent: primaryVnet
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: secondaryVnet.id
    }
  }
  dependsOn: [
    primaryVM
  ]
}

// SECONDARY VNET RESOURCES
resource secondaryVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: secondaryVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        secondaryVnetAddressPrefix
      ]
    }
    subnets: [
      { 
        name: secondarySubnetName
        properties: {
          addressPrefix: secondarySubnetPrefix
        }
      }
    ]
  }

  resource secondarySubnet 'subnets' existing = {
    name: secondarySubnetName
  }
}

resource secondaryNic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: secondaryNicName
  location: location
  properties: {
      ipConfigurations: [
          {
              name: 'ipconfig1'
              properties: {
                  subnet: {
                      id: secondaryVnet.properties.subnets[0].id
                  }
                  privateIPAllocationMethod: 'Dynamic'
              }
          }
      ]
  }
}

resource secondaryVM 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: secondaryVMName
  location: location
  properties: {
      hardwareProfile: {
          vmSize: vmSize
      }
      osProfile: {
          computerName: secondaryVMName
          adminUsername: adminUsername
          adminPassword: adminPassword
      }
      networkProfile: {
          networkInterfaces: [
              {
                  id: secondaryNic.id
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

resource peerToPrimary 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  name: 'peer-to-primary'
  parent: secondaryVnet
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: primaryVnet.id
    }
  }
  dependsOn: [
    primaryVM
  ]
}
