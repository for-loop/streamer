FROM confluentinc/cp-server-connect-base:8.1.1

# Install the Confluent Hub JDBC Connector
# Will install JAR files in /usr/share/confluent-hub-components/confluentinc-kafka-connect-jdbc/lib/
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.9.2

WORKDIR /app
