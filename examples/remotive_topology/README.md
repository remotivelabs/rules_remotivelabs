# remotive_topology example

Minimum-viable consumer of `rules_remotivelabs`. Demonstrates the
`remotive_topology_generate` rule against a tiny topology, plus enough
runtime code that `docker compose up` against the generated output
brings up containers and a passing pytest.

## What's modelled

A single platform (`topology/platform/topology.platform.yaml`) with two
CAN buses (`BodyCan0`, `DriverCan0`) and one ECU model:

- **BCM** — implemented in `topology/bcm/`. Connects to its broker and
  publishes the `TurnLightControl` frame on `BodyCan0` once a second.
- **tester** — defined in `topology/tests/tester.instance.yaml`. Runs
  pytest against `topology-broker.com` (the topology-wide broker).
  Subscribes to `TurnLightControl` and asserts at least one frame
  carrying the expected signals arrives within 10 s.

The Python source (`topology/bcm/__main__.py`,
`topology/tests/test_turnlight.py`) is deliberately small — about 50
lines combined. Both BCM and tester containers are built from the same
`topology/Dockerfile` (Python 3.12 + `remotivelabs-broker` + `pytest`).

## Bazel — generation only

```bash
bazel build //:minimal_topology
```

Produces a docker-compose tree under
`bazel-bin/minimal_topology_out/getting-started/`. `bazel test //...`
runs the generation and validates the output tree exists.

> Running `docker compose up --build` *directly* against the
> Bazel-generated output doesn't work today — the topology binary emits
> `build.context` paths relative to the output directory, which lands
> outside the source tree once Bazel materialises the output via
> `bazel-bin/`. Use the manual workflow below to actually run the stack.

## Manual — generate + run

You'll need [`docker compose`](https://docs.docker.com/compose/install/)
and the [`remotive` CLI](https://docs.remotivelabs.com/docs/remotive-cli/installation)
installed locally.

```bash
# generate the docker-compose tree
remotive topology generate \
  -f topology/instances/main.instance.yaml \
  ./build

# bring up brokers + BCM, then run the tester
cd build/getting-started
docker compose up --build -d
docker compose --profile tester run --rm --build tester
```

Expected output: BCM logs a `BCM connecting to ...` line and starts
publishing; the tester runs pytest, sees `test_bcm_publishes_turnlight
PASSED`, exits 0.

Tear down with `docker compose down`.

## Layout

```
examples/remotive_topology/
├── BUILD.bazel                      remotive_topology_generate target
├── MODULE.bazel                     consumer-style declaration
├── remotive_topology_test.sh        Bazel-side smoke check on output
└── topology/
    ├── Dockerfile                   shared image for BCM + tester
    ├── requirements.txt             remotivelabs-broker, pytest
    ├── bcm/__main__.py              minimal publisher
    ├── instances/main.instance.yaml top-level instance (includes the rest)
    ├── models/bcm.instance.yaml     BCM as a Python container
    ├── platform/                    topology + DBCs
    └── tests/
        ├── tester.instance.yaml     tester container definition
        ├── conftest.py              `--broker_url` pytest option
        └── test_turnlight.py        single end-to-end assertion
```
