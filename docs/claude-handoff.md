You are taking over my personal fork of Mural on my Mac. Complete the work to build and run it in Xcode, verify Swedish support, and install it on my iPhone. Carry out the steps and fix build or test failures; do not stop at a plan. Ask me when you need my preferences or a manual Apple/device action, and continue independent work meanwhile.

My repository is https://github.com/LuiAr/mural-swedish.git. I am a French speaker learning Swedish with English subtitles and word explanations. iPhone is the priority; Android comes later. Preserve Mural's existing interface and language-module architecture.

The Swedish implementation, tests, teaching research and verification notes are on branch codex/add-swedish in my GitHub fork. Use that branch; no handoff ZIP or patch is needed. For a new checkout, run: git clone --branch codex/add-swedish https://github.com/LuiAr/mural-swedish.git. For an existing checkout, inspect its status and preserve local work before fetching and switching branches.

1. Inspect the current checkout and read AGENTS.md before changing it. Preserve existing changes, ignored signing settings and learning data; use an isolated branch/worktree if necessary. Fetch origin/main and origin/codex/add-swedish. Continue the existing Swedish work from codex/add-swedish and integrate any newer main commits before making fixes. Confirm that apps/ios/Core/Languages/Swedish.swift is present. Do not discard existing work or replace the implementation from scratch.

2. Read docs/add-language.md, docs/swedish.md, docs/build-and-test.md, docs/run-on-iphone.md and verification/swedish-2026-10-05.md. Swedish uses ID sv, locale sv-SE, greeting Hej!, six teaching focuses and six theme overrides. English is the default meaning language. Spoken conversation, help and corrections stay Swedish; French/English replies can provide support. Preserve separate learning records, Swedish letters, valid regional variants and the existing Norwegian default. Swift/Kotlin teaching prompts must agree; regenerate Android content if you change the module.

3. Check Xcode selection, installed SDKs, Swift and available simulators. This project needs Xcode 26+ and iOS 26.1+. Resolve the pinned dependencies, including WebRTC 152.0.0. Open apps/ios/Mural.xcodeproj with scheme Mural. Choose destinations and architecture from this Mac's actual devices, rather than assuming a simulator name or Apple Silicon. New Core files are discovered by SwiftPM; run scripts/generate_project.py only if needed and preserve personal settings when doing so.

4. Run these offline checks from the repository root:
   - swift test --package-path apps/ios
   - python3 -m unittest discover -s scripts/tests -t .
   - python3 scripts/export_android_content.py --check
   - python3 scripts/check_cross_platform.py
   Build for iOS Simulator with code signing disabled, then run the native UI suite on an available compatible simulator with parallel testing disabled. Include testSwedishOnboarding and testSwedishTranscriptAndEnglishMeaningSurviveLanguageSwitch. Fix failures and rerun affected checks. Previous Linux checks passed: 78 Python, 15 isolated Kotlin/JVM and 3 API language tests, plus content/parity/TypeScript checks. Swift compilation, Xcode builds and iOS UI tests have NOT run yet.

5. Launch the simulator and verify Swedish selection, Hej!, themes, language switching and English meanings. Debug preview arguments --preview --ended-conversation --preview-language=sv provide a sample without API calls. Remove preview/verification arguments before checking normal persistence or installing the normal app.

6. Guide me through Apple Account sign-in and choosing my signing team. For a first installation, configure a unique bundle identifier; for updates preserve the installed app's team and identifier. Keep personal signing configuration local and ignored, and verify the effective build settings. Detect my connected iPhone, build, install and launch. Tell me when I must unlock, trust the Mac/developer, enable Developer Mode or approve a system prompt. Preserve the installed app and its data. A free Personal Team is sufficient; explain its seven-day refresh using the same app identity.

7. I will provide my OpenAI key later. Complete offline validation and installation without it. When ready, I will enter it directly in Settings > Advanced > Use your own API key. Never request it in chat, read it from Keychain, or include it in source, build arguments, screenshots or logs. Personal-key mode needs no Mural backend deployment. Keep hosted trials, managed sign-in and purchases outside this personal-build task. Diagnose actual provider/model access errors from sanitized evidence if they occur.

8. Once I am ready to start a short live conversation, help verify real microphone input, Swedish output and correction, English subtitles/lookup, themes, saved progress after relaunch/switching, mute, background audio and closure. Close iPhone Mirroring for voice checks because it disables the microphone. Do not start billed verification helpers while my key/testing is deferred. Synthetic typed turns do not prove speech recognition or pronunciation quality; record what was actually checked.

Finish with the app running in Xcode and on my connected iPhone where available, a brief report of fixes/checks, any exact remaining manual steps, and updated verification notes. If no phone is connected, finish simulator validation and leave the project ready for device installation. Keep Android content consistent, but do not expand into Android release work or publishing.
