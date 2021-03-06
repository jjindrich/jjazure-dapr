# Dapr Money Sample

Sample taken from https://github.com/dapr/dotnet-sdk/tree/master/samples/AspNetCore/ControllerSample

It exposes the following endpoints over HTTP:
 - GET `/{account}`: Get the balance for the account specified by `id`
 - POST `/deposit`: Accepts a JSON payload to deposit money to an account
 - POST `/withdraw`: Accepts a JSON payload to withdraw money from an account

The application also registers for pub-sub with the `deposit` and `withdraw` topics.

## Running the Sample

 To run the sample locally run this comment in this directory:

 ```sh
 dapr run --app-id moneyapp --app-port 5000 dotnet run
 ```

 The application will listen on port 5000 for HTTP (not Dapr endpoint).

### Test calling HTTP endpoint

**Deposit Money**

 ```sh
curl -X POST http://localhost:5000/deposit \
        -H 'Content-Type: application/json' \
        -d '{ "id": "17", "amount": 12 }'
 ```

**Withdraw Money**

 ```sh
curl -X POST http://localhost:5000/withdraw \
        -H 'Content-Type: application/json' \
        -d '{ "id": "17", "amount": 10 }'
 ```

**Get Balance**

```sh
curl http://localhost:5000/17
```