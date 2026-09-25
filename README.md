# moin-server Docker image

Runs a [Moin](https://moin.chat) community server. See the
[server docs](https://moin.chat/docs/server/) for setup.

```sh
docker run -d --name moin-server \
  -v moin-data:/data \
  -v ./moin-server.toml:/config/moin-server.toml:ro \
  ghcr.io/moinchat/moin-server:latest
```

## Volumes

- `/data`: the server's data. Back it up. Must be writable by UID `10001`.
- `/config/moin-server.toml`: the config file. Mount your own to replace the
  default. See the [config reference](https://moin.chat/docs/server/configuration).
