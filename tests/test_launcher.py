"""Tests for proxy environment variable passthrough in src/launcher.sh."""

# Standard Python Libraries
from pathlib import Path
import re

# Third-Party Libraries
import pytest

LAUNCHER_SH = Path(__file__).parent.parent / "src" / "launcher.sh"


def _launcher_passlist_regexes() -> list[str]:
    launcher = LAUNCHER_SH.read_text()
    match = re.search(r"^ENV_VAR_PASSLIST_REGEX='([^']+)'$", launcher, re.MULTILINE)
    assert match, "ENV_VAR_PASSLIST_REGEX is not defined in launcher.sh"
    return match.group(1).split()


def _is_allowed(env_var_name: str) -> bool:
    return any(re.search(regex, env_var_name) for regex in _launcher_passlist_regexes())


@pytest.mark.parametrize(
    "env_var_name",
    [
        "HTTP_PROXY",
        "HTTPS_PROXY",
        "ALL_PROXY",
        "NO_PROXY",
        "http_proxy",
        "https_proxy",
        "all_proxy",
        "no_proxy",
        "CUSTOM_PROXY",
        "custom_proxy",
    ],
)
def test_proxy_env_vars_are_allowlisted(env_var_name: str) -> None:
    """Proxy environment variable names are allowed through launcher passlist."""
    assert _is_allowed(env_var_name)
