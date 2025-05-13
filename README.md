# Gateway

Generar una secret key _(usa la misma con el users-service)_:

```bash
openssl rand -hex 32
```

System gateway config

### Start with docker

Create `tpii-network` if not already created

```bash
docker network create tpii-network
```

Start the gateway with Docker Compose:

```bash
docker compose up
```
