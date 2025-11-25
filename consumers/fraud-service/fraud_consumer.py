import json
import os
from typing import List

from kafka import KafkaConsumer


def get_env(name: str, default: str) -> str:
    return os.environ.get(name, default)


KAFKA_BROKER = get_env("KAFKA_BROKER", "kafka:9092")
ORDERS_TOPIC = get_env("ORDERS_TOPIC", "orders")

AMOUNT_THRESHOLD = float(get_env("FRAUD_AMOUNT_THRESHOLD", "400"))
RISKY_COUNTRIES_RAW = get_env("FRAUD_RISKY_COUNTRIES", "RU,FR,BR")
RISKY_COUNTRIES: List[str] = [c.strip().upper() for c in RISKY_COUNTRIES_RAW.split(",") if c.strip()]


def create_consumer() -> KafkaConsumer:
    consumer = KafkaConsumer(
        ORDERS_TOPIC,
        bootstrap_servers=KAFKA_BROKER,
        group_id="fraud-service-group",
        value_deserializer=lambda v: json.loads(v.decode("utf-8")),
        key_deserializer=lambda k: int(k.decode("utf-8")) if k else None,
        auto_offset_reset="earliest",
        enable_auto_commit=True,
    )
    print(f"[fraud-service] Connected to Kafka at {KAFKA_BROKER}, topic '{ORDERS_TOPIC}'")
    print(f"[fraud-service] Amount threshold: {AMOUNT_THRESHOLD}, risky countries: {RISKY_COUNTRIES}")
    return consumer


def is_fraud(order: dict) -> (bool, str):
    amount = order.get("amount", 0)
    country = order.get("country", "").upper()

    if amount >= AMOUNT_THRESHOLD and country in RISKY_COUNTRIES:
        return True, "HIGH_AMOUNT_RISKY_COUNTRY"
    if amount >= AMOUNT_THRESHOLD:
        return True, "HIGH_AMOUNT"
    if country in RISKY_COUNTRIES:
        return True, "RISKY_COUNTRY"

    return False, ""


def main():
    consumer = create_consumer()

    for message in consumer:
        order = message.value
        key = message.key

        print(f"[fraud-service] Received order: key={key}, value={order}")

        flagged, reason = is_fraud(order)
        if flagged:
            alert = {
                "order_id": order.get("order_id"),
                "reason": reason,
                "amount": order.get("amount"),
                "country": order.get("country"),
                "status": "CANCELLED",
            }
            print(f"[fraud-service] FRAUD ALERT: {alert}")
        else:
            print(f"[fraud-service] Order is clean, id={order.get('order_id')}")


if __name__ == "__main__":
    main()
