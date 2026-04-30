"""pytest configuration for the tester container.

The tester is launched by docker-compose with
`pytest --broker_url=http://topology-broker.com:50051 ...`. We expose the
URL to tests via a session-scoped fixture.
"""

import pytest


def pytest_addoption(parser):
    parser.addoption(
        "--broker_url",
        action="store",
        required=True,
        help="URL of the RemotiveBroker to connect to (e.g. http://topology-broker.com:50051).",
    )


@pytest.fixture(scope="session")
def broker_url(request):
    return request.config.getoption("--broker_url")
