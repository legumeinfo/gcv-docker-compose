# GCV Docker Compose
This repository contains files for running the [Genome Context Viewer (GCV)](https://github.com/legumeinfo/gcv) and the [microservices it depends on](https://github.com/legumeinfo/microservices) with Docker Compose.

**If you are deploying an instance of GCV, download a zipped copy of this repository from the [Releases page](https://github.com/legumeinfo/gcv-docker-compose/releases).
This will ensure you are deploying a stable release.**

If you are a developer, then clone the respoitory and include submodules in your clone:
```console
git clone --recurse-submodules https://github.com/legumeinfo/gcv-docker-compose.git
```


## Quick Start
Start by loading some data:
```console
docker-compose -f compose.yml -f compose.prod.yml run redis_loader
```
See the [Loading Data](#loading-data) section for instructions on how to load your own data.

Next, start an instance of GCV and all the microservices it requires with the following command:
```console
docker compose -f compose.yml -f compose.prod.yml --profile all up -d
```
The instance of GCV you just started should be available at [localhost:4200/gcv](http://localhost:4200/gcv).
Try searching for the gene "Glyma.15G255600" to confirm that everything is working.


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
Although the `redis_loader` profile is used to ensure the Redis service is running when the `redis_loader` service is run, the `redis_loader` service should be run directly since it is a command-line program:
```console
docker compose -f compose.yml -f compose.prod.yml run redis_loader ...
```
See the [Loading Data](#loading-data) section for instructions on how to use this profile to load your own data.


## Loading Data
The compose files use the `data/redis/` directory as the location for the Redis database file.
Redis calls this file `dump.rdb` by default and it will be automatically generated by Redis when you load data.
The `redis_loader` service supports two modes of loading data: command-line and scripting.

### Command-line
In command-line mode, arguments are passed directly to the `redis_loader` service.
For example:
```console
docker compose -f compose.yml -f compose.prod.yml run redis_loader --load_type reload \
    gff \
        --genus Glycine \
        --species max \
        --strain Wm82 \
        --chromosome-gff https://github.com/legumeinfo/microservices/raw/main/tests/data/genome.gff3.gz \
        --gene-gff https://github.com/legumeinfo/microservices/raw/main/tests/data/genes.gff3.gz \
        --gfa https://github.com/legumeinfo/microservices/raw/main/tests/data/gfa.tsv.gz
```
Note that in this example URLs are provided for the GFF and GFA files.
If paths to local files are to be used instead, then a directory containing the files needs to be mounted as a [volume](https://docs.docker.com/storage/volumes/) inside the container and the paths should describe where the files are relative to this volume inside the container.

### Scripting
When the `redis_loader` service starts, it checks the `/docker-entrypoint-initdb.d/` directory inside the container for `.sh` scripts.
**If the Redis database is empty**, these scripts will be automatically executed in alphabetical order.
For convenience, the compose files mount the `data/docker-entrypoint-initdb.d/` directory as the `/docker-entrypoint-initdb.d/` directory inside the container.
This means if there are scripts in the `data/docker-entrypoint-initdb.d/` directory, then the `redis_loader` service can be run without any command-line arguments and the scripts will automatically be executed:
```console
docker-compose -f compose.yml -f compose.prod.yml run redis_loader
```

The `redis_loader` service is actually a Python module.
The scripts in the `redis_loader` container's `/docker-entrypoint-initdb.d/` directory can run this python module directly.
For example, the `data/docker-entrypoint-initdb.d/example.sh` script used in the [Quick Start](#quick-start) runs the example from the [Command-line](#command-line) section:
```console
python -u -m redis_loader --load_type reload \
    gff \
        --genus Glycine \
        --species max \
        --strain Wm82 \
        --chromosome-gff https://github.com/legumeinfo/microservices/raw/main/tests/data/genome.gff3.gz \
        --gene-gff https://github.com/legumeinfo/microservices/raw/main/tests/data/genes.gff3.gz \
        --gfa https://github.com/legumeinfo/microservices/raw/main/tests/data/gfa.tsv.gz
```
The main advantage of this approach is that it can be used for automation and for loading batches of files.


For details about the `redis_loader` command-line options, use the `--help` flag:
```console
docker-compose -f compose.yml -f compose.prod.yml run redis_loader --help
```
More thorough documentation is available in the `redis_loader`[microservice documentation](https://github.com/legumeinfo/microservices/tree/main/redis_loader).
This includes instructions on how to use the `redis_loader` to load data from a [Chado](http://gmod.org/wiki/Chado_-_Getting_Started) database.


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

### `REDIS_START_PERIOD` (default: `90s`)
This sets how long Docker Compose will wait for Redis to start before the service's [healthcheck](https://docs.docker.com/compose/compose-file/#healthcheck) is allowed to fail.
This value will need to be increased when loading a relatively large Redis `.rdb` database file.
See the [Docker Compose documentation](https://docs.docker.com/compose/compose-file/#specifying-durations) for valid values.


## Other Files and Directories

### `config/`
This directory contains the `config.json` file used to configure the GCV web app and other related assets. See the [GCV Wiki](https://github.com/legumeinfo/gcv/wiki/Client-Configuration) for details.

### `data/`
This directory is where data related to the microservices is stored.
The `redis/` subdirectory is where the Redis `.rdb` database file generated when you load data is stored, allowing data to persist between container restarts.
And the `docker-entrypoint-initdb.d/` subdirectory is where custom scripts for loading data should be placed; see the [Loading Data](#loading-data) section for details.

### `envoy/`
This directory contains files related to the configuration of the Envoy service used to resolve gRPC Web requests.

### `.env`
This file contains values for environment variables and will be automatically read by Compose before parsing the Compose files.
You can set the value of any of the environment variables discussed above in this file or tell Compose to load environment variables from a different file using the `--env-file` command-line flag.
If you plan to deploy multiple instances of the microservices, we recommend using this flag with a different `.env` file for each instance, e.g. `.a.env` and `.b.env`. See the [Compose documentation](https://docs.docker.com/compose/env-file/) for details.
