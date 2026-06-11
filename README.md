# swarm-wiki-js
Wiki JS for Docker Swarm

## Quick Start (Recommended)

The easiest way to deploy Wiki.js with automatic detection and interactive menus:

```bash
# Clone repository
git clone https://github.com/Sokrates1989/swarm-wiki-js.git
cd swarm-wiki-js

# Run interactive quick-start
bash quick-start.sh
```

The quick-start will:
- Detect existing deployments automatically
- Show maintenance menu for existing stacks (status, logs, scale, update)
- Guide fresh setup with interactive prompts
- Deploy the stack with proper configuration

## Manual Setup

For manual deployment or advanced configuration, follow the steps below.

### Prerequisites

### Domains and subdomains

```text
Make sure that domains and subdomains exist and point to manager of swarm.

Example for wiki.fe-wi.com:
 - wiki.fe-wi.com
```



##### Setup repo at desired location

```bash
# Choose location on server.
mkdir -p /swarm/wiki/<DOMAINNAME>
cd /swarm/wiki/<DOMAINNAME>
git clone https://github.com/Sokrates1989/swarm-wiki-js.git .
```

##### Copy templates
```bash
# Copy ".env.template" to ".env".
cp .env.template .env

# Copy "docker-compose.yml.template" to "docker-compose.yml".
cp docker-compose.yml.template docker-compose.yml
```

> **Note:** The quick-start script (`bash quick-start.sh`) automates these steps with guided prompts.

## Deployment Environment Safety

Docker Compose gives already-exported shell variables precedence over values in
`.env`. If the same shell was previously used for another stack, variables such
as `DATA_ROOT` or `STACK_NAME` can silently render this stack with paths and
Traefik labels from that other project.

Prefer the quick-start script for deploys:

```bash
bash quick-start.sh
```

The quick-start renders Compose from an isolated environment and loads deploy
variables from this repository's `.env` file only.

For manual deploys, do not run `docker-compose config` directly in a reused
shell. Load this repository's `.env` immediately before rendering Compose, then
inspect the rendered output before deploying:

```bash
set -a
. ./.env
set +a

# Verify that rendered paths, hostnames, labels, and stack-specific names come
# from this repository's .env before deploying.
docker-compose --env-file .env -f docker-compose.yml config

# Deploy only after the rendered config shows the expected DATA_ROOT,
# STACK_NAME-derived labels, hostnames, and secrets.
docker stack deploy -c <(docker-compose --env-file .env -f docker-compose.yml config) "$STACK_NAME"
```


### Edit configuration
##### .env

```bash
# Edit the variables in .env.
vi .env
# Make a note of STACK_NAME, as you need it to replace <STACK_NAME>
```

##### docker-compose.yml

```bash
# Edit the variables in .env.
vi docker-compose.yml

- Replace all occurrences of XXX_CHANGE_ME_MYSQL_ROOTPW_XXX with the Secret names created before (MYSQL_ROOTPW_WORDPRESS_XXXXXXXXX)
```


# Deploy

```bash
# We need a completely empty folder.
rm db_data/.gitkeep

# Deploy service on swarm using the isolated .env flow above.
# https://github.com/moby/moby/issues/29133.
bash quick-start.sh
# WAIT till Readiness is confirmed as described below.
```
See [Determine Readiness](#determine-readiness) how to confrm readiness.

# Determine Readiness

```bash
# Check if there are any issues with initial deployment.
docker stack services <STACK_NAME>
# Make sure that the replicas numbers equal left and right side ( 1/1 and 0/0 is good. 0/1 is bad )

# In case of unequal replicas check issues of the service.
docker service ps <STACK_NAME>_db --no-trunc
docker service ps <STACK_NAME>_wiki --no-trunc

# If all replicas started properly.
Wait ~10 min then check logs.

# Desired log entry of wiki.
docker service logs <STACK_NAME>_wiki
# TODO Add what to look out for

# Desired log entry of wordpress db.
docker service logs <STACK_NAME>_db
# TODO Add what to look out for
```


# Re-Deploy to fix errors

```bash
# Remove all services in the stack.
docker stack rm <STACK_NAME>

# Only, if you want to completely restart all data fresh.
# !!! COMPLETE RESTART (old data is moved) !!!
mv db_data/ db_data_old
# We need an empty folder.
git restore  db_data/.gitkeep
rm db_data/.gitkeep

# Re-deploy using isolated .env variables.
bash quick-start.sh
```
