#!/usr/bin/env python3
"""render.py: a text becomes one finished mp3 BEFORE anything plays (Marko, 24.10.2026: "Avoid sound drops on any
cost"; "record the sound and save it on the computer"). The text is cut at sentence ends into pieces under 1500
characters, each piece is made by Speechify's own API (Marko, 24.10.2026: "We work with APIs ... there are free
accounts, so you need to work with fallback"): Beatrice (beatrice_32, simba-3.2), his keys from
~/Downloads/API/speechify_api.txt taken by shape and never printed, the next key when one is spent or refused; only
when every key fails, the Mac's voice server (:8837 /say, engine beatrice). The pieces are joined into one file with a
short pause between them. Nothing streams while playing.

    python3 tools/render.py in.txt out.mp3
"""
import base64, json, os, re, subprocess, sys, tempfile, urllib.error, urllib.request

VOICE = 'http://127.0.0.1:8837'
API = 'https://api.sws.speechify.com/v1/audio/speech'
KEYFILE = os.path.expanduser('~/Downloads/API/speechify_api.txt')
VOICE_ID, MODEL = 'beatrice_32', 'simba-3.2'          # the model belongs to the voice (generating-audio.md §3)

def keys():
    try: txt = open(KEYFILE).read()
    except OSError: return []
    seen = []
    for k in re.findall(r'\bsk_[A-Za-z0-9_-]{40,}', txt):     # Speechify: sk_ and 44+ characters (keyring.md)
        if k not in seen: seen.append(k)
    return seen

KEYS = keys()
used = {'key': 0, 'server': 0}

def speechify(text, path):
    while KEYS:
        req = urllib.request.Request(API, data=json.dumps({'input': text, 'voice_id': VOICE_ID, 'model': MODEL,
                                     'audio_format': 'mp3'}).encode(),
                                     headers={'Content-Type': 'application/json', 'Authorization': 'Bearer ' + KEYS[0]})
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                open(path, 'wb').write(base64.b64decode(json.load(r)['audio_data']))
            used['key'] += 1
            return True
        except urllib.error.HTTPError as e:
            if e.code in (401, 402, 403, 429):           # spent, refused or limited: the next account
                KEYS.pop(0); continue
            raise
    return False

def pieces(text, limit=1500):
    sents = re.split(r'(?<=[.!?])\s+', ' '.join(text.split()))
    out, cur = [], ''
    for s in sents:
        if cur and len(cur) + len(s) + 1 > limit:
            out.append(cur); cur = s
        else:
            cur = (cur + ' ' + s).strip()
    if cur: out.append(cur)
    return out

def say(text, path):
    if speechify(text, path): return
    used['server'] += 1
    req = urllib.request.Request(VOICE + '/say', data=json.dumps({'text': text, 'engine': 'beatrice'}).encode(),
                                 headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=300) as r:
        url = json.load(r)['url']
    urllib.request.urlretrieve(VOICE + url, path)

def render(text, out):
    tmp = tempfile.mkdtemp()
    parts = []
    for i, p in enumerate(pieces(text)):
        f = os.path.join(tmp, f'{i:03}.mp3'); say(p, f); parts.append(f)
    gap = os.path.join(tmp, 'gap.mp3')
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'lavfi', '-i', 'anullsrc=r=44100:cl=mono', '-t', '0.35',
                    '-b:a', '128k', gap], check=True)
    lst = os.path.join(tmp, 'list.txt')
    with open(lst, 'w') as f:
        for i, p in enumerate(parts):
            if i: f.write(f"file '{gap}'\n")
            f.write(f"file '{p}'\n")
    # decode and encode once, so the joins are sample-exact (no clicks, no gaps from mp3 frame padding)
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', lst, '-ar', '44100', '-ac', '1',
                    '-b:a', '128k', out], check=True)
    return out

if __name__ == '__main__':
    render(open(sys.argv[1]).read(), sys.argv[2])
    d = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', sys.argv[2]],
                       capture_output=True, text=True).stdout.strip()
    print(f'{sys.argv[2]}: {float(d):.1f} s; pieces by the Speechify API {used["key"]}, by the voice server {used["server"]}')
