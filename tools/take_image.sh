#!/bin/sh
# take_image.sh N: the newest Gemini download in ~/Downloads becomes content/images/N.jpg (1600 px wide, JPEG), the
# download is removed, and the Download Monitor is told it is done.
set -e
N=$1; D="$HOME/Downloads"; OUT="$(dirname "$0")/../content/images/$N.jpg"
F=$(ls -t "$D"/Gemini_Generated_Image_* 2>/dev/null | head -1)
[ -n "$F" ] || { echo "no Gemini image in Downloads"; exit 1; }
MB=$(du -k "$F" | awk '{printf "%.1f", $1/1024}')
sips -s format jpeg -s formatOptions 82 -Z 1600 "$F" --out "$OUT" >/dev/null
rm -f "$F"
python3 "$HOME/Developer/DOWNLOAD_MONITOR/dlmon.py" report "cq-img-$N" "$MB" "$MB" --name "CQ tutorial photo $N (Gemini)" --done >/dev/null 2>&1 || true
echo "content/images/$N.jpg $(sips -g pixelWidth -g pixelHeight "$OUT" | awk '/pixel/{printf "%s ", $2}')from $MB MB"
