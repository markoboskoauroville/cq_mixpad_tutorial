#!/usr/bin/env python3
"""build_audio.py: every "say" of lessons.json becomes a finished mp3 BEFORE the tutorial plays (no live speech, no
drops; Marko, 24.10.2026: "Avoid sound drops on any cost"). A step's file is named after the hash of its text, so an
edited sentence is made again and the others are kept. Each lesson's whole narration is also joined into one file,
audio/lessons/<n>.mp3: the recording to replay without the app.

    python3 tools/build_audio.py
"""
import hashlib, json, os, subprocess, sys
sys.path.insert(0, os.path.dirname(__file__))
import render

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STEPS = os.path.join(ROOT, 'audio', 'steps'); LESSONS = os.path.join(ROOT, 'audio', 'lessons')

def name(text): return hashlib.sha1(text.encode()).hexdigest()[:16] + '.mp3'

def main():
    os.makedirs(STEPS, exist_ok=True); os.makedirs(LESSONS, exist_ok=True)
    data = json.load(open(os.path.join(ROOT, 'lessons.json')))
    made = kept = 0
    for n, lesson in enumerate(data['lessons'], 1):
        files = []
        for st in lesson['steps']:
            if 'say' not in st: continue
            f = os.path.join(STEPS, name(st['say']))
            if os.path.exists(f) and os.path.getsize(f) > 1000: kept += 1
            else: render.render(st['say'], f); made += 1
            files.append(f)
        lst = os.path.join(LESSONS, f'{n}.txt')
        with open(lst, 'w') as fh:
            for f in files: fh.write(f"file '{f}'\n")
        out = os.path.join(LESSONS, f'{n}.mp3')
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', lst, '-ar', '44100', '-ac', '1',
                        '-b:a', '128k', out], check=True)
        os.remove(lst)
        d = float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', out],
                                 capture_output=True, text=True).stdout)
        print(f'lesson {n}: {len(files)} sentences, {d/60:.1f} min -> audio/lessons/{n}.mp3')
    used = sorted(name(st['say']) for l in data['lessons'] for st in l['steps'] if 'say' in st)
    for f in os.listdir(STEPS):
        if f not in used: os.remove(os.path.join(STEPS, f))     # a sentence no longer in the lessons
    print(f'made {made}, kept {kept}; Speechify API pieces {render.used["key"]}, voice server {render.used["server"]}')

main()
