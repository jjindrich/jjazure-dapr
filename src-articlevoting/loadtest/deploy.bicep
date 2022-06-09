param location string = resourceGroup().location
param testName string = 'jjarticlevoting-tests'
param appName string = 'jjarticlevoting-ui'

resource uiApp 'Microsoft.App/containerApps@2022-03-01' existing = {
  name: appName
}

resource loadtest 'Microsoft.LoadTestService/loadTests@2022-04-15-preview' = {
  name: testName
  location: location
}

// TODO: tests cannot be created via ARM API
// https://docs.microsoft.com/en-us/rest/api/loadtesting/create-load-test

