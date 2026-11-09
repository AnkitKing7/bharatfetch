<div align="center">

<img src="bharatfetch.png" alt="BharatFetch" width="720">

```
  ██████╗ ██╗  ██╗ █████╗ ██████╗  █████╗ ████████╗
  ██╔══██╗██║  ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝
  ██████╔╝███████║███████║██████╔╝███████║   ██║
  ██╔══██╗██╔══██║██╔══██║██╔══██╗██╔══██║   ██║
  ██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║   ██║
  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
        सत्यमेव जयते  •  Satyameva Jayate
```

**An India-themed, neofetch-style system info tool for Linux servers.**
Animated tricolor flag, live resource bars, network, security and Docker details, all in pure Bash.

![shell](https://img.shields.io/badge/shell-bash-138808)
![platform](https://img.shields.io/badge/platform-Debian%20%7C%20Ubuntu-FF9933)
![deps](https://img.shields.io/badge/dependencies-none%20required-000080)

**🇮🇳 Jai Hind! Jai Bharat! 🇮🇳**

</div>

---

## Table of contents

1. [Features](#features)
2. [Flag art](#flag-art)
   - [Login banner (MOTD)](#login-banner-motd)
3. [Quick install](#quick-install)
4. [Usage](#usage)
5. [Sample output](#sample-output)
6. [What each field means](#what-each-field-means)
7. [`--full` sections](#--full-sections)
8. [Customization](#customization)
9. [Files and layout](#files-and-layout)
10. [Troubleshooting](#troubleshooting)
11. [Privacy and network use](#privacy-and-network-use)
12. [Uninstall](#uninstall)
13. [FAQ](#faq)
14. [License](#license)

---

## Features

| Area | What you get |
|---|---|
| **Visuals** | Big BHARAT banner, tricolor flag with Ashoka Chakra, waving animation, info lines revealed one by one |
| **Resources** | Live CPU % (sampled over 0.3 s), RAM, swap and disk with color bars (green, orange, red) |
| **Network** | Interface, RX/TX totals, local IP, public IP, city, country and ISP (cached 10 minutes) |
| **Security** | UFW status, failed SSH logins in the last 24 hours, listening ports, failed systemd units |
| **System** | OS, host, kernel, uptime, packages, shell, virtualization, GPU, temperature, load average |
| **Ops** | Docker container counts, pending apt updates, reboot-required flag, last SSH login |
| **India touch** | IST clock, time-based greeting (Suprabhat, Namaste, Shubh Sandhya, Shubh Ratri), random Sanskrit quote |
| **Modes** | Animated, `--static`, `--full` |

---

## Flag art

### Terminal flag (what the script draws)

The real script draws this in color and waves it by shifting rows sideways.

```
 ┃██████████████████████████████████   ← saffron  (#FF9933)
 ┃██████████████████████████████████
 ┃██████████████████████████████████
 ┃██████████████████████████████████
 ┃██████████████████████████████████
 ┃░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   ← white
 ┃░░░░░░░░░░░░░╲ │ ╱░░░░░░░░░░░░░░░░
 ┃░░░░░░░░░░░░── ◉ ──░░░░░░░░░░░░░░░   ← Ashoka Chakra
 ┃░░░░░░░░░░░░░╱ │ ╲░░░░░░░░░░░░░░░░
 ┃░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 ┃▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   ← green   (#138808)
 ┃▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
 ┃▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
 ┃▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
 ┃▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
```

### Wave animation frames

Each row is shifted by 0 to 3 columns using the pattern `0 1 2 3 3 2 1 0`, and the pattern advances every frame (30 frames, 0.07 s each).

```
 Frame 0            Frame 3            Frame 6
 ┃████████          ┃      ████████    ┃   ████████
 ┃ ████████         ┃     ████████     ┃  ████████
 ┃  ████████        ┃    ████████      ┃ ████████
 ┃   ████████       ┃   ████████       ┃████████
 ┃   ░░░░░░░░       ┃   ░░░░░░░░       ┃  ░░░░░░░░
 ┃  ░░░░░░░░        ┃    ░░░░░░░░      ┃   ░░░░░░░░
```

### Ashoka Chakra (24 spokes)

The PNG and SVG logos draw the full 24-spoke wheel. The terminal version uses a compact form.

```
            ,-~"~-.
         ,'  \ | /  `.
        / ‐ ‐ \|/ ‐ ‐ \
       |  ── ──◉── ──  |
        \ ‐ ‐ /|\ ‐ ‐ /
         `.  / | \  ,'
            `-.,_,.-'
```

### Color palette

| Color | Hex | 256-color code | Used for |
|---|---|---|---|
| Saffron | `#FF9933` | `208` | Top band, labels, banner |
| White | `#FFFFFF` | `255` | Middle band |
| Green | `#138808` | `28` / `34` | Bottom band, banner |
| Navy blue | `#000080` | `18` | Chakra |

---

## Login banner (MOTD)

`install.sh` now also installs **`bharatmini`**, a compact, fast, non-animated banner that is shown automatically **every time you log in over SSH**. It is built for small screens: 13 lines, about 78 columns wide.

```
                                Namaste, root @ powerdev0050-vps-2
                                ────────────────────────────────────────────
         ▄▄▄▄▄▄▄▄▄▄▄▄           OS     Ubuntu 22.04.5 LTS
      ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄       Kernel 7.0.0 · up 21m
    ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄     CPU    █░░░░░░░░░   5% 4c · load 0.05
   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    RAM    █░░░░░░░░░   1% 219Mi/15Gi
  ░░░░░░░╲ │ ╱░░░░░░░░░░░░░░░    Disk   █░░░░░░░░░   6% 4.2G/77G
  ░░░░ ─ ─╲│╱─ ─ ░░░░░░░░░░░     Net    eth0 ↓1.2G ↑340M
  ░░░░────( ◉ )────░░░░░░░░░    IP     10.0.0.5 · pub 203.0.113.7
  ░░░░ ─ ─╱│╲─ ─ ░░░░░░░░░░░    Secure fw active · ssh-fail 12 · ports 5
  ░░░░░░░╱ │ ╲░░░░░░░░░░░░░░    System updates 0 · failed 0 · docker 2/3
    ████████████████████████    Last   root from 1.2.3.4 (Sun Nov 8)
      ████████████████████      Time   Sun 08 Nov, 11:14 PM IST
         ████████████

  bharatfetch   Jai Hind !   सत्यमेव जयते
```

The circle is a tricolor "sun": saffron on top, white in the middle with the Ashoka Chakra, green at the bottom (drawn in real colors in the terminal).

**How it works**

| Part | Detail |
|---|---|
| Ubuntu | `/etc/update-motd.d/99-bharatfetch` runs `bharatmini` through `pam_motd` at every SSH login |
| Debian and others | falls back to `/etc/profile.d/99-bharatfetch.sh` for interactive login shells |
| Default Ubuntu noise | `10-help-text`, `50-motd-news` and similar are switched off (list saved, restored on uninstall). Keep them with `--keep-default-motd` |
| Speed | slow data (public IP, apt updates, failed SSH logins, UFW) is cached in `/var/cache/bharatfetch/stats` and refreshed in the background every 30 minutes, so login is never blocked |
| Manual run | `bharatmini` prints the same banner any time |

```bash
sudo bash install.sh                       # install + enable on login
sudo bash install.sh --keep-default-motd   # keep Ubuntu's own MOTD too
sudo bash install.sh --uninstall           # remove and restore default MOTD
```

To test without logging out: `bharatmini`, or `sudo run-parts /etc/update-motd.d/` (Ubuntu).

**Want it even smaller?** Open `/usr/local/bin/bharatmini` and delete lines from the `info=( ... )` array, then change `seq 0 12` to the new count minus one. The art can be hidden by replacing `${art[i]}` with an empty string.

---

## Quick install

**One command (as root or with sudo):**

```bash
sudo bash install.sh
```

**Step by step:**

```bash
# 1. Upload the installer to your VPS
scp install.sh root@YOUR_VPS_IP:~/

# 2. Log in and run it
ssh root@YOUR_VPS_IP
bash install.sh

# 3. Try it
bharatfetch
```

The installer:

1. Installs helper packages: `pciutils iproute2 procps curl net-tools util-linux` (skipped quietly if apt is not available or offline).
2. Writes `bharatfetch` (full) and `bharatmini` (compact) to `/usr/local/bin/`.
3. Writes the SVG and PNG logos to `/usr/share/bharatfetch/`.
4. Enables the compact banner on every SSH login through MOTD (see [Login banner](#login-banner-motd)).
5. Warms the cache and shows a preview.

### Manual install (no installer)

```bash
sudo cp bharatfetch /usr/local/bin/bharatfetch
sudo chmod +x /usr/local/bin/bharatfetch
bharatfetch
```

---

## Usage

```bash
bharatfetch                    # animated flag + info
bharatfetch --static           # no animation (best for login and slow links)
bharatfetch --full             # flag + every detail section
bharatfetch --static --full    # all details, no animation
bharatfetch --help             # show options
```

| Flag | Effect |
|---|---|
| *(none)* | Waving flag, info reveals line by line |
| `--static` | Prints once, no animation |
| `--full` | Adds the detailed sections listed below |
| `-h`, `--help` | Prints usage |

Animation is turned off automatically when output is piped or redirected, or when the terminal is narrower than 105 columns.

**Show on every login:** the installer already does this through MOTD. For a user without MOTD access you can use:

```bash
echo 'bharatmini' >> ~/.bashrc
```

---

## Sample output

Colors are shown in your terminal. This is the plain-text shape.

```
  ██████╗ ██╗  ██╗ █████╗ ██████╗  █████╗ ████████╗
  ██╔══██╗██║  ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝
  ██████╔╝███████║███████║██████╔╝███████║   ██║
  ██╔══██╗██╔══██║██╔══██║██╔══██╗██╔══██║   ██║
  ██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║   ██║
  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
  सत्यमेव जयते  •  Satyameva Jayate

                                          Namaste, root!  @powerdev0050-vps-2
                                          ──────────────────────────────────────────────
                                          ▸ OS         Ubuntu 22.04.5 LTS
                                          ▸ Host       m8a.xlarge
                                          ▸ Kernel     7.0.0
                                          ▸ Uptime     21 minutes
                                          ▸ Packages   735 (dpkg)   updates: 0
                                          ▸ Shell      bash   virt: kvm
 ┃ [saffron]                              ▸ CPU        AMD EPYC (4 cores)
 ┃ [saffron]                              ▸ CPU Use    █░░░░░░░░░░░░░░░░░░░ 5%
 ┃ [saffron]                              ▸ GPU        None / virtual
 ┃ [white]                                ▸ Load       0.05, 0.03, 0.01
 ┃ [white]      ╲ │ ╱                     ▸ Memory     219M / 16000M
 ┃ [white]     ── ◉ ──                    ▸            █░░░░░░░░░░░░░░░░░░░ 1%
 ┃ [white]      ╱ │ ╲                     ▸ Swap       0M / 0M  ░░░░░░░░░░░░░░░░░░░░ 0%
 ┃ [green]                                ▸ Disk       4.2G / 77G
 ┃ [green]                                ▸            █░░░░░░░░░░░░░░░░░░░ 6%
 ┃ [green]                                ▸ Network    eth0  ↓ 1.2 GB  ↑ 340 MB
                                          ▸ Local IP   10.0.0.5
                                          ▸ Public IP  203.0.113.7  Mumbai, IN
                                          ▸ Firewall   active   ssh fails 24h: 12
                                          ▸ Docker     2 running / 3 total
                                          ▸ Time       Sun, 08 Nov 2026  11:14 PM IST
                                          🇮🇳  Jai Hind!  Jai Bharat!

  वसुधैव कुटुम्बकम् — the world is one family
```

> Values above are illustrative. Your machine will show its own data.

---

## What each field means

| Field | Source |
|---|---|
| OS | `/etc/os-release` |
| Host | `/sys/devices/virtual/dmi/id/product_name` |
| Kernel | `uname -r` |
| Uptime | `uptime -p` |
| Packages | count of `dpkg -l` entries with status `ii` |
| updates | `apt list --upgradable` |
| virt | `systemd-detect-virt` |
| CPU / CPU Use | `/proc/cpuinfo`, two samples of `/proc/stat` 0.3 s apart |
| GPU | `nvidia-smi`, else `lspci` (VGA, 3D, Display) |
| Load | `/proc/loadavg` (1, 5, 15 min) |
| Memory / Swap | `free -m` |
| Disk | `df -h /` |
| Network | default-route interface and `/sys/class/net/<if>/statistics` |
| Public IP / ISP | `https://ipinfo.io/json` (cached) |
| Ports | `ss -tuln` count |
| Firewall | `ufw status` |
| ssh fails 24h | `journalctl` for `Failed password` in ssh or sshd units |
| Docker | `docker ps` and `docker ps -a` (needs permission to the Docker socket) |
| Time | `Asia/Kolkata` timezone |

Bar colors: **green** below 60 %, **orange** from 60 to 84 %, **red** at 85 % and above.

---

## `--full` sections

| Section | Contents |
|---|---|
| **HARDWARE** | CPU model, cores and threads, MHz, L2/L3 cache, architecture, RAM breakdown, GPU, board and BIOS version |
| **DISKS** | All real filesystems with type, size, used, free, mount, plus `lsblk` tree |
| **NETWORK** | Every interface and address, gateway, DNS servers, public IP and ISP, IPv6, established TCP connections |
| **LISTENING PORTS** | Protocol, bind address and owning process (top 15) |
| **TOP PROCESSES** | Top 5 by CPU and top 5 by memory |
| **USERS & LOGINS** | Current sessions, last 5 logins, failed SSH count, sudo group members |
| **SECURITY** | UFW, fail2ban, SSH `PermitRootLogin`, `PasswordAuthentication`, SSH port, pending updates, failed units |
| **DOCKER** | Version, image count, running containers with image and status |
| **SYSTEM** | Hostname (FQDN), timezone, boot time, uptime, load vs cores, zombie count, open files, entropy, locale |

Some fields need root (for example `sshd -T`, `journalctl`, `ss -p`). Run with `sudo` for the complete picture.

---

## Customization

Open `/usr/local/bin/bharatfetch` and edit:

| Want to change | Where |
|---|---|
| Colors | Variables at the top: `S` (saffron), `G` (green), `WH` (white), `DM` (dim) |
| Flag size | `FW` (width) and `FH` (height) |
| Wave shape | `OFF=(0 1 2 3 3 2 1 0)` |
| Wave speed | `sleep 0.07` in the animation loop |
| Animation length | `FR=30` (frames) |
| Chakra art | `CH=(...)` array |
| Quotes | `QUOTES=(...)` array near the end |
| Timezone | `TZ=Asia/Kolkata` (two places) |
| Greeting hours | the `HR` conditions |
| Public IP check | delete the `curl ... ipinfo.io` block |

Add your own line by appending to the `info=( ... )` array:

```bash
"$(lab 'My Label')my value"
```

---

## Files and layout

```
.
├── install.sh          # one-shot installer (embeds everything below)
├── bharatfetch         # full script (animated, --full)
├── bharatmini          # compact login banner (MOTD)
├── bharatfetch.svg     # vector logo (24-spoke chakra)
├── bharatfetch.png     # 1200x630 logo / social preview
└── README.md
```

Installed locations:

```
/usr/local/bin/bharatfetch
/usr/local/bin/bharatmini
/etc/update-motd.d/99-bharatfetch      # Ubuntu login hook
/etc/profile.d/99-bharatfetch.sh       # fallback on non-Ubuntu
/usr/share/bharatfetch/bharatfetch.svg
/usr/share/bharatfetch/bharatfetch.png
/var/cache/bharatfetch/stats           # cached slow data (30 min)
/var/lib/bharatfetch/disabled-motd.list # restored on uninstall
/tmp/.bharatfetch_net.<uid>            # 10 minute public-IP cache (bharatfetch)
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `bharatfetch: command not found` | Check `ls -l /usr/local/bin/bharatfetch`. Make sure `/usr/local/bin` is in `$PATH`. Re-run the installer. |
| No animation | Terminal is under 105 columns, output is piped, or `--static` is set. Widen the window or zoom out. |
| Boxes instead of `◉ ╲ ╱ █` | Use a UTF-8 terminal and a font with box-drawing glyphs (for example DejaVu Sans Mono). |
| Flag colors look wrong | Needs a 256-color terminal. Try `export TERM=xterm-256color`. |
| Hindi text garbled | Set `export LANG=C.UTF-8` or `en_IN.UTF-8`. |
| `GPU: None / virtual` | Normal on most VPS. Install `pciutils` for PCI detection. |
| `Public IP: offline` | No internet or ipinfo.io blocked. Not an error. |
| `ssh fails 24h: 0` but you expect more | Needs root and `journalctl`. Some distros log to `/var/log/auth.log` instead. |
| Docker shows "not installed / not running" | Docker missing, stopped, or your user is not in the `docker` group. |
| Empty SSH settings in `--full` | Run with `sudo` and make sure `openssh-server` is installed. |
| Banner not shown at login | Ubuntu: check `ls -l /etc/update-motd.d/99-bharatfetch` is executable and `grep pam_motd /etc/pam.d/sshd` exists. Debian: log in again so `/etc/profile.d` is read. |
| Banner shows twice | Remove old `bharatfetch` lines from `~/.bashrc` (`sed -i '/bharatfetch/d' ~/.bashrc`). |
| `pub ...` or `updates -` at first login | Cache is still warming. It fills in within a few seconds. Run `sudo bharatmini --refresh`. |
| Slow login | The compact banner does not make network calls at login. If it is still slow, check DNS and `last`/`journalctl` speed. |

---

## Privacy and network use

- The only outbound request is to **`https://ipinfo.io/json`** (2 to 3 second timeout, in the background for the login banner) to show your public IP, city and ISP. The response is cached in `/tmp/.bharatfetch_net.<uid>` for 10 minutes.
- To make the tool fully offline, delete the block starting with `CF=/tmp/.bharatfetch_net.$UID` through the `jget` lines and set `PIP=offline`.
- Nothing is written anywhere else and nothing is sent to the project author.
- The `--full` output includes IPs, usernames and open ports. Do not paste it publicly without redacting.

---

## Uninstall

```bash
sudo bash install.sh --uninstall
```

This removes both commands, the logos, the MOTD hook and the cache, and **restores the default Ubuntu MOTD**.

Manual removal:

```bash
sudo rm -f /usr/local/bin/bharatfetch /usr/local/bin/bharatmini /etc/update-motd.d/99-bharatfetch
sudo rm -rf /usr/share/bharatfetch /var/cache/bharatfetch
sudo chmod +x /etc/update-motd.d/*   # re-enable default MOTD scripts
sed -i '/# bharatfetch-login/d' ~/.bashrc
```

---

## FAQ

**Does it work on CentOS, Fedora or Arch?**
The visuals and most fields do. The package count and update check use `dpkg` and `apt`, so they will show 0 or be empty on non-Debian systems.

**Can I use it for a normal (non-root) user?**
Yes. Copy the script to `/usr/local/bin` and add the login line to that user's `~/.bashrc`. Some `--full` fields will be limited without root.

**Is it safe to run on production?**
It only reads system information. The 0.3 second CPU sample and a few short commands are the only load.

**Why is the flag skewed or cut off?**
Window is too narrow. The animated layout needs about 105 columns. Use `--static` or widen the window.

**Can I change the language of the greeting?**
Yes. Edit the `GR=` assignments and the `QUOTES` array.

**Can I use the logo?**
Yes, the SVG and PNG are free to use with the same license as the project.

---

## License

MIT. Use it, change it, share it.

```
Copyright (c) 2026 BharatFetch contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files, to deal in the Software
without restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of the
Software, subject to the above copyright notice and this permission notice
being included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
```

<div align="center">

**🇮🇳 Made with ❤️ in Bharat. Jai Hind! 🇮🇳**

</div>
