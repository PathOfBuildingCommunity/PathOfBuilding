# Versions

So far there is only one version

The base URL for an API should be: _baseURL_/_apiVersion_/ meaning even something such as sometestbuildsforpoe.gg/something/a/b/c/ would be valid as a base URL, as long  as it has afterwards the per version required endpoints.

## Metadata Endpoint

In order to provide a consistent API a metadata endpoint should be provided under _baseURL_/.well-known/pathofbuilding this endpoint should provide information about the API and the version of the API.
Furthermore this may allow having custom endpoints for the API.

<details><summary><b>Specification</b></summary>
| Feature          | Field         | Type             | Description                                                                          |
| ---------------- | ------------- | ---------------- | ------------------------------------------------------------------------------------ |
| League Filtering | league_filter | bool             | This can  be used to indicate whether the API supports filtering based on leagues    |
| Gem Filtering    | gem_filter    | bool             | This can  be used to indicate whether the API supports filtering based on gems       |
| Streams          | streams       | StreamInfo[]     | A list of streams available to be queried against                                    |
| Update Builds    | update_builds | UpdateBuildsInfo | Indicates if the API supports updating builds via PoB and which fields are supported |

</details>

### Types

<details><summary><b>StreamInfo</b></summary>

| Field   | Type   | Description                     |
| ------- | ------ | ------------------------------- |
| name    | string | Name of the stream              |
| apiPath | string | API path to the stream endpoint |

apiPath might be changed to a generic endpoint such as `/v1/{stream}/builds`
</details>

<details><summary><b>UpdateBuildsInfo</b></summary>
| Field      | Type     | Description                                            |
| ---------- | -------- | ------------------------------------------------------ |
| hasSupport | bool     | indicates if the API supports updating external builds |
| fields     | string[] | list of fields that can be updated                     |

Example:

```json
{
    "hasSupport": true,
    "fields": ["description", "youtubeUrl"]
}
```
</details>

## Version 1

### Response and Request types

<details><summary><b>BuildInfo</b></summary>

| Field        | Type    | Description                         |
| ------------ | ------- | ----------------------------------- |
| pobdata      | string  | The Path of Building data           |
| name         | string  | The name of the build               |
| lastModified | integer | The last modification timestamp     |
| buildId      | string  | The unique identifier for the build |
</details>

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

These values will just be the base patch version for the league.

These links are generally available via poewiki see: https://www.poewiki.net/wiki/Necropolis_league _Official Page_.

Example values:

| Patch | League                 | value | url                                    |
| ----- | ---------------------- | ----- | -------------------------------------- |
| 3.25  | Settlers of Kalguur    | 3.25  | https://www.pathofexile.com/settlers   |
| 3.24  | Necropolis             | 3.24  | https://www.pathofexile.com/necropolis |
| 3.23  | Affliction             | 3.23  | https://www.pathofexile.com/affliction |
| 3.22  | Trial of the Ancestors | 3.22  | https://www.pathofexile.com/ancestor   |
| 3.4   | Delve                  | 3.4   | https://www.pathofexile.com/delve      |

#### Responses

| http code | content-type       | response           |
| --------- | ------------------ | ------------------ |
| `200`     | `application/json` | `BuildInfo object` |

</details>


<details>
 <summary><code>POST</code> <code><b>/v1/builds/{buildId}</b></code> <code>(Update a single build on the source)</code></summary>

#### Parameters
> Path Parameters

| name    | type     | data type | description                                                |
| ------- | -------- | --------- | ---------------------------------------------------------- |
| buildId | required | string    | The build in question on the source that should be updated |

#### Request

| Field      | Type     | Description                        |
| ---------- | -------- | ---------------------------------- |
| pobdata    | string   | The Path of Building data          |
| name       | string   | The name of the build              |
| customData | string[] | A list of custom data to be stored |

customData will be describable fields via the metadata endpoint, if customData is empty it is expected to be ignored and no changes should be made.

#### Responses

| http code | content-type               | response              | Description            |
| --------- | -------------------------- | --------------------- | ---------------------- |
| `200`     | `application/json`         | None                  | Update succesful       |
| `201`     | `application/json`         | None                  | Succesful creation     |
| `400`     | `text/html; charset=utf-8` | `Reason for failure`  | Input may be incorrect |
| `401`     | `text/html; charset=utf-8` | `Reason if necessary` | Auth incorrect         |
| `404`     | `text/html; charset=utf-8` | None                  | Build does not exist   |

</details>

