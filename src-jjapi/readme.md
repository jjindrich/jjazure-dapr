# Run API using Dapr 
This repo contains minimal API using Dapr (https://dapr.io).

## Create API with Dapr and test locally

Using dotnet 8.

```
dotnet new web -o jjapi
dotnet run

curl http://localhost:5201/hello
```

Now add Dapr

```
dotnet add package Dapr.Client

dapr run --app-id app-jjapi --dapr-http-port 5020 --app-port 5201 --resources-path ./components dotnet run

curl http://localhost:5020/v1.0/invoke/app-jjapi/method/hello
```

Now we add some Dapr logic - calling external service via Dapr service invocation
- https://docs.dapr.io/developing-applications/building-blocks/service-invocation/howto-invoke-non-dapr-endpoints/


## Create Docker image and publish to Azure Container Registry

Docs 
- Dockerfile https://learn.microsoft.com/en-us/dotnet/core/docker/build-container?tabs=windows&pivots=dotnet-8-0#create-the-dockerfile
- Default port https://learn.microsoft.com/en-us/dotnet/core/compatibility/containers/8.0/aspnet-port

```
docker built . -t jjapi
docker run -d -p 8080:8080 jjapi
```

Publish to Azure Container Registry

```
az group create -n jjapi-rg -l swedencentral
az acr create --resource-group jjapi-rg --name jjacr12345 --sku Basic --admin-enabled true
az acr build --image jjapi:v1 --registry jjacr12345 --file Dockerfile .
```

## Deploy to Azure Container App

Deploy without using Dapr
```
az extension add --name containerapp --upgrade
az containerapp env create --name jjapienv --resource-group jjapi-rg --location swedencentral
az containerapp create --name jjapi --resource-group jjapi-rg --environment jjapienv --image jjacr12345.azurecr.io/jjapi:v1 --target-port 8080 --ingress 'external' --registry-server jjacr12345.azurecr.io --query properties.configuration.ingress.fqdn
```

Deploy with Dapr enabled
```
az extension add --name containerapp --upgrade
az containerapp env create --name jjapienv --resource-group jjapi-rg --location swedencentral
az containerapp create --name jjapi --resource-group jjapi-rg --enable-dapr --dapr-app-id jjapi --dapr-app-port 8080 --environment jjapienv --image jjacr12345.azurecr.io/jjapi:v1 --target-port 8080 --ingress 'external' --registry-server jjacr12345.azurecr.io --query properties.configuration.ingress.fqdn
```

You can call api
```
curl https://jjapi.orangetree-7906d767.swedencentral.azurecontainerapps.io/hello
```

!!! You cannot call service via DAPR from Ingress

## Publish with Azure API management

https://docs.dapr.io/developing-applications/integrations/azure/azure-api-management/
https://github.com/tomkerkhove/azure-apim-on-container-apps/blob/main/deploy/modules/integrate-container-app-in-api-gateway.bicep