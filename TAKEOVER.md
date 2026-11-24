# TAKEOVER

**24.10.2026, v3.** The app plays all eleven lessons offline; tested: lesson 1 with the voice, the step list, the MA
Reader highlight (one sentence at a time, checked over all 1925 word marks) and the hand clicking CONFIG and the USB tab
in MixPad. Not yet seen end to end: lessons 3–11 with Live (solo, play from Jai Ganesha at 948 beats) and the hand in
Live (its points are measured on Live full screen on the BenQ: if Live's layout changes, they move).

**Next**
- Photos per lesson from Nano Banana (Gemini in Chrome, the accounts u/0, u/1, u/3 … in parallel tabs, started about
  30 s apart): `content/images/<n>.jpg` and `"image"` on each lesson; the app shows them beside the title.
- CQ MixPad Actions: a second app, its own repository, in the same star folder.

**24.10.2026, v7.** 27 lessons (16 from the book), 17 CQ manual quotes, 11 Nano Banana photos, 204 sentences made with
Speechify. Tested: lessons 1–10 end to end with no fault in the log (~/Library/Logs/cqtutorial.log), lesson 12's book card.
Lesson 11 ran once and exposed two faults, both fixed: Live played from beat 0 (start then move), and Marko's playhead
was taken (now restored with his solos). Not yet re-run: lesson 11 with the fix, lessons 13–27 end to end.

**25.10.2026, v21.** The whole course played end to end, lessons 1–28 (06:19–08:23), Claude driving with
`build/start <lesson>[.<step>] | pause | resume` (distributed notifications), Marko observing. From v21 (lesson 6 on) not
one PROBLEM in the log. What changed on the way:
- v16: pause / resume / play-from-step from outside, for a permission dialog first (a guard pauses, brings the dialog
  forward, Beatrice tells Marko; three seconds after it is gone the tutorial comes back and resumes).
- v17–v21: Live and CQ MixPad each full screen in its own space on the BenQ. The hand asks "running?" first (not running is
  the only "not open"), slides to the app's space with `/usr/bin/open -a` (activate, Accessibility and
  NSWorkspace.openApplication did not slide; up to three tries of 4 s, each "SWIPE:" in the log), then measures the click.
- v18: Accessibility asked only when missing (AXIsProcessTrusted first).
- Claude Code side: ~/Developer/claude-code/tools/tutorial_attention.sh, called by the Notification (permission_prompt) and
  PostToolUse hooks: an approval in the terminal pauses the tutorial and brings the terminal forward, then resumes.

**Next**
- Marko's verdict on the lessons themselves (what to cut, slow, explain differently).
- CQ MixPad full screen: done by Marko with its green button (25.10.2026); Live and MixPad now each in its own space.
- CQ MixPad Actions, the second app of the Audio Production folder.

## v24, 31.10.2026: TOP

TOP beside the ✕ (UserDefaults "onTop", NSWindow.level .floating, applied at launch); the row's words are Accessibility
buttons `on`, `off`, `top`, `permissions`, `close`. At the minimum width 1100 the lesson list's left edge is cut (not
fixed in v24).


## What it is (folded from the former README, 24.11.2026)


**The Allen & Heath CQ-12T taught by voice, diagrams and a hand, offline, with the Santoshi concert as the case study.**
Marko, 24.10.2026: *"Teach me my mixer ... Teach me by voice and mouse"*, *"the whole tutorial as a software-only Swift"*.

`/Applications/CQ MixPad Tutorial (Mantra).app`, in the star's folder **Audio Mixing**. Its window fills the MacBook's
screen; CQ MixPad and Ableton Live stay on the BenQ, where the hand works.

- **Twenty-seven lessons** (`content/lessons.json`). Lessons 12–27 come from Steve Savage, *Mixing and Mastering in the Box* (Marko's PDF on Drive; chapters 1–6), in our own words with one short quote each, tied to the Santoshi channels; drafted in `content/book_lessons.json` and `book_lessons2.json`. The first eleven: the cable both ways, the return channels, the routing now, the USB preview
  of the venue mix while recording, preparing a multitrack in Live (names, markers, −12 dB), gain staging, EQ and HPF,
  the channel compressor, reverb on a send, the glue compressor on the main, balancing.
- **The voice is made before, never streamed**: `python3 tools/build_audio.py` makes every sentence with the Speechify
  API (beatrice_32, simba-3.2; Marko's keys from `~/Downloads/API/speechify_api.txt`, next key on a spent one; the Mac's
  voice server last) into `content/audio/steps/<hash>.mp3` with its word marks `<hash>.json`. Only edited sentences are
  made again. Each lesson's whole narration is also `content/audio/lessons/<n>.mp3`, to replay without the app.
- **Diagrams** are data (`content/diagrams.json`), drawn by the app; a step lights parts of them.
- **The hand** (`app/Hand.swift`): glides the real mouse to a control of CQ MixPad or Live (a 1600 × 900 picture of the
  app's window), clicks it, with a big amber ring around the pointer and the word being said in a red block above it.
  Needs Accessibility (granted 24.10.2026). Clicks only change pages and banks, and the listen key it switches back.
- **Live** by OSC (`app/Live.swift`) through the router of Ableton Live Actions on 127.0.0.1:11002.
- **Sources are marked** (Marko: "you need to quote it so i know you quote from the manual"): FROM THE CQ MANUAL and FROM THE BOOK cards with the chapter; every sentence tagged MANUAL / BOOK / MEASURED / SANTOSHI / MIXING KNOWLEDGE.
- **Live is given back**: a lesson that plays or solos remembers where Live was and restores it (and every solo) at its end or on STOP.
- **The reading highlight is MA Reader Web's**: sentence a yellow band, word a red block (MANTRA_MANIFEST word-timing.md §4a).
- **Keys**: BACK (the spoken step before), AGAIN, PLAY / PAUSE, SKIP, STOP; a click on a lesson or a step starts there.
- **What was changed, and when**: the list under the steps (`changes` in `content/lessons.json`).

Build: `./build.sh` (swiftc, signed "Mantra Apps", content copied into the app, installed in /Applications).
