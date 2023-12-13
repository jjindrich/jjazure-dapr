# Run API using Dapr 
This repo contains minimal API using Dapr (https://dapr.io).

## Create API with Dapr and test locally

```
dotnet new web -o jjapi
dotnet run

curl http://localhost:5201/hello
```

Now add Dapr

```
dotnet add package Dapr.Client

dapr run --app-id app-jjapi --dapr-http-port 5020 --app-port 5201 dotnet run --components-path ./components

curl http://localhost:5020/v1.0/invoke/app-jjapi/method/hello
```

TODO: Add logic into API - call external service https://docs.dapr.io/developing-applications/building-blocks/service-invocation/howto-invoke-non-dapr-endpoints/

## Publish with Azure API management

https://docs.dapr.io/developing-applications/integrations/azure/azure-api-management/
https://github.com/tomkerkhove/azure-apim-on-container-apps/blob/main/deploy/modules/integrate-container-app-in-api-gateway.bicep