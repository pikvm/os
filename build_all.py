#!/usr/bin/env python

import os
import contextlib

from typing import Generator

import yaml


# =====
def _get_targets() -> list[dict[str, str]]:
    targets: list[dict[str, str]] = []
    wfs_path = ".github/workflows"
    for name in os.listdir(wfs_path):
        if name.startswith("v"):
            with open(os.path.join(wfs_path, name)) as file:
                config = yaml.safe_load(file.read())
                config = config["jobs"]["os"]["with"]
                if "BOARD" not in config:
                    raise RuntimeError(f"Where is the BOARD? {config}")
                targets.append(config)
    return targets


@contextlib.contextmanager
def _configured(target: dict[str, str]) -> Generator[None, None, None]:
    name = "config.mk"
    try:
        with open(name, "w") as file:
            file.write("\n".join(
                f"{key}={value}"
                for (key, value) in target.items()
            ) + "\n")
        yield
    finally:
        try:
            os.remove(name)
        except FileNotFoundError:
            pass


def main() -> None:
    for target in _get_targets():
        if target["BOARD"] in ["zero2w"]: #["zero2w", "rpi3", "rpi4"]:
            target["ARCH_DIST_REPO_URL"] = "http://m64/mirror/archlinux-arm"
            target["ARCH"] = "aarch64"
            with _configured(target):
                retval = os.system("cat config.mk && make os && make image IMAGE_XZ=1")
                if retval != 0:
                    raise RuntimeError(f"Build failed: {target}")
                print()


if __name__ == "__main__":
    main()
