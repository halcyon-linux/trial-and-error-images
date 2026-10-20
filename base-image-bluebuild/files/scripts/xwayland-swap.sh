#!/usr/bin/env bash
# halcyon build step — hand the Xwayland provider back to Fedora.
#
# _why_: bazzite's build swapped the base's xorg-x11-server-Xwayland for
# terra-xorg-x11-server-Xwayland (ublue-os/bazzite 3c3911ee, 2026-10-08), but
# Terra's build only provides the UNQUALIFIED name (Provides:
# xorg-x11-server-Xwayland = 26.0.99.903). hyprland-git hard-requires the
# arch-qualified xorg-x11-server-Xwayland(x86-64) (spec %{?_isa}) — only a
# package NAMED xorg-x11-server-Xwayland self-provides that — so every build
# from the 2026-10-12 base on died in the desktop transaction (CI runs
# 38286020810 onward). Fedora's copy cannot be installed while Terra's is
# present (Conflicts), and a plain `dnf remove` is NOT an option —
# terra-gamescope and the gamescope sessions require the plain name and would
# be dragged out as dependents — so swap both sides in ONE transaction; the
# dependents' requires carry over to Fedora's package. No-op on a base that
# already ships Fedora's copy.
set -euo pipefail

echo "::group::xwayland-swap"

if rpm -q terra-xorg-x11-server-Xwayland >/dev/null 2>&1; then
  echo "  OK    terra Xwayland found — swapping to Fedora's in one transaction"
  dnf5 -y swap --allowerasing --setopt=install_weak_deps=False \
    terra-xorg-x11-server-Xwayland xorg-x11-server-Xwayland
else
  echo "  OK    no terra Xwayland present — nothing to swap"
fi

# Gate the swap's contract, not just the command's exit — a silent no-op
# (e.g. a base that ships neither package) must fail the build here.
if rpm -q terra-xorg-x11-server-Xwayland >/dev/null 2>&1; then
  echo "  FAIL  terra Xwayland survived the swap" >&2
  exit 1
fi
if ! rpm -q xorg-x11-server-Xwayland >/dev/null 2>&1; then
  echo "  FAIL  xorg-x11-server-Xwayland absent after the swap" >&2
  exit 1
fi
echo "  OK    Xwayland provider: $(rpm -q xorg-x11-server-Xwayland)"

echo "::endgroup::"
echo "--- xwayland-swap complete ---"
