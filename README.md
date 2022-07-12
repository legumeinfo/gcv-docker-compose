# GCV Docker Compose

This repository contains files for running the [Genome Context Viewer (GCV)](https://github.com/legumeinfo/gcv) and the [microservices it depends on](https://github.com/legumeinfo/microservices) with Docker Compose.

**If you are deploying an instance of GCV, download a zipped copy of this repository from the [Releases page](https://github.com/legumeinfo/gcv-docker-compose/releases).
This will ensure you are deploying a stable release.**

If you are a developer, then clone the respoitory and include submodules in your clone:
```console
git clone --recurse-submodules https://github.com/legumeinfo/gcv-docker-compose.git
```

## Quick Start

Start an instace of GCV and all the microservices it requires with the following command:
```console
docker compose -f compose.yml -f compose.prod.yml --profile all up -d
```
The instance of GCV you just started should be available at [localhost:4200/gcv](http://localhost:4200/gcv).

## Compose Files

This repository provides multiple Compose files: `compose.yml`, `compose.prod.yml`, and `compose.dev.yml`.

### `compose.yml`
**This file contains a base configuration and must be used with `compose.prod.yml` OR `compose.dev.yml` to properly deploy GCV** (see [Understanding multiple Compose files](https://docs.docker.com/compose/extends/#multiple-compose-files) for an explanation of this strategy).
For example:
```console
docker compose -f compose.yml -f compose.prod.yml ...
```

### `compose.prod.yml`
**This is the Compose file to use if you are deploying an instance of GCV.**
It downloads prebuilt Docker images from the [GitHub Container Registry](https://github.com/orgs/legumeinfo/packages) and configures them for use in a production environment, including configuring the [Traefik](https://doc.traefik.io/traefik/) reverse proxy for the microservices (see the [Traefik documentation](https://doc.traefik.io/traefik/https/overview/) if you want to deploy with HTTPS and TLS).

### `compose.dev.yml`
This is the compose file to use if you are a developer.
It builds the GCV and microservice Docker containers locally using the code in the `gcv/` and `microservices/` submodules, respectively.
You must clone the repository with submodules to use this file.


## Compose Profiles

The Compose files define the following [profiles](https://docs.docker.com/compose/profiles/): `gcv`, `services`, `all`, and `redis_loader`.
**At least one profile must be specified when using a Compose file.** For example:
```console
docker compose -f compose.yml -f compose.prod.yml --profile gcv ...
```

### `gcv`
This profile runs just the GCV web app (no microservices).
This should be used if you want your instance of GCV to load data from microservices deployed by another group or if you want to deploy multiple instances of the microservices and have just one GCV web app load data from all of them.

### `services`
This profile runs just the microservices (no GCV web app).
This should be used if you want to deploy the microservices without the GCV web app or if you want to deploy multiple instances of the microservices but only a single instance of the GCV web app.

### `all`
This deploys both the GCV web app and the microservices.
This should be used if you want to deploy an instance of the GCV web app that loads data from only one instance of the microservices.

### `redis_loader`
The microservices load data from a Redis database, which is defined as a service in the Compose files.
The Compose files also define a `redis_loader` service that provides a command-line program for loading data into Redis from a Chado database and/or GFF files.

```console
docker compose -f compose.yml -f compose.prod.yml run redis_loader ...
```
See the [`redis_loader` documentation](https://github.com/legumeinfo/microservices/tree/main/redis_loader) for details on how to load data in to the microservices' Redis database.


## Environment Variables
The services defined in the Compose files can be configured via the following environment variables.
We recommend setting these variables via the `.env` file [described below](#env).

### `DOMAIN` (required)
This sets the domain GCV and the microservices are served at.
Use `localhost` for testing on your own computer.

### `GCV_PORT` (default: `4200`)
This sets the port the GCV web app is served at.

### `GCV_PATH` (default: `/gcv/`)
This sets the path the GCV web app is served at. Note: a trailing slash is required!

### `TRAEFIK_PORT` (default: `80`)
This is the port the microservices are served at.

### `MICROSERVICES_PATH` (default: `/gcv/microservices`)
This is the path the microservices are served at. Note: there should be no trailing slash!

### `COMPOSE_PROJECT_NAME` (required in `compose.prod.yml`)
This sets the [project name](https://docs.docker.com/compose/#multiple-isolated-environments-on-a-single-host) in Compose.
We also use it to limit what services the Traefik reverse proxy controls, i.e. a Traefik reverse proxy only controls services that have the same Compose project name.
Note: setting the project name via the Compose `--project` command-line flag does not have the same effect; the `COMPOSE_PROJECT_NAME` environment variable must be given a value before using Compose, such as via the `.env` file.

### `TRAEFIK_LOG_LEVEL` (default: `ERROR` in `compose.prod.yml`, `DEBUG` in `compose.dev.yml`)
This sets the Traefik reverse proxy's log level.
Valid values are `DEBUG`, `PANIC`, `FATAL`, `ERROR`, `WARN`, and `INFO`.
See the [Traefik documentation](https://doc.traefik.io/traefik/observability/logs/#level) for details.

### `TRAEFIK_API_PORT` (default: `8080` in `compose.dev.yml`)
This sets what port the Traefik API is served at.
The Traefik API is disabled in the production `compose.prod.yml` file for security purposes.
See the [Traefik documentation](https://doc.traefik.io/traefik/operations/api/) for details.


## Other Files and Directories

### `config/`
This directory contains the `config.json` file used to configure the GCV web app and other related assets. See the [GCV Wiki](https://github.com/legumeinfo/gcv/wiki/Client-Configuration) for details.

### `data/`
This directory is where data related to the microservices is stored. The `redis/` subdirectory is where the Redis `.rdb` database file is stored, allowing data to persist between container restarts.

### `envoy/`
This directory contains files related to the configuration of the Envoy service used to resolve gRPC Web requests.

### `.env`
This file contains values for environment variables and will be automatically read by Compose before parsing the Compose files.
You can set the value of any of the environment variables discussed above in this file or tell Compose to load environment variables from a different file using the `--env-file` command-line flag.
If you plan to deploy multiple instances of the microservices, we recommend using this flag with a different `.env` file for each instance, e.g. `.a.env` and `.b.env`. See the [Compose documentation](https://docs.docker.com/compose/env-file/) for details.
