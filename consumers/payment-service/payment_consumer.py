import json
import os

from kafka import KafkaConsumer, KafkaProducer


def get_env(name: str, default: str) -> str:
    return os.environ.get(name, default)


KAFKA_BROKER = get_env("KAFKA_BROKER", "kafka:9092")
ORDERS_TOPIC = get_env("ORDERS_TOPIC", "orders")
PAYMENTS_TOPIC = get_env("PAYMENTS_TOPIC", "payments")


def create_consumer() -> KafkaConsumer:
    consumer = KafkaConsumer(
        ORDERS_TOPIC,
        bootstrap_servers=KAFKA_BROKER,
        group_id="payment-service-group",
        value_deserializer=lambda v: json.loads(v.decode("utf-8")),
        key_deserializer=lambda k: int(k.decode("utf-8")) if k else None,
        auto_offset_reset="earliest",
        enable_auto_commit=True,
    )
    print(f"[payment-service] Connected consumer to Kafka at {KAFKA_BROKER}, topic '{ORDERS_TOPIC}'")
    return consumer


def create_producer() -> KafkaProducer:
    producer = KafkaProducer(
        bootstrap_servers=KAFKA_BROKER,
        value_serializer=lambda v: json.dumps(v).encode("utf-8"),
        key_serializer=lambda k: str(k).encode("utf-8"),
    )
    print(f"[payment-service] Connected producer to Kafka at {KAFKA_BROKER}, topic '{PAYMENTS_TOPIC}'")
    return producer


def main():
    consumer = create_consumer()
    producer = create_producer()

    for message in consumer:
        order = message.value
        key = message.key

        print(f"[payment-service] Received order: key={key}, value={order}")

        if order.get("status") == "NEW":
            print(f"[payment-service] Processing payment for order {order.get('order_id')} "
                  f"amount={order.get('amount')} {order.get('currency')}")
            payment_event = {
                "order_id": order.get("order_id"),
                "customer_id": order.get("customer_id"),
                "amount": order.get("amount"),
                "currency": order.get("currency"),
                "status": "PAID",
            }
            producer.send(PAYMENTS_TOPIC, key=payment_event["order_id"], value=payment_event)
            producer.flush()
            print(f"[payment-service] Payment successful, event sent: {payment_event}")
        else:
            print(f"[payment-service] Skipping order {order.get('order_id')} with status={order.get('status')}")


if __name__ == "__main__":
    main()
