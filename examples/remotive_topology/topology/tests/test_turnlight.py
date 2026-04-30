"""
End-to-end smoke test: BCM should be publishing `TurnLightControl` on
`BodyCan0`. Subscribe via the topology-wide broker, wait for the first
frame, assert it carries the expected signals.
"""

import asyncio

from remotivelabs.broker import BrokerClient

NAMESPACE = "BodyCan0"
FRAME = "TurnLightControl"
WAIT_S = 10.0


async def _await_first_frame(broker_url: str):
    async with BrokerClient(url=broker_url) as client:
        stream = await client.subscribe_frames((NAMESPACE, [FRAME]))
        async for frame in stream:
            return frame
    return None


def test_bcm_publishes_turnlight(broker_url):
    frame = asyncio.run(
        asyncio.wait_for(_await_first_frame(broker_url), timeout=WAIT_S)
    )
    assert frame is not None, f"no {FRAME} frame received within {WAIT_S}s"
    assert "LeftTurnLightRequest" in frame.signals
    assert "RightTurnLightRequest" in frame.signals
