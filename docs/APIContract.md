# Versions

So far there is only one version

The base URL for an API should be: _baseURL_/_apiVersion_/ meaning even something such as sometestbuildsforpoe.gg/something/a/b/c/ would be valid as a base URL, as long  as it has afterwards the per version required endpoints.

## Metadata Endpoint

In order to provide a consistent API a metadata endpoint should be provided under _baseURL_/.well-known/pathofbuilding this endpoint should provide information about the API and the version of the API.
Furthermore this may allow having custom endpoints for the API.

| Feature          | Field         | Type | Description                                                                       |
| ---------------- | ------------- | ---- | --------------------------------------------------------------------------------- |
| League Filtering | league_filter | bool | This can  be used to indicate whether the API supports filtering based on leagues |
| Gem Filtering    | gem_filter    | bool | This can  be used to indicate whether the API supports filtering based on gems    |

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
> Query Parameters

| name   | type     | data type | description                             |
| ------ | -------- | --------- | --------------------------------------- |
| page   | optional | integer   | Used for pagination                     |
| league | optional | string    | Used to limit builds to a league        |
| gems   | optional | string    | Used to limit builds with specific gems |

##### League

The values should be matching what Grinding Gear Games will be using for the teaser part of the website, such as: _https://www.pathofexile.com/settlers_ or _https://www.pathofexile.com/affliction_. This allows for easier mapping of the data as neither PoB nor the API will be required to wait for either party.

These links are generally available via poewiki see: https://www.poewiki.net/wiki/Necropolis_league _Official Page_.

Example values:

| Patch | League                 | value      | url                                    |
| ----- | ---------------------- | ---------- | -------------------------------------- |
| 3.25  | Settlers of Kalguur    | settlers   | https://www.pathofexile.com/settlers   |
| 3.24  | Necropolis             | necropolis | https://www.pathofexile.com/necropolis |
| 3.23  | Affliction             | affliction | https://www.pathofexile.com/affliction |
| 3.22  | Trial of the Ancestors | ancestor   | https://www.pathofexile.com/ancestor   |
| 3.4   | Delve                  | delve      | https://www.pathofexile.com/delve      |

#### Responses

| http code | content-type       | response           |
| --------- | ------------------ | ------------------ |
| `200`     | `application/json` | `BuildInfo object` |

</details>

