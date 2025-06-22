FROM maven AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline

FROM confluentinc/cp-server-connect-base:7.9.0

# Install the Confluent Hub JDBC Connector
# Will install JAR files in /usr/share/confluent-hub-components/confluentinc-kafka-connect-jdbc/lib/
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.8.4

WORKDIR /app

# Copy the downloaded MariaDB Connector/J JAR from the builder stage
ARG MARIADB_DRIVER_VERSION=3.5.3
COPY --from=builder /root/.m2/repository/org/mariadb/jdbc/mariadb-java-client/${MARIADB_DRIVER_VERSION}/mariadb-java-client-${MARIADB_DRIVER_VERSION}.jar /usr/share/confluent-hub-components/confluentinc-kafka-connect-jdbc/lib/
