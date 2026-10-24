#!/usr/bin/env python3
"""render.py: a text becomes one finished mp3 BEFORE anything plays (Marko, 24.10.2026: "Avoid sound drops on any
cost"; "record the sound and save it on the computer"). The text is cut at sentence ends into pieces under 1500
characters, each piece is made by Speechify's own API (Marko, 24.10.2026: "We work with APIs ... there are free
accounts, so you need to work with fallback"): Beatrice (beatrice_32, simba-3.2), his keys from
~/Downloads/API/speechify_api.txt taken by shape and never printed, the next key when one is spent or refused; only
when every key fails, the Mac's voice server (:8837 /say, engine beatrice). The pieces are joined into one file with a
short pause between them. Nothing streams while playing.
Beside out.mp3, out.json holds Speechify's exact word marks, [char start, char end, seconds from, seconds to], on the
text with its spaces made single, so the reader can light the sentence (yellow) and the word (red) as they are said
(Marko, 24.10.2026: "My eyes need to be guided ... Speechify gives you exact word timing").

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
                j = json.load(r)
            open(path, 'wb').write(base64.b64decode(j['audio_data']))
            used['key'] += 1
            chunks = (j.get('speech_marks') or {}).get('chunks') or []
            return [[c['start'], c['end'], c['start_time'] / 1000, c['end_time'] / 1000] for c in chunks if c.get('type', 'word') == 'word']
        except urllib.error.HTTPError as e:
            if e.code in (401, 402, 403, 429):           # spent, refused or limited: the next account
                KEYS.pop(0); continue
            raise
    return None

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

def duration(path):
    return float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', path],
                                capture_output=True, text=True).stdout)

def say(text, path):
    marks = speechify(text, path)
    if marks is not None: return marks
    used['server'] += 1
    req = urllib.request.Request(VOICE + '/say', data=json.dumps({'text': text, 'engine': 'beatrice'}).encode(),
                                 headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=300) as r:
        url = json.load(r)['url']
    urllib.request.urlretrieve(VOICE + url, path)
    return []          # the voice server gives no marks here: the text is shown without the word highlight

def render(text, out):
    tmp = tempfile.mkdtemp()
    full = ' '.join(text.split())
    parts, marks, at, t = [], [], 0, 0.0
    for i, p in enumerate(pieces(text)):
        f = os.path.join(tmp, f'{i:03}.mp3'); m = say(p, f); parts.append(f)
        at = full.index(p, at)                      # where this piece sits in the whole text
        marks += [[a + at, b + at, round(t0 + t, 3), round(t1 + t, 3)] for a, b, t0, t1 in m]
        at += len(p); t += duration(f) + 0.35       # the pieces are joined with a 0.35 s pause
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
    json.dump(marks, open(os.path.splitext(out)[0] + '.json', 'w'))
    return out

if __name__ == '__main__':
    render(open(sys.argv[1]).read(), sys.argv[2])
    d = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', sys.argv[2]],
                       capture_output=True, text=True).stdout.strip()
    print(f'{sys.argv[2]}: {float(d):.1f} s; pieces by the Speechify API {used["key"]}, by the voice server {used["server"]}')
