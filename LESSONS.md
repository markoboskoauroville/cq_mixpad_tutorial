# LESSONS

1. (24.10.2026) Live speech drops on the 4G line (the voice server made it at 0.32× real time): every sentence is made
   into an mp3 first and played from the file.
2. Speechify's word marks sometimes include the word's full stop: find the sentence by cutting the text once and
   looking the word up, never by scanning from the word's end (two sentences lit at a transition).
3. CQ MixPad misses a click whose press and release come together: 120 ms between them, and the app in front first.
4. AbletonOSC answers only to 11001: questions go through the router of Ableton Live Actions on 11002.
5. A SwiftUI Canvas draws a Text as it is: a centred multi-line note is drawn line by line.
6. (24.10.2026) Live's `/live/song/start_playing` starts at the start marker: set `current_song_time` AFTER it, not
   before (lesson 11 played from beat 0 instead of 948).
7. (24.10.2026) A test guard that clicks STOP at a screen position missed, and lesson 11 moved Marko's playhead from
   beat ~1787 to 0 while he was listening. Never test steps that move Live's transport while Live is playing for him.
