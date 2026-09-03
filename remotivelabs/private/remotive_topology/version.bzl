"""
Version-string helpers for the pinned `remotive-topology` release.

Rules read the toolchain's `version` and use `version_at_least` to gate
attributes that only newer binaries understand, failing at analysis time
with a clear message instead of a cryptic error from the binary.
"""

def parse_version(version):
    """Parses `"0.30.1"` into the comparable tuple `(0, 30, 1)`.

    Args:
      version: dotted numeric version string.

    Returns:
      A tuple of ints, one per component.
    """
    return tuple([int(component) for component in version.split(".")])

def version_at_least(version, minimum):
    """Returns True when `version` is `minimum` or newer (numeric compare per component).

    Args:
      version: dotted numeric version string.
      minimum: dotted numeric version string to compare against.

    Returns:
      True when `version >= minimum`.
    """
    return parse_version(version) >= parse_version(minimum)
