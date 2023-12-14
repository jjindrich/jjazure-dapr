using System.Text.Json.Nodes;
using Dapr.Client;

var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

app.MapGet("/hello", () => "JJ Hello World!");

app.MapGet("/call", async () =>
{
    using var client = new DaprClientBuilder().Build();

    var ret = await client.InvokeMethodAsync<JsonObject>(HttpMethod.Get, "extapi", "jsonip");
    var s = ret;
    
    return "JJ: " + s;
});

app.Run();
