"""Analysis test for the public topology build provider."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//remotivelabs/rules:remotive_topology.bzl", "RemotiveTopologyBuildInfo")

def _provider_fields_test_impl(ctx):
    env = analysistest.begin(ctx)
    info = ctx.attr.target_under_test[RemotiveTopologyBuildInfo]

    asserts.equals(env, "minimal_topology", info.name)
    asserts.true(env, info.output_dir.is_directory)

    source_paths = [source.short_path for source in info.sources.to_list()]
    asserts.true(
        env,
        "tests/fixtures/topology/instances/main.instance.yaml" in source_paths,
        "root instance is missing from provider sources",
    )
    asserts.true(
        env,
        "tests/fixtures/topology/Dockerfile" in source_paths,
        "declared data is missing from provider sources",
    )
    return analysistest.end(env)

provider_fields_test = analysistest.make(_provider_fields_test_impl)

def topology_provider_analysis_test(name, target_under_test):
    """Checks the `RemotiveTopologyBuildInfo` a `remotive_topology_build` returns.

    Args:
      name: name of the analysis test target.
      target_under_test: the `remotive_topology_build` to inspect.
    """
    provider_fields_test(
        name = name,
        target_under_test = target_under_test,
    )
