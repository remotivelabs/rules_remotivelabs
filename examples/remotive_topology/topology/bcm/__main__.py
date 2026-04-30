"""Minimal BCM: publishes a `TurnLightControl` frame on `BodyCan0` once a
second, alternating left/right turn requests. Just enough to demonstrate
signal flow when the topology stack is up."""

import asyncio
import os

from remotivelabs.broker import BrokerClient, WriteSignal

NAMESPACE = "BodyCan0"


async def main() -> None:
    broker_url = os.environ["REMOTIVE_BROKER_URL"]
    print(f"BCM connecting to {broker_url}; publishing on {NAMESPACE}", flush=True)

    async with BrokerClient(url=broker_url) as client:
        toggle = 0
        while True:
            await client.publish(
                (
                    NAMESPACE,
                    [
                        WriteSignal(name="LeftTurnLightRequest", value=toggle),
                        WriteSignal(name="RightTurnLightRequest", value=1 - toggle),
                    ],
                ),
            )
            toggle ^= 1
            await asyncio.sleep(1)


if __name__ == "__main__":
    asyncio.run(main())
