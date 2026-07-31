#!/usr/bin/env python


# =====
_TARGETS = [
    {"PLATFORM": "v1-hdmi",     "BOARD": "rpi2",   "ARCH": "arm"},
    {"PLATFORM": "v1-hdmi",     "BOARD": "rpi3",   "ARCH": "arm"},
    {"PLATFORM": "v1-hdmi",     "BOARD": "zero2w", "ARCH": "arm"},
    {"PLATFORM": "v1-hdmiusb",  "BOARD": "rpi2",   "ARCH": "arm"},
    {"PLATFORM": "v1-hdmiusb",  "BOARD": "rpi3",   "ARCH": "arm"},
    {"PLATFORM": "v1-hdmiusb",  "BOARD": "zero2w", "ARCH": "arm"},
    {"PLATFORM": "v2-hdmi",     "BOARD": "rpi3",   "ARCH": "arm"},
    {"PLATFORM": "v2-hdmi",     "BOARD": "rpi4",   "ARCH": "aarch64"},
    {"PLATFORM": "v2-hdmi",     "BOARD": "rpi4",   "ARCH": "arm"},
    {"PLATFORM": "v2-hdmi",     "BOARD": "zero2w", "ARCH": "arm"},
    {"PLATFORM": "v2-hdmiusb",  "BOARD": "rpi4",   "ARCH": "aarch64"},
    {"PLATFORM": "v2-hdmiusb",  "BOARD": "rpi4",   "ARCH": "arm"},
    {"PLATFORM": "v3-hdmi",     "BOARD": "rpi4",   "ARCH": "aarch64"},
    {"PLATFORM": "v3-hdmi",     "BOARD": "rpi4",   "ARCH": "aarch64", "FAN": "1", "OLED": "1", "SUFFIX": "-box"},
    {"PLATFORM": "v3-hdmi",     "BOARD": "rpi4",   "ARCH": "arm"},
    {"PLATFORM": "v3-hdmi",     "BOARD": "rpi4",   "ARCH": "arm",     "FAN": "1", "OLED": "1", "SUFFIX": "-box"},
    {"PLATFORM": "v4mini-hdmi", "BOARD": "rpi4",   "ARCH": "aarch64"},
    {"PLATFORM": "v4mini-hdmi", "BOARD": "rpi4",   "ARCH": "arm"},
    {"PLATFORM": "v4plus-hdmi", "BOARD": "rpi4",   "ARCH": "aarch64"},
    {"PLATFORM": "v4plus-hdmi", "BOARD": "rpi4",   "ARCH": "arm"},
]


# =====
def main() -> None:
    names: list[str] = []
    for t in _TARGETS:
        pairs = [f"{k}={v}" for (k, v) in t.items()]
        name = f"build/{'__'.join(pairs)}/done".replace("=", "_")
        for p in pairs:
            print(f"{name}: export {p}")
        print()
        names.append(name)
    print()
    print(f"ALL_TARGETS := {' '.join(names)}")


if __name__ == "__main__":
    main()
