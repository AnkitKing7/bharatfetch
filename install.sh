#!/bin/bash
# BharatFetch installer
# usage: sudo bash install.sh [--keep-default-motd] [--uninstall]
set -e
BIN=/usr/local/bin/bharatfetch
MINI=/usr/local/bin/bharatmini
SHARE=/usr/share/bharatfetch
STATE=/var/lib/bharatfetch
HOOK=/etc/update-motd.d/99-bharatfetch
PROF=/etc/profile.d/99-bharatfetch.sh

[ "$(id -u)" -eq 0 ] || { echo "Run as root: sudo bash install.sh"; exit 1; }

if [ "$1" = "--uninstall" ]; then
  if [ -f "$STATE/disabled-motd.list" ]; then
    while read -r f; do [ -f "$f" ] && chmod +x "$f"; done < "$STATE/disabled-motd.list"
  fi
  rm -f "$BIN" "$MINI" "$HOOK" "$PROF"
  rm -rf "$SHARE" "$STATE" /var/cache/bharatfetch
  sed -i '/# bharatfetch-login/d' /root/.bashrc 2>/dev/null || true
  for h in /home/*; do sed -i '/# bharatfetch-login/d' "$h/.bashrc" 2>/dev/null || true; done
  echo "BharatFetch removed. Default MOTD restored."; exit 0
fi

KEEP_DEFAULT=0; [ "$1" = "--keep-default-motd" ] && KEEP_DEFAULT=1

echo "[1/5] Installing dependencies..."
if command -v apt-get >/dev/null; then
  apt-get update -qq >/dev/null 2>&1 || true
  apt-get install -y -qq pciutils iproute2 procps curl net-tools util-linux >/dev/null 2>&1 \
    || echo "  (some packages could not be installed, continuing)"
fi

echo "[2/5] Installing commands: bharatfetch (full) and bharatmini (compact)..."
cat > "$BIN" <<'BHARAT_EOF'
#!/bin/bash
# bharatfetch - India themed system info tool
export LC_ALL=C.UTF-8
ANIM=1; FULL=0
for a in "$@"; do case "$a" in --static) ANIM=0;; --full) FULL=1;; --help|-h) echo "bharatfetch [--static] [--full]"; exit 0;; esac; done
[ ! -t 1 ] && ANIM=0
R=$'\e[0m'; BD=$'\e[1m'
S=$'\e[38;5;208m'; G=$'\e[38;5;34m'; WH=$'\e[97m'; DM=$'\e[38;5;245m'
FW=34; FH=15
OFF=(0 1 2 3 3 2 1 0)
CH=('' '╲ │ ╱' '── ◉ ──' '╱ │ ╲' '')
trap 'printf "\e[?25h"' EXIT

center(){ local s="$1" l=${#1} a b; a=$(((FW-l)/2)); b=$((FW-l-a)); printf '%*s%s%*s' $a '' "$s" $b ''; }
lab(){ printf '%s▸ %-11s%s' "$S$BD" "$1" "$R"; }
bar(){
  local p=$1 f i col; f=$((p*20/100))
  if ((p>=85)); then col=196; elif ((p>=60)); then col=214; else col=40; fi
  printf '\e[38;5;%sm' "$col"
  for ((i=0;i<20;i++)); do ((i<f)) && printf '█' || printf '\e[38;5;240m░'; done
  printf '%s %d%%' "$R" "$p"
}
hb(){ awk -v b="$1" 'BEGIN{split("B KB MB GB TB",u," ");i=1;while(b>=1024&&i<5){b/=1024;i++}printf "%.1f %s",b,u[i]}'; }
cpu_usage(){
  local u1 n1 s1 i1 w1 q1 sq1 u2 n2 s2 i2 w2 q2 sq2 dt di
  read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat; sleep 0.3
  read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
  dt=$(( (u2+n2+s2+i2+w2+q2+sq2)-(u1+n1+s1+i1+w1+q1+sq1) ))
  di=$(( (i2+w2)-(i1+w1) ))
  echo $(( dt>0 ? (dt-di)*100/dt : 0 ))
}

banner(){
  local L=(
"██████╗ ██╗  ██╗ █████╗ ██████╗  █████╗ ████████╗"
"██╔══██╗██║  ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝"
"██████╔╝███████║███████║██████╔╝███████║   ██║   "
"██╔══██╗██╔══██║██╔══██║██╔══██╗██╔══██║   ██║   "
"██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║   ██║   "
"╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ")
  local C=("$S" "$S" "$WH" "$WH" "$G" "$G") i
  echo
  for i in 0 1 2 3 4 5; do printf '  %s%s%s\n' "${C[i]}$BD" "${L[i]}" "$R"; done
  printf '  %s%s%s\n\n' "$DM" "सत्यमेव जयते  •  Satyameva Jayate" "$R"
}

# ---------- Gather ----------
OS=$(. /etc/os-release; echo "$PRETTY_NAME")
HOST=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null); HOST=${HOST:-Unknown}
CPU=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
CORES=$(nproc)
CPCT=$(cpu_usage)
if command -v nvidia-smi >/dev/null; then GPU=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)
elif command -v lspci >/dev/null; then GPU=$(lspci | grep -iE 'vga|3d|display' | head -1 | cut -d: -f3- | xargs); fi
GPU=${GPU:-None / virtual}
read -r MT MU <<<"$(free -m | awk '/Mem:/{print $2,$3}')"
read -r ST SU <<<"$(free -m | awk '/Swap:/{print $2,$3}')"
MP=$((MU*100/MT)); SP=0; ((ST>0)) && SP=$((SU*100/ST))
DP=$(df / --output=pcent | tail -1 | tr -dc 0-9)
DISK=$(df -h / | awk 'NR==2{print $3" / "$2}')
LOAD=$(awk '{print $1", "$2", "$3}' /proc/loadavg)
PROCS=$(ps -e --no-headers | wc -l)
USERS=$(who | wc -l)
PKG=$(dpkg -l 2>/dev/null | grep -c '^ii')
VIRT=$(systemd-detect-virt 2>/dev/null || echo none)
FAILED=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
PORTS=$(ss -tuln 2>/dev/null | tail -n +2 | wc -l)
TOP=$(ps -eo comm,%cpu --sort=-%cpu --no-headers | head -3 | awk '{printf "%s(%s%%) ",$1,$2}')
TEMP=""; [ -r /sys/class/thermal/thermal_zone0/temp ] && TEMP="$(( $(cat /sys/class/thermal/thermal_zone0/temp)/1000 ))°C"
IF=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
RX=$(cat /sys/class/net/$IF/statistics/rx_bytes 2>/dev/null || echo 0)
TX=$(cat /sys/class/net/$IF/statistics/tx_bytes 2>/dev/null || echo 0)
LIP=$(hostname -I 2>/dev/null | awk '{print $1}')

# Docker
if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
  DK="$(docker ps -q | wc -l) running / $(docker ps -aq | wc -l) total"
else DK="not installed / not running"; fi

# Firewall
if command -v ufw >/dev/null; then FW_S=$(ufw status 2>/dev/null | head -1 | sed 's/Status: //'); FW_S=${FW_S:-unknown}
else FW_S="ufw n/a"; fi

# Updates
UPD=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
[ -f /var/run/reboot-required ] && RB="${S}reboot needed${R}" || RB="no reboot needed"

# SSH logins
LAST=$(last -n 3 -a -w 2>/dev/null | grep -v -E '^(reboot|wtmp|$)' | head -3 | awk '{print $1" from "$NF" ("$4" "$5" "$6")"}')
FAILSSH=$(journalctl -u ssh -u sshd --since "24 hours ago" --no-pager 2>/dev/null | grep -c "Failed password")

# Public IP (cached 10 min)
CF=/tmp/.bharatfetch_net.$UID
if [[ ! -s $CF || $(( $(date +%s)-$(stat -c %Y "$CF") )) -gt 600 ]]; then
  curl -s --max-time 2 https://ipinfo.io/json > "$CF" 2>/dev/null; [ -s "$CF" ] || rm -f "$CF"
fi
jget(){ grep -o "\"$1\": *\"[^\"]*\"" "$CF" 2>/dev/null | head -1 | sed 's/.*: *"\(.*\)"/\1/'; }
PIP=$(jget ip); PIP=${PIP:-offline}
GEO=""; [ "$PIP" != "offline" ] && GEO="$(jget city), $(jget country)"; ORG=$(jget org)

HR=$(TZ=Asia/Kolkata date +%H); HR=$((10#$HR))
if ((HR<12)); then GR="Suprabhat"; elif ((HR<17)); then GR="Namaste"; elif ((HR<21)); then GR="Shubh Sandhya"; else GR="Shubh Ratri"; fi
NOW=$(TZ=Asia/Kolkata date '+%a, %d %b %Y  %I:%M %p IST')

info=(
"$S$BD$GR, $(whoami)!$R  $DM@$(hostname)$R"
"$DM──────────────────────────────────────────────$R"
"$(lab OS)$OS"
"$(lab Host)$HOST"
"$(lab Kernel)$(uname -r)"
"$(lab Uptime)$(uptime -p | sed 's/up //')"
"$(lab Packages)$PKG (dpkg)   ${DM}updates:$R $UPD"
"$(lab Shell)$(basename "$SHELL")   ${DM}virt:$R $VIRT"
"$(lab CPU)$CPU ($CORES cores)"
"$(lab 'CPU Use')$(bar $CPCT)"
"$(lab GPU)$GPU"
"$(lab Load)$LOAD"
"$(lab Memory)${MU}M / ${MT}M"
"$(lab '')$(bar $MP)"
"$(lab Swap)${SU}M / ${ST}M  $(bar $SP)"
"$(lab Disk)$DISK"
"$(lab '')$(bar $DP)"
"$(lab Network)${IF:-n/a}  ↓ $(hb $RX)  ↑ $(hb $TX)"
"$(lab 'Local IP')${LIP:-n/a}"
"$(lab 'Public IP')$PIP  $DM$GEO$R"
"$(lab ISP)${ORG:-n/a}"
"$(lab Ports)$PORTS listening   ${DM}failed units:$R $FAILED"
"$(lab Firewall)$FW_S   ${DM}ssh fails 24h:$R $FAILSSH"
"$(lab Docker)$DK"
"$(lab Procs)$PROCS running, $USERS user(s)"
"$(lab Top)$TOP"
"$(lab Temp)${TEMP:-n/a}   $RB"
"$(lab 'Last SSH')$(echo "${LAST:-none}" | head -1)"
"$(lab Time)$NOW"
"$S$BD🇮🇳  Jai Hind!  Jai Bharat!$R"
"$(for c in 208 214 255 40 28 18 196 39; do printf '\e[48;5;%sm    \e[0m' $c; done)"
)

flagrow(){
  local r=$1 t=$2 sh col txt=""
  sh=${OFF[$(((r+t)%8))]}
  if ((r<5)); then col=208; elif ((r<10)); then col=255; txt="${CH[r-5]}"; else col=28; fi
  printf '\e[38;5;94m┃\e[0m%*s' "$sh" ''
  printf '\e[48;5;%sm\e[38;5;18m%s\e[0m' "$col" "$(center "$txt")"
  printf '%*s' $((3-sh)) ''
}

M=${#info[@]}; N=$(( M>FH ? M : FH )); foff=$(((N-FH)/2))
render(){
  local t=$1 vis=$2 i fr
  for ((i=0;i<N;i++)); do
    fr=$((i-foff))
    if ((fr>=0 && fr<FH)); then printf ' '; flagrow $fr $t; else printf '%*s' $((FW+5)) ''; fi
    printf '   '
    ((i<vis)) && printf '%s' "${info[i]}"
    printf '\e[K\n'
  done
}

QUOTES=("वसुधैव कुटुम्बकम् — the world is one family" "विद्या ददाति विनयम् — knowledge gives humility" "अहिंसा परमो धर्मः — non-violence is the highest duty" "उद्यमेन हि सिध्यन्ति कार्याणि — work brings success")


# ---------- FULL DETAILS ----------
sec(){ printf '\n  %s%s━━ %s %s%s\n' "$S" "$BD" "$1" "$(printf '━%.0s' $(seq 1 $((60-${#1}))))" "$R"; }
kv(){ printf '  %s%-14s%s %s\n' "$DM" "$1" "$R" "$2"; }
full_details(){
  sec "HARDWARE"
  kv "CPU model" "$CPU"
  kv "Cores/Threads" "$(lscpu 2>/dev/null | awk -F: '/^Core\(s\) per socket/{c=$2}/^Socket\(s\)/{s=$2}/^CPU\(s\):/{t=$2}END{gsub(/ /,"",c);gsub(/ /,"",s);gsub(/ /,"",t);print c*s" cores / "t" threads"}')"
  kv "CPU MHz" "$(lscpu 2>/dev/null | awk -F: '/CPU MHz|CPU max MHz/{gsub(/^ +/,"",$2);print $2; exit}')"
  kv "Cache L2/L3" "$(lscpu 2>/dev/null | awk -F: '/L2 cache|L3 cache/{gsub(/^ +/,"",$2);printf "%s  ",$2}')"
  kv "Arch" "$(uname -m)"
  kv "RAM total" "$(free -h | awk '/Mem:/{print $2" (used "$3", free "$4", cache "$6")"}')"
  kv "GPU" "$GPU"
  kv "BIOS/Board" "$(cat /sys/devices/virtual/dmi/id/board_name 2>/dev/null || echo n/a)  $(cat /sys/devices/virtual/dmi/id/bios_version 2>/dev/null)"

  sec "DISKS"
  df -hT -x tmpfs -x devtmpfs -x squashfs -x overlay -x fuse.rclone 2>/dev/null | awk 'NR==1{printf "  %s%-22s %-8s %6s %6s %6s %5s%s\n","'"$DM"'",$1,$2,$3,$4,$5,$6,"'"$R"'"} NR>1{printf "  %-22s %-8s %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6,$7}'
  command -v lsblk >/dev/null && { echo; lsblk -o NAME,SIZE,TYPE,MOUNTPOINT 2>/dev/null | sed 's/^/  /'; }

  sec "NETWORK"
  ip -brief addr 2>/dev/null | awk '{printf "  %-14s %-8s %s %s\n",$1,$2,$3,$4}'
  kv "Gateway" "$(ip route 2>/dev/null | awk '/default/{print $3; exit}')"
  kv "DNS" "$(awk '/^nameserver/{printf "%s ",$2}' /etc/resolv.conf)"
  kv "Public IP" "$PIP  ($GEO)"
  kv "ISP" "${ORG:-n/a}"
  kv "IPv6" "$(ip -6 addr 2>/dev/null | awk '/global/{print $2; exit}' || true)"
  kv "TCP conns" "$(ss -tn state established 2>/dev/null | tail -n +2 | wc -l) established"

  sec "LISTENING PORTS"
  printf '  %s%-6s %-24s %s%s\n' "$DM" "PROTO" "ADDRESS" "PROCESS" "$R"
  ss -tulnpH 2>/dev/null | awk '{p=$NF; sub(/.*users:\(\("/,"",p); sub(/".*/,"",p); printf "  %-6s %-24s %s\n",$1,$5,p}' | sort -u | head -15

  sec "TOP PROCESSES"
  printf '  %s%-18s %6s %6s%s\n' "$DM" "COMMAND" "CPU%" "MEM%" "$R"
  ps -eo comm,%cpu,%mem --sort=-%cpu --no-headers | head -5 | awk '{printf "  %-18s %6s %6s\n",$1,$2,$3}'
  echo "  ${DM}-- by memory --${R}"
  ps -eo comm,%cpu,%mem --sort=-%mem --no-headers | head -5 | awk '{printf "  %-18s %6s %6s\n",$1,$2,$3}'

  sec "USERS & LOGINS"
  who 2>/dev/null | awk '{printf "  now: %s from %s (%s %s)\n",$1,$5,$3,$4}'
  last -n 5 -a -w 2>/dev/null | grep -v -E '^(reboot|wtmp|$)' | head -5 | sed 's/^/  /'
  kv "Failed SSH 24h" "$FAILSSH"
  kv "Sudo users" "$(getent group sudo | cut -d: -f4)"

  sec "SECURITY"
  kv "Firewall (ufw)" "$FW_S"
  kv "fail2ban" "$(systemctl is-active fail2ban 2>/dev/null || echo not-installed)"
  kv "SSH root login" "$(sshd -T 2>/dev/null | awk '/^permitrootlogin/{print $2}')"
  kv "SSH password auth" "$(sshd -T 2>/dev/null | awk '/^passwordauthentication/{print $2}')"
  kv "SSH port" "$(sshd -T 2>/dev/null | awk '/^port /{print $2; exit}')"
  kv "Pending updates" "$UPD   ($RB)"
  kv "Failed units" "$FAILED"

  sec "DOCKER"
  if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
    kv "Version" "$(docker --version | cut -d, -f1)"
    kv "Images" "$(docker images -q | wc -l)"
    docker ps --format '  {{.Names}}\t{{.Image}}\t{{.Status}}' 2>/dev/null | column -t -s $'\t' | head -10
  else kv "Docker" "not installed / not running"; fi

  sec "SYSTEM"
  kv "OS" "$OS"
  kv "Kernel" "$(uname -r)"
  kv "Hostname" "$(hostname -f 2>/dev/null || hostname)"
  kv "Timezone" "$(timedatectl show -p Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null)"
  kv "Boot time" "$(uptime -s 2>/dev/null)"
  kv "Uptime" "$(uptime -p | sed 's/up //')"
  kv "Load avg" "$LOAD  (cores: $CORES)"
  kv "Processes" "$PROCS total, $(ps -eo stat --no-headers | grep -c '^Z') zombie"
  kv "Open files" "$(awk '{print $1}' /proc/sys/fs/file-nr) / $(cat /proc/sys/fs/file-max)"
  kv "Entropy" "$(cat /proc/sys/kernel/random/entropy_avail 2>/dev/null)"
  kv "Locale" "${LANG:-n/a}"
  echo
}

banner
if ((ANIM==1 && ${COLUMNS:-$(tput cols)}>=105)); then
  printf '\e[?25l'; FR=30
  for ((f=0;f<FR;f++)); do
    vis=$((f*M/(FR-8))); ((vis>M)) && vis=$M
    render $f $vis
    ((f<FR-1)) && { printf '\e[%dA' $N; sleep 0.07; }
  done
  printf '\e[?25h'
else
  render 0 $M
fi
printf '\n  %s%s%s\n\n' "$DM" "${QUOTES[RANDOM%${#QUOTES[@]}]}" "$R"
((FULL==1)) && full_details
BHARAT_EOF
chmod +x "$BIN"

cat > "$MINI" <<'BHARATMINI_EOF'
#!/bin/bash
# bharatmini - compact India-themed login banner (MOTD friendly, fast, no animation)
export LC_ALL=C.UTF-8
CACHE_DIR=/var/cache/bharatfetch
CACHE=$CACHE_DIR/stats

# ---------------- background refresh of slow data ----------------
if [ "$1" = "--refresh" ]; then
  mkdir -p "$CACHE_DIR" 2>/dev/null || exit 0
  J=$(curl -s --max-time 3 https://ipinfo.io/json 2>/dev/null)
  jget(){ printf '%s' "$J" | grep -o "\"$1\": *\"[^\"]*\"" | head -1 | sed 's/.*: *"\(.*\)"/\1/'; }
  PIP=$(jget ip); CITY=$(jget city); CC=$(jget country)
  FAILSSH=$(journalctl -u ssh -u sshd --since "24 hours ago" -q --no-pager 2>/dev/null | grep -c "Failed password")
  UPD=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
  if command -v ufw >/dev/null; then FWS=$(ufw status 2>/dev/null | head -1 | sed 's/Status: //'); else FWS="n/a"; fi
  RB=no; [ -f /var/run/reboot-required ] && RB=yes
  {
    echo "PIP='${PIP:-offline}'"; echo "GEO='${CITY:+$CITY, }$CC'"
    echo "FAILSSH='${FAILSSH:-0}'"; echo "UPD='${UPD:-0}'"
    echo "FWS='${FWS:-n/a}'"; echo "RB='$RB'"
  } > "$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"
  exit 0
fi

PIP="..."; GEO=""; FAILSSH="-"; UPD="-"; FWS="-"; RB=no
[ -r "$CACHE" ] && . "$CACHE"
if [ ! -s "$CACHE" ] || [ $(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) )) -gt 1800 ]; then
  ( "$0" --refresh >/dev/null 2>&1 </dev/null & )
fi

# ---------------- colors / helpers ----------------
R=$'\e[0m'; B=$'\e[1m'
SF=$'\e[38;5;208m'; GN=$'\e[38;5;34m'; WH=$'\e[97m'; DM=$'\e[38;5;245m'
lab(){ printf '%s%-7s%s' "$SF$B" "$1" "$R"; }
bar(){
  local p=$1 f i col; ((p>100)) && p=100; f=$((p/10))
  if ((p>=85)); then col=196; elif ((p>=60)); then col=214; else col=40; fi
  for ((i=0;i<10;i++)); do
    if ((i<f)); then printf '\e[38;5;%sm█' "$col"; else printf '\e[38;5;238m░'; fi
  done
  printf '%s %3d%%' "$R" "$p"
}
hb(){ awk -v b="$1" 'BEGIN{split("B K M G T",u," ");i=1;while(b>=1024&&i<5){b/=1024;i++}printf "%.1f%s",b,u[i]}'; }

# ---------------- gather (fast) ----------------
OS=$(. /etc/os-release; echo "$PRETTY_NAME")
KER=$(uname -r)
UP=$(uptime -p | sed 's/^up //; s/ hours\?/h/; s/ minutes\?/m/; s/ days\?/d/; s/ weeks\?/w/; s/,//g')
CORES=$(nproc)
read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat; sleep 0.25
read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
dt=$(( (u2+n2+s2+i2+w2+q2+sq2)-(u1+n1+s1+i1+w1+q1+sq1) )); di=$(( (i2+w2)-(i1+w1) ))
CP=$(( dt>0 ? (dt-di)*100/dt : 0 ))
LOAD=$(awk '{print $1}' /proc/loadavg)
read -r MT MU <<<"$(free -m | awk '/Mem:/{print $2,$3}')"; MP=$((MU*100/MT))
MEMH=$(free -h | awk '/Mem:/{print $3"/"$2}')
DP=$(df / --output=pcent | tail -1 | tr -dc 0-9)
DISKH=$(df -h / | awk 'NR==2{print $3"/"$2}')
IF=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
RX=$(cat /sys/class/net/$IF/statistics/rx_bytes 2>/dev/null || echo 0)
TX=$(cat /sys/class/net/$IF/statistics/tx_bytes 2>/dev/null || echo 0)
LIP=$(hostname -I 2>/dev/null | awk '{print $1}')
PORTS=$(ss -tuln 2>/dev/null | tail -n +2 | wc -l)
FAILED=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
  DK="$(docker ps -q | wc -l)/$(docker ps -aq | wc -l)"
else DK="-"; fi
LAST=$(last -w -a -n 3 2>/dev/null | grep -vE '^(reboot|wtmp|$)' | sed -n 2p | awk '{printf "%s from %s (%s %s %s)",$1,$NF,$4,$5,$6}')
LAST=${LAST:-first login}
HR=$(TZ=Asia/Kolkata date +%H); HR=$((10#$HR))
if ((HR<12)); then GRT="Suprabhat"; elif ((HR<17)); then GRT="Namaste"; elif ((HR<21)); then GRT="Shubh Sandhya"; else GRT="Shubh Ratri"; fi
NOW=$(TZ=Asia/Kolkata date '+%a %d %b, %I:%M %p IST')
HN=$(hostname); HN=${HN:0:22}

# ---------------- sun-circle chakra ----------------
HW=(13 13 12 12 10 8 5)
CH=("  ╲ │ ╱  " "─ ─╲│╱─ ─" "────( ◉ )────" "─ ─╱│╲─ ─" "  ╱ │ ╲  ")
art=()
for y in -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6; do
  ay=${y#-}; hw=${HW[ay]}; pad=$((13-hw))
  line=$(printf '%*s' $pad '')
  if ((y<=-3)); then
    line+=$(printf '\e[48;5;208m%*s\e[0m' $((2*hw+1)) '')
  elif ((y>=3)); then
    line+=$(printf '\e[48;5;28m%*s\e[0m' $((2*hw+1)) '')
  else
    c=${CH[y+2]}; L=${#c}; half=$(((L-1)/2)); seg=""
    for ((i=-hw;i<=hw;i++)); do
      if ((i>=-half && i<=half)); then seg+="${c:i+half:1}"; else seg+=" "; fi
    done
    line+=$(printf '\e[48;5;255m\e[38;5;18m%s\e[0m' "$seg")
  fi
  line+=$(printf '%*s' $pad '')
  art+=("$line")
done

# ---------------- info (compact) ----------------
info=(
"$SF$B$GRT$R, $WH$B$(whoami)$R$DM @ $HN$R"
"$DM────────────────────────────────────────────$R"
"$(lab OS)$OS"
"$(lab Kernel)$KER ${DM}· up$R $UP"
"$(lab CPU)$(bar $CP) ${DM}${CORES}c · load$R $LOAD"
"$(lab RAM)$(bar $MP) ${DM}$MEMH$R"
"$(lab Disk)$(bar $DP) ${DM}$DISKH$R"
"$(lab Net)${IF:-n/a} ${DM}↓$R$(hb $RX) ${DM}↑$R$(hb $TX)"
"$(lab IP)${LIP:-n/a} ${DM}· pub$R $PIP"
"$(lab Secure)${DM}fw$R $FWS ${DM}· ssh-fail$R $FAILSSH ${DM}· ports$R $PORTS"
"$(lab System)${DM}updates$R $UPD ${DM}· failed$R $FAILED ${DM}· docker$R $DK"
"$(lab Last)$(printf '%s' "$LAST" | cut -c1-40)"
"$(lab Time)$NOW"
)

echo
for i in $(seq 0 12); do
  printf '  %s   %s\n' "${art[i]}" "${info[i]}"
done
printf '\n  %s%s%s   %sJai%s %sHind%s %s!%s   %sसत्यमेव जयते%s\n\n' \
  "$DM" "bharatfetch" "$R" "$SF$B" "$R" "$WH$B" "$R" "$GN$B" "$R" "$DM" "$R"
BHARATMINI_EOF
chmod +x "$MINI"

echo "[3/5] Installing SVG + PNG logo to $SHARE ..."
mkdir -p "$SHARE"
cat > "$SHARE/bharatfetch.svg" <<'SVG_EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 630" width="1200" height="630">
<defs>
<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0b1020"/><stop offset="1" stop-color="#05070f"/></linearGradient>
<filter id="sh" x="-10%" y="-10%" width="120%" height="130%"><feDropShadow dx="0" dy="8" stdDeviation="10" flood-opacity=".5"/></filter>
</defs>
<rect width="1200" height="630" fill="url(#bg)"/>
<g filter="url(#sh)">
<rect x="300" y="165" width="600" height="100" fill="#FF9933"/>
<rect x="300" y="265" width="600" height="100" fill="#FFFFFF"/>
<rect x="300" y="365" width="600" height="100" fill="#138808"/>
</g>



<circle cx="600" cy="315" r="44" fill="none" stroke="#000080" stroke-width="4"/><line x1="600" y1="315" x2="644.0" y2="315.0" stroke="#000080" stroke-width="2"/><circle cx="639.7" cy="320.2" r="2" fill="#000080"/><line x1="600" y1="315" x2="642.5" y2="326.4" stroke="#000080" stroke-width="2"/><circle cx="637.0" cy="330.3" r="2" fill="#000080"/><line x1="600" y1="315" x2="638.1" y2="337.0" stroke="#000080" stroke-width="2"/><circle cx="631.7" cy="339.4" r="2" fill="#000080"/><line x1="600" y1="315" x2="631.1" y2="346.1" stroke="#000080" stroke-width="2"/><circle cx="624.4" cy="346.7" r="2" fill="#000080"/><line x1="600" y1="315" x2="622.0" y2="353.1" stroke="#000080" stroke-width="2"/><circle cx="615.3" cy="352.0" r="2" fill="#000080"/><line x1="600" y1="315" x2="611.4" y2="357.5" stroke="#000080" stroke-width="2"/><circle cx="605.2" cy="354.7" r="2" fill="#000080"/><line x1="600" y1="315" x2="600.0" y2="359.0" stroke="#000080" stroke-width="2"/><circle cx="594.8" cy="354.7" r="2" fill="#000080"/><line x1="600" y1="315" x2="588.6" y2="357.5" stroke="#000080" stroke-width="2"/><circle cx="584.7" cy="352.0" r="2" fill="#000080"/><line x1="600" y1="315" x2="578.0" y2="353.1" stroke="#000080" stroke-width="2"/><circle cx="575.6" cy="346.7" r="2" fill="#000080"/><line x1="600" y1="315" x2="568.9" y2="346.1" stroke="#000080" stroke-width="2"/><circle cx="568.3" cy="339.4" r="2" fill="#000080"/><line x1="600" y1="315" x2="561.9" y2="337.0" stroke="#000080" stroke-width="2"/><circle cx="563.0" cy="330.3" r="2" fill="#000080"/><line x1="600" y1="315" x2="557.5" y2="326.4" stroke="#000080" stroke-width="2"/><circle cx="560.3" cy="320.2" r="2" fill="#000080"/><line x1="600" y1="315" x2="556.0" y2="315.0" stroke="#000080" stroke-width="2"/><circle cx="560.3" cy="309.8" r="2" fill="#000080"/><line x1="600" y1="315" x2="557.5" y2="303.6" stroke="#000080" stroke-width="2"/><circle cx="563.0" cy="299.7" r="2" fill="#000080"/><line x1="600" y1="315" x2="561.9" y2="293.0" stroke="#000080" stroke-width="2"/><circle cx="568.3" cy="290.6" r="2" fill="#000080"/><line x1="600" y1="315" x2="568.9" y2="283.9" stroke="#000080" stroke-width="2"/><circle cx="575.6" cy="283.3" r="2" fill="#000080"/><line x1="600" y1="315" x2="578.0" y2="276.9" stroke="#000080" stroke-width="2"/><circle cx="584.7" cy="278.0" r="2" fill="#000080"/><line x1="600" y1="315" x2="588.6" y2="272.5" stroke="#000080" stroke-width="2"/><circle cx="594.8" cy="275.3" r="2" fill="#000080"/><line x1="600" y1="315" x2="600.0" y2="271.0" stroke="#000080" stroke-width="2"/><circle cx="605.2" cy="275.3" r="2" fill="#000080"/><line x1="600" y1="315" x2="611.4" y2="272.5" stroke="#000080" stroke-width="2"/><circle cx="615.3" cy="278.0" r="2" fill="#000080"/><line x1="600" y1="315" x2="622.0" y2="276.9" stroke="#000080" stroke-width="2"/><circle cx="624.4" cy="283.3" r="2" fill="#000080"/><line x1="600" y1="315" x2="631.1" y2="283.9" stroke="#000080" stroke-width="2"/><circle cx="631.7" cy="290.6" r="2" fill="#000080"/><line x1="600" y1="315" x2="638.1" y2="293.0" stroke="#000080" stroke-width="2"/><circle cx="637.0" cy="299.7" r="2" fill="#000080"/><line x1="600" y1="315" x2="642.5" y2="303.6" stroke="#000080" stroke-width="2"/><circle cx="639.7" cy="309.8" r="2" fill="#000080"/><circle cx="600" cy="315" r="6" fill="#000080"/><rect x="285" y="150" width="8" height="400" rx="4" fill="#8b5a2b"/>
<text x="600" y="75" text-anchor="middle" font-family="DejaVu Sans, Arial, sans-serif" font-size="56" font-weight="700" letter-spacing="14" fill="#FF9933">BHARAT<tspan fill="#ffffff">FE</tspan><tspan fill="#138808">TCH</tspan></text>
<text x="600" y="115" text-anchor="middle" font-family="DejaVu Sans, Arial, sans-serif" font-size="22" fill="#9aa4b8">India themed system info for your terminal</text>
<text x="600" y="520" text-anchor="middle" font-family="DejaVu Sans Mono, monospace" font-size="22" fill="#cfd6e6">$ bharatfetch</text>
<text x="600" y="570" text-anchor="middle" font-family="DejaVu Sans, Arial, sans-serif" font-size="24" fill="#FF9933">Jai Hind  •  Jai Bharat</text>
</svg>
SVG_EOF
base64 -d > "$SHARE/bharatfetch.png" <<'PNG_EOF'
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
w+v+irLSZDKptTYMIxKNlR87duzIEaWMsJ+hoAz1H2htWq1Rq60jXKD8+NEj77z5eklJp/ETL/HS
add1tNYVx4/1Hzjo3PMvOHz4g7fffN1saP6k2pu1zLfefP3okSPnjxrT+/S+FcePsdZOOu273oRL
phQWFb/5+vrS48cNQzWhe2HYzfXVtauPHTs6acqlkyZflkwkXl29iiqXbGnEkxJClJeVHTt6tEvX
bt2690iVlxNxOp0OHGfCJVMi0YgOdFOifdWQRdd1lJLhPKg6CIIgUMo4fuzYmtWvdOnW/fIrZgY6
cNKVk5EGQZBKJT3PM0yr8btsJSfzsQYA0GSnxmkVANozZq47dWE47WHdO2td+XshhJBywQtzDh08
MOPq666+8RNFRcWxvPjEy6741K2fO3r0CDPX7OUY7iUc7RN2RNu4YYPv+5dfOfOCiydGItGCwsIp
V8z8/H995fjxY2GAyV5gLQ1j/7596VRy2PCR/YacaRhmJBqtXt2rwcKHE3vs2/f+v5/4R0FB4de+
/v+mTL+qS9eu0Wi0qKh40BmDZ153w2e/cJthmlprIlFV+NpX51rrLL+v3FE422GOO5KqEfVZk5Ay
nU6fNfTs2+74+tgJk047rU8sHo9EIkOGjbjxpk/l5+evf21tOp0Ok5gQggStXrUi8P3hI86RQqxd
tdLzXKkqTyhCiJtuvvXGm245c+iw4uISOxIpKi6+4prrLxo7Ye97e7ZseteyLKlUhvpXyjTN/S1f
q/XTdV79Bo+HenYtlZo3d/bevXsuv/LqGz91a+fOXaLR2HkXXvz5L321pFPnBXNn79m9y6qzMH09
22StLcveuWPbi/Pndu/R44tfvmPEeaMi0WiXbt0/eevnJ196+e6d2xfMe15VHczZaikbZm3a9p7d
u9558/X+Awf16z9g+9bNWzZvtCy7+j2V05OyLCFEoqLstVdXFxUVfeymmweceZZt2T1P6/Vft//3
0LOHHzt6tFazaLZ6rksplUol9+/fV1hUMubicXn5+bZth/MVmZY5b+7sN9a/dsWMq798+9cHn3lW
Xl5+LBbr0aPnqAsvvu2rd54/anQqmQwP5mx7PPlDqwlHkRCiUR9rNT8SAQBOBsYQAsDJYTZNq6io
OJ734eJmQoiCwkId6LpNUnn5BYWFRWFbk2Xb7+3Z/fvf/OJTt37+xptuufq6GzzPi0ajzzz1pFTy
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
jA3DZhFJ4plSIhJns14cm5kzn3Ic5/TT9xk/fqTvO77vtJdgrW1qKlpbGDduRCbjRZHtfZHPpP9w
//03DUOvsbGYz0ftbzmOTqddpVT7FhS/+92TIjJx4iiRYvJB19VxXKRvEADwaUErBQAY1BxHGWOV
UnfccdTBB28XxwWtjYhSKjVr1vPTp//tyCNvXbx4WVlZ9fe+t+uKFYUZMx6+9963wjCOY5tMILzq
qqdTqbqddtpQpE/LuhhjoyieMmV0sbjsuuueE5FiMU5Wjpkx4+EVKwpRZL797Z2HDRu2YkXj/vvf
8KtfPS6SjSLjeTqKgtraNGkQAPBp4cpqxs4A6APb4Q+9f091OpJvQKAPtFbWWq3V7NlH33nn64cc
8tc4LnpeVqRi9uwXRcT309dd96XKytSGG166aNESETn//ClnnbWPtdLSEjY2FsPQ23//Ta1t3Vew
p1gYx9YYa4zNZLxx40bceecjTU1Fa63v6wsvnHvOOXeJqKuvfubtt79XV5c95phtfvObOQ899Hbb
MFEThvVTpux0441frq1NJ3G0P+8S8OmWtImqS8uo2t7tVtfjAawh2ioAwKdAsjqoMfbgg7e8556v
HnDA6DCsFzG+n3WcdBTpM8986ItfvGHRooZUqlKpzCWXPLZ4cc5a+7e/vVQsLp0wYbMoipUS39c9
pUGllOMoz9OplGNt6zTCmTOfLhZNU1PxwgvnKpVNpys//nj5UUfddsght8yc+YRSadf1fd+L45xS
asaMqXfccWSSBllTFADwqUAgBAB8amitosgceOBm99574rnnTlFKFYst1oqIfv31hXPmvKWUH0XG
2njXXTcaPrxMa3X33W9Za/fff7NMxlu8ODdjxsPtGxh2KjyKVg4KVUrGjx8ZBG5TU9DSElZWpiZN
GmNtGIaxUunZs1+8444X8nmttY6iqFisP+CAMffcc+y55+6XdGaSBgEAnxbuQFcAAIA1kGwQr5TM
mLHfHnts8utfz73vvndEjONktFZhGBsjIs7rry8955z7t99+xCOPLEilhp5xxu5hGG+33RULFy4R
kRkzJv/0p3uHoUlGkAZBFIbmooseufDCe0TkD3945tVXv1NTkzn00C3/+c8nL730seHDywuFMKmA
tdZ1M46jg6AYRbkhQ2pPPXXfs8/e13EUkwYBAJ86BEIAwKdM0v8Whuagg0YddNCoe+9967e/fey+
+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
MjojaTX32ea/PNno+k6yZkwf77/nqPrm+In5wcEb+Jd8aYi19rH/FXxH7bFp+pdfqUv7OtcU21Xv
WWRsp2ctInaN/lla0UrE2KcXFI6K7df3rKpI6fnLIu3KxyuiG55sYmwpAAw4AiEADB6tXT6m7Qf9
lK/nvpm/ek79NyfVnjKp9uS9qwqhzWQdqXZ+/bcldeXO8TuVZ/1kcwoREd9VXpU7LGf70nVUndFe
tVuT7XGoSHW2mwNqstqrdss6nDTjKa/aHVrezbKS5Snl1bjVbSUYaz1fnX/Xsq038CfvXnH+UUPP
nVIbxjY9xM2viL5/y9Krjh8mnhpsfZ7JIp1i25+L9dfnc6nJaq/MGbtlduxOFStfja20mJb66G9z
m39y+9JcZH1XJZs59PH+J/+2zrtr2Z5j0mNGZf552kaF5thxxKvzln4QfO+WJdeeNFyU6viw68oc
r9rNeKvUOrbS98tPjnc85/onmiZvnT1gbNlJU4eIpySlVryev/GpJmNkne4GAgBYYwRCABgslJa0
r0QkF1qJRbliRVxHffuWpa8tCo/YpXzLOt+KPP1m7s9PNF0zt2Ha9mULAvPIKzntqNBY7ag3Fxcv
+NuS+pY4jK3quYfMWtGO+ut/m16tD99YEHT9idxa0Vr+/FTT80vDV+YXtG5d3UQr+eNjjXPeD+a+
nW8/6XPvBxf8ZfHCZVH7HhIiEhurHXX/a7n4ukUvvpXXunWhGqVVLpQv//Hj772dP2zH8jF1XjGy
dz7SePHdy99aEm5U40bGNuSNVut+VZu1o0QyvtZarJFc0SQb+oldj8/lpnlNLy0J48C0d81ZkUJo
P2qI5i0I3v4o0J7yXGWsKJG+3/84tp6nnnm3sP9vPvzhQTV7bZquLdMLG81D85p+fs+KxS3xZrO9
YmSbA9M62tPKrx+qH/Fy7r/vFbSjTMfn0efLN9ZaK44jDQUz+cqP99s8s9UGfpmvtKsWroiSrREH
x3MGgNKlvFT1QNcBAEqaUuJpFRobxfL0j0bsMLbsN7ctPePvSzIZJzJWKbFWwsD4KV2W0tbapoKN
Q+OndbFgRKwo7aVWbjsukRERN+WstjMqDEyyeqWX6r6TsNsDWl/U2vPbThpaiU035SgJA5vsP9jx
LaXEGImKJpXWWV/Hxja2GFHieSoMYhFxfGcwdBI6WjxHNTVHx+5R9edvbdDcEG194XvvLY9SSRhb
78+lKyWOSnlqlTVg1/D+ayVB0YqVyjLtaFWMbUtLLI5yXRV1ufmtNXG053XObX28/PZPtR/f4dJ6
/IcHAOhP9BACwIBSUoxsMYpF5JCdKrfZOKVy8bwFhfb3rRUlks7oyEh93qgkqGR0bCSd0Vqp2Nik
s0is+K5yfdda6ct0teTjxvY4jbDbA7qeNOUpJ9XdSa2kUsrRbqcSrBWtVrmiVEolr2ezroiE8aDo
NCrkTUFsNuUct2uF8dQrHxc/aog9p3W3jPX9XDq9aEWstdZ23hVwTe+/sZLylYg0B9aKTR5Esr9F
15ufyThKSXIhnevTt8vverwSpdp6ID/5irIAgE+OQAgAA0YpiSO7+TDviJ0rNq11D9+xwq90Xn0j
f9fLOcdXcVs3kG1bNlM7rX9Pfr6PjcSrdtwki5f08exdP96XA7q+aKyYHk7a01urXFGHkDNIoqCI
WCvH7FG55YapA8dkxm2elthe/VhjFJhMRkdt4Wqgnksna3r/k7vtahG1ss7S3c3vPbD1/fI7Hr++
lvoBAKwtAiEADBitpBjZsSP887/xOSlYaYqeeT134g2LW/LG91WX/p7P2s/Sg/aKlEho7c8m1Gw1
rlKWFHNN8W/+XX/9441+SnftTR20V9G7dVXtT+nlAwDaMYcQAAZM0kM4aph3xM4VLYF5fVH48Bv5
fGBSXdIg+pmxctTO5ZsN9T5cET3+v8JrHwR+SgvZBwDwmUMgBIAB1WHFERHl+trRXeaJYSC0r6mT
LOXCQwEAfCYRCAFggCklrk6WjrTG0Ac1WDhatFLWirHdrKoCAMBnA3MIAWCArdGKI+g3a7q4CwAA
n0ZsAQQAAAAAJYpACAAAAAAlikAIAAAAACWKQAgAAAAAJYpACAAAAAAlikAIAAAAACWKQAgAAAAA
JYpACAAAAAAlikAIAAAAACWKQAgAAAAAJcoVsQNdBwAAAADAAKCHEAAAAABKFIEQAAAAAEoUgRAA
AAAAShSBEAAAAABKFIEQAAAAAEoUgRAAAAAAShSBEAAAAABKFIEQAAAAAEoUgRAAAAAAShSBEAAA
AABKFIEQAAAAAEoUgRAAAAAAShSBEAAAAABKFIEQAAAAAEoUgRAAAAAAShSBEAAAAABKFIEQAAAA
AEoUgRAAAAAAShSBEAAAAABKFIEQAAAAAEoUgRAAAAAAShSBEAAAAABKFIEQAAAAAEoUgRAAAAAA
ShSBEAAAAABKFIEQAAAAAEoUgRAAAAAAShSBEAAAAABKFIEQAAAAAEoUgRAAAAAAShSBEAAAAABK
FIEQAAAAAEoUgRAAAAAAShSBEAAAAABKFIEQAAAAAEoUgRAAAAAAStT/B3m5bcQykDjSAAAAAElF
TkSuQmCC
PNG_EOF

echo "[4/5] Enabling on SSH login (MOTD)..."
mkdir -p "$STATE"
if [ -d /etc/update-motd.d ]; then
  if [ "$KEEP_DEFAULT" -eq 0 ]; then
    : > "$STATE/disabled-motd.list"
    for f in /etc/update-motd.d/*; do
      [ "$f" = "$HOOK" ] && continue
      if [ -x "$f" ]; then echo "$f" >> "$STATE/disabled-motd.list"; chmod -x "$f"; fi
    done
  fi
  printf '#!/bin/sh\nexec /usr/local/bin/bharatmini\n' > "$HOOK"
  chmod +x "$HOOK"
else
  # Debian and others without update-motd: use profile.d for interactive logins
  printf '[ -t 1 ] && [ -z "$BHARAT_SHOWN" ] && export BHARAT_SHOWN=1 && /usr/local/bin/bharatmini\n' > "$PROF"
fi
# remove old .bashrc hook from earlier versions (avoid showing twice)
sed -i '/# bharatfetch-login/d' /root/.bashrc 2>/dev/null || true

echo "[5/5] Warming cache (public IP, updates, ssh stats)..."
"$MINI" --refresh || true

echo
"$MINI"
echo "Done! It will now show automatically when you log in over SSH."
echo
echo "  bharatmini                  compact banner (same as login)"
echo "  bharatfetch                 animated flag + info"
echo "  bharatfetch --full          every detail"
echo "  sudo bash install.sh --keep-default-motd   keep Ubuntu's default MOTD too"
echo "  sudo bash install.sh --uninstall           remove everything"
