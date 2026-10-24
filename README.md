# CQ MixPad Tutorial (Mantra)

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
