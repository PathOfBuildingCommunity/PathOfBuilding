# Versions

So far there is only one version

The base URL for an API should be: _baseURL_/_apiVersion_/ meaning even something such as sometestbuildsforpoe.gg/something/a/b/c/ would be valid as a base URL, as long  as it has afterwards the per version required endpoints.

## Metadata Endpoint

In order to provide a consistent API a metadata endpoint should be provided under _baseURL_/.well-known/pathofbuilding this endpoint should provide information about the API and the version of the API.
Furthermore this may allow having custom endpoints for the API.

## Version 1

### Response and Request types

#### BuildInfo

| Field        | Type    | Description                         |
| ------------ | ------- | ----------------------------------- |
| pobdata      | string  | The Path of Building data           |
| name         | string  | The name of the build               |
| lastModified | integer | The last modification timestamp     |
| buildId      | string  | The unique identifier for the build |

### Endpoints

<details>
 <summary><code>GET</code> <code><b>/v1/builds</b></code> <code>(Lists multiple builds)</code></summary>

#### Parameters

| name | type     | data type | description         |
| ---- | -------- | --------- | ------------------- |
| page | optional | integer   | Used for pagination |

#### Responses

| http code | content-type       | response           |
| --------- | ------------------ | ------------------ |
| `200`     | `application/json` | `BuildInfo object` |

</details>

