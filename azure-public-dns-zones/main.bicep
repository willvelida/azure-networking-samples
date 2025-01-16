param customDomainName string = 'example.com'
param email string = ''
param firstName string = ''
param lastName string = ''
param phone string = '<needs to be in the following format +00.000000000>'
param agreedAt string = utcNow()
param agreedBy string = '<your-client-ip>'
param location string = 'westus2'
param address1 string = ''
param city string = ''
param country string = ''
param postalCode string = ''
param state string = ''
param webAppName string = 'swa-prod-ae-wv-001'

resource customDomain 'Microsoft.DomainRegistration/domains@2024-04-01' = {
  name: customDomainName
  location: 'global'
  properties: {
    autoRenew: false
    privacy: true
    consent: {
      agreedAt: agreedAt
      agreedBy: agreedBy
      agreementKeys: [
        'DNRA'
        'DNPA'
      ]
    }
    contactAdmin: {
      email: email
      nameFirst: firstName
      nameLast: lastName
      phone: phone
      addressMailing: {
        address1: address1
        city: city
        country: country
        postalCode: postalCode
        state: state
      }
    }
    contactBilling: {
      email: email
      nameFirst: firstName
      nameLast: lastName
      phone: phone
      addressMailing: {
        address1: address1
        city: city
        country: country
        postalCode: postalCode
        state: state
      }
    }
    contactRegistrant: {
      email: email
      nameFirst: firstName
      nameLast: lastName
      phone: phone
      addressMailing: {
        address1: address1
        city: city
        country: country
        postalCode: postalCode
        state: state
      }
    }
    contactTech: {
      email: email
      nameFirst: firstName
      nameLast: lastName
      phone: phone
      addressMailing: {
        address1: address1
        city: city
        country: country
        postalCode: postalCode
        state: state
      }
    }
  }
}

resource swa 'Microsoft.Web/staticSites@2021-01-15' = {
  name: webAppName
  location: location
  sku: {
    tier: 'Free'
    name: 'Free'
  }
  properties: {}
}

resource swaCustomDomain 'Microsoft.Web/staticSites/customDomains@2021-01-15' = {
  name: customDomainName
  parent: swa
  properties: {
    validationMethod: 'dns-txt-token'
  }
}

resource publicDnsZone 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: customDomainName
  location: 'global'
}

resource cname 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  name: 'www'
  parent: publicDnsZone
  properties: {
    TTL: 3600
    CNAMERecord: {
      cname: swa.properties.defaultHostname
    }
  }
}
