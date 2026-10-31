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
