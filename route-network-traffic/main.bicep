param location string = resourceGroup().location
param vnetName string = 'vnet-prod-ae-wv-001'
param bastionHostName string = 'bastion-prod-ae-wv-001'
param bastionIpName string = 'pipbastion-prod-ae-wv-001'
param nvaVmName string = 'nvavmprodaewv001'
param nvaNicName string = 'nicnva-prod-ae-wv-001'
param nvaNsgName string = 'nvansg-prod-ae-wv-001'
param publicVMName string = 'pubvmprodaewv001'
param publicVMNicName string = 'nicpub-prod-ae-wv-001'
param privateVMName string = 'privmprodaewv001'
param privateVMNicName string = 'nicpri-prod-ae-wv-001'
param routeTableName string = 'routetable-prod-ae-wv-001'

var bastionSubnetName = 'AzureBastionSubnet'
var bastionSubnetPrefix = '10.0.1.0/24'
var publicVmSubnetName = 'PublicVMSubnet'
var publicVmSubnetPrefix = '10.0.0.0/24'
var privateVmSubnetName = 'PrivateVMSubnet'
var privateVmSubnetPrefix = '10.0.2.0/24'
var dmzSubnetName = 'DMZSubnet'
var dmzSubnetPrefix = '10.0.3.0/24'
var adminUsername = ''
var adminPassword = ''
var vmSize = 'Standard_DS1_v2'

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: publicVmSubnetName
        properties: {
          addressPrefix: publicVmSubnetPrefix
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetPrefix
        }
      }
      {
        name: privateVmSubnetName
        properties: {
          addressPrefix: privateVmSubnetPrefix
        }
      }
      {
        name: dmzSubnetName
        properties: {
          addressPrefix: dmzSubnetPrefix
        }
      }
    ]
  }

  resource publicSubnet 'subnets' existing = {
    name: publicVmSubnetName
  }

  resource bastionSubnet 'subnets' existing = {
    name: bastionSubnetName
  }

  resource dmzSubnet 'subnets' existing = {
    name: dmzSubnetName
  }
}

resource bastionPip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: bastionIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: bastionHostName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastionIpConfig'
        properties: {
          subnet: {
            id: vnet.properties.subnets[1].id
          }
          publicIPAddress: {
            id: bastionPip.id
          }
        }
      }
    ]
  }
}

// NVA Resources
resource nvaNic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: nvaNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[3].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    networkSecurityGroup: {
      id: nvaNsg.id
    }
    enableIPForwarding: true
  }
}

resource nvaVm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: nvaVmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: nvaVmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nvaNic.id
        }
      ]
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
  }
}

resource nvaNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: nvaNsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-ssh'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '22'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Public VM resources
resource publicVm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: publicVMName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: publicVMName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: publicNic.id
        }
      ]
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
  }
}

resource publicNic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: publicVMNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// Private VM resources
resource privateVm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: privateVMName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: privateVMName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: privateNic.id
        }
      ]
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
  }
}

resource privateNic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: privateVMNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[2].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// ROUTE TABLE
resource routeTable 'Microsoft.Network/routeTables@2024-05-01' = {
  name: routeTableName
  location: location
  properties: {
    routes: [
      {
        name: 'to-private-subnet'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: vnet.properties.subnets[2].properties.addressPrefix
          nextHopIpAddress: nvaNic.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

resource privateSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name: '${vnet.name}/${privateVmSubnetName}'
}

resource subnetRouteAssociation 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: privateSubnet.name
  properties: {
    addressPrefix: privateVmSubnetPrefix
    routeTable: {
      id: routeTable.id
    }
  }
}
