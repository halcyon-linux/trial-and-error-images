# Halcyon — ceyx

**ceyx** is one of the two Halcyon images: a lean Hyprland gaming-desktop OCI
image built with [BlueBuild](https://blue-build.org) on
`ghcr.io/ublue-os/bazzite-nvidia-open:latest`. The sibling image, **alcyone**,
is the Containerfile-built variant (see the `containerfile` branch) and ships
DE-free with no compositor.

- Hyprland + Noctalia on the Bazzite base (KDE Plasma removed), zsh as the
  default shell (`/etc/default/useradd` for new accounts; accounts rebased
  from an older OS are adopted into zsh automatically at first boot), login
  via getty@tty2 (a display manager — ly — is planned)
- Bazzite's kernel and NVIDIA open driver stack, inherited untouched
- Native gaming stack, no Flatpak: Steam, Lutris and Heroic Launcher install
  as RPMs for maximum Proton/Wine compatibility (RakuOS model), plus
  gamescope, mangohud, gamemode, umu, scx schedulers and the base's
  `bazzite-steam` wrapper
- GNOME file stack instead of KDE's: nautilus + file-roller
- Curated font set (JetBrainsMono, Nerd Fonts, Noto Color Emoji) over a
  dnf-swept base font payload (fonts that other packages pull back as deps
  are fine); GUI GPG prompts via pinentry-gnome3; gnome-keyring SSH
  agent; openssh-clients wired
- GRUB menu visible for 10 seconds (rebasing machines: `ujust regenerate-grub`)
- `ujust` tooling (`ujust --list`), `uupd` system updates, Nix + home-manager ready
- Curated dev tooling; every module is gated by build-time verify scripts

## Halcyon family

| Image     | Built with   | Desktop             | Rebase target                             |
| --------- | ------------ | ------------------- | ----------------------------------------- |
| `ceyx`    | BlueBuild    | Hyprland + Noctalia | `ghcr.io/halcyon-linux/ceyx:latest`       |
| `alcyone` | Containerfile | none (DE-free)      | `ghcr.io/halcyon-linux/alcyone:stable`    |

Both images report `NAME="Halcyon"` in `/etc/os-release`; `VARIANT_ID`
distinguishes them (`ceyx` or `alcyone`).

## Install / rebase

> [!WARNING]
> [bootc images are an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable) — try at your own discretion.

Rebase an existing Fedora atomic system (bootc or rpm-ostree):

```bash
sudo bootc switch ghcr.io/halcyon-linux/ceyx:latest
```

or, on an rpm-ostree system:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/halcyon-linux/ceyx:latest
```

Reboot to apply. The image ships its own sigstore policy and public key, so
`bootc switch --enforce-container-sigpolicy` verifies the signature baked into
the image (`cosign.pub` at the repo root, staged as
`/etc/pki/containers/ceyx.pub`) from the first update on. A
`rebase-to-custom` ujust recipe wraps the same flow.

## Updating

The image is rebuilt on every push to `bluebuild` plus a daily schedule (see
`.github/workflows/build.yml`) and published to
`ghcr.io/halcyon-linux/ceyx:latest`. Once you are booted into ceyx,
updates are automatic: the image ships `uupd` with its timer enabled, which
stages a new deployment in the background whenever a newer image is
published and prompts you to reboot.

To update manually:

```bash
sudo bootc upgrade          # fetch + stage the new deployment (alias: bootc update)
sudo systemctl reboot       # boot into it
```

or let bootc do both: `sudo bootc upgrade --apply`. Only the changed layers
are downloaded, and every update is signature-verified by the baked
`policy.json` — no extra flags needed. `bootc status` shows the running and
staged deployments. On a machine that was rebased from rpm-ostree, the
equivalent is `rpm-ostree upgrade` followed by a reboot.

## Verification

Images are signed with [cosign](https://github.com/sigstore/cosign) in the
legacy attachment format that bootc's client-side policy can verify:

```bash
cosign verify --key cosign.pub ghcr.io/halcyon-linux/ceyx
```

## Build

Builds run in CI via [BlueBuild](https://blue-build.org) (see
`.github/workflows/build.yml`): the recipe (`recipes/ceyx.yml`) is validated,
built with the pinned BlueBuild CLI, verified end-state (`final-verify`) and
with `bootc container lint`, then pushed and signed. Architecture rules and
the per-module verification gates are documented in [AGENTS.md](AGENTS.md).
