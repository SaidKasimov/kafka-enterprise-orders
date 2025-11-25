FROM confluentinc/cp-kafka-connect:7.6.1

# Устанавливаем JDBC и Couchbase коннекторы
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:latest \
 && confluent-hub install --no-prompt couchbase/kafka-connect-couchbase:4.1.11

# Кладём наш конфиг
COPY connect-distributed.properties /etc/kafka/connect-distributed.properties

# Запускаем Connect с этим конфигом
CMD ["connect-distributed", "/etc/kafka/connect-distributed.properties"]

