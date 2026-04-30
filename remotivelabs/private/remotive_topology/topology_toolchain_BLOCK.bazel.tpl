toolchain(
    name = "{name}",
    exec_compatible_with = [
        "{os_constraint}",
        "{cpu_constraint}",
    ],
    toolchain = "@{repo}//:toolchain_impl",
    toolchain_type = "@rules_remotivelabs//remotivelabs/toolchains/remotive_topology:toolchain_type",
)
