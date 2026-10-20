# trial-and-error-images

A lab notebook for building custom **Fedora Atomic / bootc** OCI images.

This is a scratchpad, not a maintained product. It holds the successive
attempts at the **Halcyon** desktop image — Hyprland + Noctalia, NVIDIA open
drivers, a gaming stack, everything baked in so that rebasing lands you
straight in a working session — together with the dead ends, forks and
rewrites that got there. Each directory is a complete, self-contained
snapshot of one attempt, with its own README, LICENSE and CI. The images
themselves are published from the upstream repositories these attempts grew
out of; each subproject's README names the image it pushes.

## The attempts

| Directory | Build system | Base image | What it was | Status |
| --- | --- | --- | --- | --- |
| [`base-image-bluebuild/`](base-image-bluebuild/) | BlueBuild recipe | `ghcr.io/ublue-os/bazzite-nvidia-open` | The Halcyon family: **ceyx** (Hyprland + Noctalia) and its DE-free sibling **alcyone** | current |
| [`container-based/`](container-based/) | `Containerfile` | `quay.io/fedora/fedora-bootc` + p03 kernel | Halcyon rebuilt as a raw Containerfile, no BlueBuild | current |
| [`bazzite-base/`](bazzite-base/) | BlueBuild recipe + ISO | `ghcr.io/ublue-os/bazzite-gnome-nvidia-open` | The BlueBuild branch of Halcyon, plus an Anaconda installer ISO | current |
| [`bazzfin/`](bazzfin/) | BlueBuild recipe | `ghcr.io/ublue-os/base-main` (desktop-free) | Gaming-first Hyprland image on a DE-free base | in progress |
| [`bazzite-fork/`](bazzite-fork/) | `Containerfile` | `ghcr.io/ublue-os/base-main` (desktop-free) | Same DE-free base, but written as a plain Containerfile | earlier attempt |
| [`bazzite-hyprland/`](bazzite-hyprland/) | BlueBuild recipe | `ghcr.io/ublue-os/bazzite-gnome-nvidia-open` | The first GNOME → Hyprland conversion | earlier attempt |
| [`bak/`](bak/) | — | — | Frozen snapshots of earlier trees (`base-image.bak`, `bazzite-fork.bak`) | archive |

"Current" means the directory still carries a CI workflow that builds and
publishes an image; everything else is kept for reference and reuse.

### `base-image-bluebuild/` — Halcyon (BlueBuild)

The current shape of the project. Two images in one repo: **ceyx**, a lean
Hyprland + Noctalia gaming desktop on `bazzite-nvidia-open` where the gaming
stack (Steam, Lutris, Heroic) ships as native RPMs for maximum
Proton/Wine compatibility, and **alcyone**, its Containerfile-built DE-free
sibling. Everything is gated by per-module build-time verify scripts, with
`bootc-lint` as the no-cache backstop.

### `container-based/` — Halcyon (Containerfile)

The same image goal without BlueBuild: a hand-written `Containerfile` on
`quay.io/fedora/fedora-bootc`, the **p03** kernel with its *prebuilt*
NVIDIA-open modules (no akmods, no DKMS, and RPM Fusion's NVIDIA packages
excluded so the two driver chains can never mix), Hyprland + Noctalia with
greetd, and the Bazzite gaming stack as native RPMs. Verification lives in
`verify/`, shellcheck runs over `build_files/` in CI.

### `bazzite-base/` — Halcyon (BlueBuild, with ISO)

The BlueBuild branch of the same project, built from a `bazzite-gnome-open`
base with GNOME removed in favour of Hyprland + Noctalia and a
noctalia-greeter login. Adds a `build-iso` workflow that generates a
bootable Anaconda installer ISO from the published image, so the image can
be installed like a normal Fedora Workstation ISO.

### `bazzfin/` — gaming-first on a desktop-free base

Starts from Universal Blue's `base-main` — no desktop to take apart — and
adds the NVIDIA open driver, Hyprland, the OGC gaming kernel, sched-ext
schedulers, Wine/Proton tooling, gaming Flatpaks and a small GTK3 portal app
(`bazzfin-portal`) that wires all of it into one window.

### `bazzite-fork/` — the same idea, hand-written

The DE-free base with the plain bash + `Containerfile` structure of
`ublue-os/bazzite`, but without BlueBuild. Useful as the reference for what
BlueBuild's declarative modules actually do.

### `bazzite-hyprland/` — where the Hyprland conversion started

The first pass at stripping Bazzite's GNOME image down to Hyprland, and the
richest source of ideas that later attempts reused: Chezmoi dotfiles, Nix and
Home-Manager, TeX Live, the `ujust` recipe layout, and the
`--setopt=install_weak_deps=False` discipline for every dnf layer.

## Anatomy of an attempt

Every attempt follows the same shape, which is why they can be compared
side by side:

1. **Base** — a Universal Blue image (`base-main`, `bazzite-nvidia-open`) or
   plain `quay.io/fedora/fedora-bootc`.
2. **Packages** — dnf layers where COPR repos are enabled for the install
   and removed again afterwards, weak dependencies off, and the NVIDIA
   packages kept on exactly one track (akmods, or prebuilt modules, never
   both).
3. **Overlay** — `/etc`, `/usr/lib/systemd`, `/usr/share` staged from
   `files/` (BlueBuild) or `system_files/` (Containerfile).
4. **Verification** — build-time `verify-*.sh` scripts that fail the build
   when a module did not land.
5. **Signing** — Cosign in the legacy `.sig` attachment format, the only one
   `bootc` can discover, with `cosign.pub` shipped inside the image.
6. **Rebase** — `rpm-ostree rebase` or `bootc switch` onto the published tag.

## Upstream

- [Universal Blue](https://universal-blue.org) — the `base-main` and
  `bazzite` images, `ujust` and `uupd`
- [BlueBuild](https://blue-build.org) — the declarative recipe runner
- [Fedora bootc / Atomic Desktops](https://fedoraproject.org/wiki/Changes/OstreeNativeContainerStable)
- [Bazzite](https://bazzite.gg) — the build structure several of these
  attempts fork
- [Cosign](https://github.com/sigstore/cosign) — image signing
- [p03 kernel](https://github.com/CatPieLeaf/linux-p03) — the kernel used by
  the Containerfile attempts

## License

Apache-2.0, see [LICENSE](LICENSE). Each subdirectory keeps its own license
file; several of them fork the `ublue-os/bazzite` build structure, which is
Apache-2.0 as well.
