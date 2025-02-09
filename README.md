# swarm-wiki-js
Wiki JS for Docker Swarm

# First Setup

### Domains and subdomains

```text
Make sure that domains and subdomains exist and point to manager of swarm.

Example for wiki.fe-wi.com:
 - wiki.fe-wi.com
```



##### Setup repo at desired location

```bash
# Choose location on server (glusterfs when using multiple nodes is recommended).
mkdir -p /gluster_storage/swarm/wiki/<DOMAINNAME>
cd /gluster_storage/swarm/wiki/<DOMAINNAME>
git clone https://github.com/Sokrates1989/swarm-wiki-js.git .
```

##### Copy templates
```bash
# Copy ".env.template" to ".env".
cp .env.template .env

# Copy "docker-compose.yml.template" to "docker-compose.yml".
cp docker-compose.yml.template docker-compose.yml
```

##### Create secrets in docker swarm (TODO adapt docker files to use secrets)
```bash
# XXX_CHANGE_ME_WIKIJS_DB_PASSWORD_XXX.
vi secret.txt  # Then insert password (Make sure the password does not contain any backslashes "\") and save the file.
docker secret create WIKIJS_DB_PASSWORD_XXXXXXXXX secret.txt # Change WIKIJS_DB_PASSWORD_XXXXXXXXX
rm secret.txt
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
# Deploy service on swarm using .env via docker compose.
# https://github.com/moby/moby/issues/29133.
docker stack deploy -c <(docker-compose config) <STACK_NAME>
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

# Re-deploy.
docker stack deploy -c <(docker-compose config) <STACK_NAME>
```
