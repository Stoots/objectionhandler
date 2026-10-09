# macOS compatibility

OpenOats targets **Apple Silicon, macOS 14.2+**. Core Audio process taps require
14.2; earlier Sonoma releases are not supported. Qwen3 ASR uses macOS 15-only
FluidAudio APIs. Parakeet, Whisper and the existing cloud backends remain
available on Sonoma. Live/batch model pickers and setup detection omit Qwen3
there, and saved unavailable selections resolve to Parakeet v2.

## Building and releasing

Use the existing Xcode 26 / Swift 6.2 build environment on a host supported by
Xcode. The build host's OS is separate from the release app's minimum OS; an
end user on Sonoma only needs the application bundle. Do not lower toolchain
requirements or patch dependency checkouts to produce official releases.

The SwiftPM platform, app Info.plist and UI-test host all target 14.2. Run:

```sh
cd OpenOats
swift test
cd ..
SKIP_SIGN=1 SKIP_INSTALL=1 ./scripts/build_swift_app.sh
python3 scripts/check_macos_compatibility.py dist/OpenOats.app
python3 -m unittest discover -s scripts/tests -p 'test_*.py'
```

The compatibility check verifies source/bundle deployment metadata and the
executable's Mach-O minimum OS. Package CI runs it on the existing modern
build runner; this is not a substitute for testing a release on Sonoma.

The release workflow reads `LSMinimumSystemVersion` from the built app for
both the Sparkle appcast and the Homebrew cask update. This also preserves the
correct minimum when rebuilding a historical release. The checked-in cask must
continue to describe its currently published binary until a new compatible
release replaces its version and checksum.

## Audio regressions covered

A device-bound tap needs both `deviceUID` and output stream index `0`. On
Sonoma, omitting the stream produced `Stream out of range for tap` in
coreaudiod; tap creation returned success with ID 0 and later format queries
failed with OSStatus 560947818 (`!obj`). Reject an unknown tap ID before
creating its aggregate device. Keep retries for genuinely transient failures.

Streaming conversion uses the capture format's sample rate. The VAD/ASR
consumer may process queued buffers seconds after capture, so its wall-clock
throughput cannot measure the device's rate. The old estimate incorrectly
treated 48 kHz audio as roughly 7–12 kHz on a Sonoma machine. Conversion tests
cover tone frequency/duration, delayed consumption and changes in input format.

For a real-device check in a quiet test session:

1. Enable local audio saving and select the output carrying your playback.
2. Start recording, then mute the microphone in OpenOats.
3. Play a known spoken sentence from another application. Wait for finalized
   text attributed to **Them**; partial hypotheses can take time to settle.
4. Stop and confirm a playable M4A, then restore the microphone. Separately
   verify microphone speech as **You**.
5. Repeat when changing output hardware. Multi-stream professional audio
   interfaces may need a different stream; the first stream is the default.

The underlying audio fixes were verified on macOS 14.6.1 / Apple Silicon with
built-in speakers: a microphone-muted test finalized “The quick brown fox jumps
over the lazy dog.” and saved a 48 kHz mono AAC recording. This is a short
capture/transcription check, not a long-meeting or all-peripherals certification.

### Objection coaching capture verification

On macOS 26.6.2 / Apple M3, Parakeet TDT v2 finalized a synthesized
price/budget phrase from external playback as **Them**, with the microphone
muted. The native window displayed the matching objection card, suggested
reply, and follow-up question. A separate physical-microphone check finalized
the phrase as **You** and left coaching in its waiting state. That check used
an `AVAudioPlayer` created through the debugger inside the isolated app:
the existing system tap excludes the app's own playback, so the phrase
reached transcription through the microphone rather than the system channel.

Selecting the unused Microsoft Teams output did not isolate external playback
on this machine; it still arrived as **Them**. Do not treat that setup as a
microphone-only check. These are controlled-audio checks, not a human sales
call, transcription-accuracy certification, or multi-speaker hardware test.
The XCTest UI suite uses scripted transcripts and is separate from audio
capture verification. Run those checks sequentially with only one test app
open: both app instances register the global recording shortcut.

The full objection playbook was also exercised on this host with controlled
external playback and the microphone muted. Parakeet TDT v2 finalized
“This is not a priority, we already have a provider.” as **Them**; the native
window displayed both timing/priority and existing-provider cards quoting that
exact transcript. This used a real local transcription engine in an isolated
temporary workspace, not scripted utterances. Repeated external playback
finalized “Not now, we currently use a vendor.” and updated the same two
category cards. Dismissing provider suppressed a qualifying captured repeat
nine seconds later while timing stayed active; provider resurfaced on a new
captured repeat more than 30 seconds after dismissal. The saved M4A contained
system audio with no microphone samples. The playbook's separate scripted
native UI suite passed 13 tests, including all seven categories across two
scenarios, split information requests, repeated timing quotes, dismissal,
pause/resume, and new-session reset.

For current macOS hosts, inspect `/usr/bin/automationmodetool` before changing
UI-testing authorization: this host's executable uses
`enable-automationmode-without-authentication` and
`disable-automationmode-without-authentication`, whereas its installed manual
lists an obsolete spelling. Run authorization changes only with approval and
restore the original policy and Developer Tools state afterward. The native
test launcher ignores saved window restoration so a prior manual run with
closed windows does not change scenario startup.

For diagnosis, enable Settings → General → Diagnostic logging and inspect the
system-audio events or export diagnostics. Successful startup should report a
nonzero tap ID, a resolved tap format and a successful device start. An absent
permission entry alone does not establish denial if tap creation failed first.
