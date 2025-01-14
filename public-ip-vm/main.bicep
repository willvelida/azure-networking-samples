param location string = resourceGroup().location
param vmName string = 'vmprodaewv001'
param adminUsername string = ''
param adminPassword string = ''

var addressPrefix = '10.0.0.0/16'
var vmSubnetPrefix = '10.0.0.0/24'
var bastionSubnetPrefix = '10.0.1.0/24'
var publicIpName = 'pip-prod-ae-wv-001'
var vnetName = 'vnet-prod-ae-wv-001'
var vmSubnetName = 'VMSubnet'
var bastionSubnetName = 'AzureBastionSubnet'
var nicName = 'nic-prod-ae-wv-001'
var bastionHostName = 'bastion-prod-ae-wv-001'
var vmSize = 'Standard_DS1_v2'

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
    name: vnetName
    location: location
    properties: {
        addressSpace: {
            addressPrefixes: [
                addressPrefix
            ]
        }
        subnets: [
            { 
                name: vmSubnetName
                properties: {
                    addressPrefix: vmSubnetPrefix
                }
            }
            {
                name: bastionSubnetName
                properties: {
                    addressPrefix: bastionSubnetPrefix
                }
            }
        ]
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

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
    name: nicName
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
                        id: publicIP.id
                    }
                }
            }
        ]
    }
}
