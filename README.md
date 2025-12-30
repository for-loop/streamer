# streamer

Get started with Confluent Kafka. It uses custom Kafka Connect with MariaDB JDBC driver support

> Adapted from [Quick Start for Confluent Platform](https://docs.confluent.io/platform/current/get-started/platform-quickstart.html)

## First time

### Install CLI

```bash
brew install confluentinc/tap/cli
```

### Update CLI

```bash
brew upgrade confluentinc/tap/cli
```

### First time

In the original [docker-compose.yml](https://github.com/confluentinc/cp-all-in-one/blob/63518b1d964e3629a823fb70fcef573371ddf755/cp-all-in-one/docker-compose.yml#L37) provided by Confluent, the `CLUSTER_ID` is hardcoded. Generate a new ID and save it in the `.env` file. The problem, however, is that this process requires a broker. Here's one of the ways to set it up:

1. Start a broker container using the CLI
    ```bash
    confluent local kafka start
    ```
2. Find container name (*e.g.*, `confluent-local-broker-1`)
    ```bash
    docker ps
    ```
3. Get inside the container
    ```bash
    docker exec -it <CONTAINER_NAME> bash
    ```
4. Run the command and copy the new cluster ID that is printed on the console
    ```bash
    /bin/kafka-storage random-uuid
    ```
    > [More info](https://docs.confluent.io/kafka/operations-tools/kafka-tools.html#kafka-storage-sh)
5. Create an `.env` file at the root of the repo and paste the cluster ID
    ```
    CLUSTER_ID=<CLUSTER_ID>
    ```
6. Exit the container
    ```bash
    exit
    ```
6. Stop the container
    ```bash
    confluent local kafka stop
    ```

## Set up JDBC Sink Connector

The consumer can be replaced by a connector that transfers data from the topic of interest to MariaDB using Kafka Connect.

The problem, however, is that the Control Center does not provide this connector by default. When you click "Add connector" in the Control Center, you will want to see a tile that says, "JDBCSinkConnector". Also, you will need a JDBC driver for MariaDB. There are two ways to set this up—either a manual install or docker compose

### Manually install the JAR files

> Although straightforward, this is not a preferred method because JAR files shouldn't be committed to git

1. Download and unzip the file for "Confluent Platform (self-managed)" from [Confluent](https://www.confluent.io/hub/confluentinc/kafka-connect-jdbc). This contains the JAR files for the JDBCSinkConnector
2. Create a directory named `connect-plugins` at the root of this repo
3. Copy the JAR files from `lib` to `connect-plugins` directory
4. Download `mariadb-java-client-x.x.x.jar` from [Maven](https://repo.maven.apache.org/maven2/org/mariadb/jdbc/mariadb-java-client/) and put it in `connect-plugins` directory. This is the JDBC driver for MariaDB
5. Under the `connect` service in compose.yml, use the image from confluent
    ```yml
    image: confluentinc/cp-server-connect-base:7.9.0
    ```
5. Under the `connect` service in compose.yml, mount the volume from `connect-plugins` to `/usr/share/confluent-hub-components/confluentinc-kafka-connect-jdbc/lib/`
    ```yml
    volumes:
      - ./connect-plugins:/usr/share/confluent-hub-components/confluentinc-kafka-connect-jdbc/lib/
    ```
6. Confirm that `CONNECT_PLUGIN_PATH` env variable includes the path, `/usr/share/confluent-hub-components`. This will help Kafka Connect container find the JAR files
7. Start the containers
    ```bash
    docker compose up -d
    ```

### Build custom connector image (recommended)

This will build a custom image containing the JDBC driver for MariaDB, as configured in `pom.xml`

Run the containers

```bash
docker compose up -d
```

Wait a few minutes for the Control Center to recognize the Connect cluster

## Create a topic

1. Go to Topics in the Control Center
2. Click "Add topic" button
3. Enter Topic name and Number of partitions
4. Click "Create with defaults" button

## Configure sink connector

JDBCSinkConnector tile should be available when the "Add Connector" button is clicked (You can also verify at http://localhost:8083/connector-plugins). Next, configure the connector so that it can be used. From within the Control Center:

1. Click on `connect-default` cluster
2. Click on "Upload connector config file" button
3. Select `connector_malstrek-sink_config.json` (in malstrek repo)
4. Edit the user and password fields in the Control Center
5. Launch the connector

If it fails, check the log in the `connect` container and troubleshoot

### List active connectors

```bash
curl -s "http://localhost:8083/connectors"
```

### Status summary of all connectors

> This shows both the status and the config details

```bash
curl -s "http://localhost:8083/connectors?expand=info&expand=status" | jq
```

### Status for specific connector

```bash
curl -s "http://localhost:8083/connectors/<connector_name>/status" | jq
```

### Add a new connector

```bash
curl -X POST -H "Content-Type: application/json" --data @your-config-file.json http://localhost:8083/connectors
```

### Create or update connector config

```bash
curl -X PUT -H "Content-Type: application/json" --data @your-config-file-config-only.json http://localhost:8083/connectors/<connector_name>/config
```

> Note: The PUT method typically expects only the `config` object as the payload, not the wrapper with the `name`.

### Delete a specific connector

```bash
curl -s -X DELETE "http://localhost:8083/connectors/<connector_name>"
```

For more details, see https://developer.confluent.io/courses/kafka-connect/rest-api/

## Schema Registry

### List registered subjects

```bash
curl -X GET http://localhost:8081/subjects
```

### List versions of a specific subject

```bash
curl -X GET http://localhost:8081/subjects/<my-subject-value>/versions
```

> The default subject value is `<topic name>-value`

### View the full schema content

```bash
curl -X GET http://localhost:8081/subjects/<my-subject-value>/versions/latest | jq .
```

### Check if a particular schema has been registered

```bash
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
     --data "{\"schema\": $(jq -Rs . <myschema>.avsc)}" \
     http://localhost:8081/subjects/<my-subject-value>
```

### Register schema

```bash
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
     --data "{\"schema\": $(jq -Rs . <myschema>.avsc)}" \
     http://localhost:8081/subjects/<my-subject-value>/versions
```

### Delete schema

Soft delete all versions

```bash
curl -X DELETE http://localhost:8081/subjects/<my-existing-subject>
```

See https://docs.confluent.io/platform/7.9/schema-registry/schema-deletion-guidelines.html

---

## Docker compose commands

### Restart a particular container

```bash
docker compose restart control-center
```

### Stop containers

```bash
docker compose stop
```

## Docker commands

### Monitor logs in Kafka Connect container

```bash
docker logs -f connect
```

## UI

### Control Center

http://localhost:9021

## References

Adapted from docker-compose.yml in [Quick Start for Confluent Platform](https://docs.confluent.io/platform/current/get-started/platform-quickstart.html)

> Might want to try the [community edition](https://github.com/confluentinc/cp-all-in-one/blob/7.9.0-post/cp-all-in-one-community/docker-compose.yml) instead