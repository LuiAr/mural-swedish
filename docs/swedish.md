# Swedish in this personal Mural fork

Choose **Swedish · Sweden** as the learning language and **English** as the subtitle language. Conversation, corrections and spoken help stay in Swedish; subtitles and contextual word explanations use English. French or English learner replies are welcome as support, but do not count as independent Swedish production. Your OpenAI key can be entered later through Settings → Advanced → Use your own API key.

The compiled module uses stable storage ID `sv`, locale `sv-SE`, native name `Svenska` and greeting `Hej!`. Its initial speech target is standard Swedish as spoken in Sweden. Valid regional usage, including Finland-Swedish, is accepted. Adding Swedish preserves the other languages, the Norwegian legacy/default ID `nb`, existing learning archives and the English meaning default. Select Swedish during onboarding rather than changing old records to a new language.

## Teaching decisions and research

Research reviewed on 5 October 2026. These sources inform the module; they do not establish that an AI tutor is the best method for every learner or that this implementation has measured learning outcomes.

| Decision | Evidence and implementation |
| --- | --- |
| Practise useful actions in short conversations | [Skolverket's SFI syllabus](https://syllabuswebb.skolverket.se/syllabuscw/jsp/sfi.htm) emphasizes communication for everyday, work and study situations, adapted to the learner's needs. The [Council of Europe's action-oriented approach](https://www.coe.int/en/web/common-european-framework-reference-languages/action-orientation-in-the-classroom) also centers purposeful language use. The module uses greetings, asking for repetition, shopping, travel and fika; it offers a short phrase or simple choice when needed, then reduces support as the learner demonstrates ability. |
| Prioritize intelligibility in pronunciation | [Stockholm University's Swedish intelligibility project](https://www.su.se/english/research/research-catalogue/research-projects/d/intelligibility-in-swedish-as-a-second-language) identifies stressed-syllable quantity as important for intelligibility. [Bosse Thorén's explanation of Swedish prosody](https://bossethoren.se/prosodi_eng.html) distinguishes stress, complementary vowel/consonant length and pitch. The speech guidance prioritizes stress, rhythm and length while modeling natural vowels and pitch accents. It accepts regional variation and prohibits inferring pronunciation errors from transcript spelling. |
| Learn gender, definiteness and word order in context | [Isof's explanation of Swedish word order and noun phrases](https://www.isof.se/utforska/bloggar-och-poddar/bloggarkiv/sant-vi-bara-gor/inlagg/2020-08-27-omvand-ordfoljd-och-annan-ordfoljd) illustrates en/ett, definite endings, adjective position and finite-verb placement in main clauses. The module stores nouns with their article and introduces these structures through useful phrases and stories. Common/neuter gender is not inferred from French masculine/feminine gender or an English translation. |
| Make a clear correction noticeable and allow a retry | [Lyster and Saito's classroom feedback meta-analysis](https://doi.org/10.1017/S0272263109990520) found durable benefits from corrective feedback, with larger effects for prompts than recasts in the reviewed studies. The Swedish policy preserves Mural's brief correction and invites another attempt for a recurring error. Limiting corrections to one per turn is Mural's interaction design, not a result demonstrated by that paper. |
| Revisit vocabulary across time and situations | [Kim and Webb's spaced-practice meta-analysis](https://doi.org/10.1111/lang.12479) supports distributed second-language practice. The Swedish policy reuses prior practice words in relevant new contexts through Mural's existing recall mechanism. The research does not validate Mural's specific spacing thresholds or recall bars. |

This is an application of the sources to Mural's existing design. It adds content and Swedish prompt guidance without replacing the learning engine, introducing a fixed course or claiming CEFR/SFI certification. The learner's topic and observed ability still determine the conversation.

## Six adaptive teaching focuses

| Internal focus | Examples |
| --- | --- |
| 0 | Greetings, introductions, `jag heter`, `jag skulle vilja`, asking for slower speech or repetition |
| 1 | Everyday questions, `en/ett`, definite endings, common plurals and present-tense verbs |
| 2 | Everyday stories, preterite/perfect, modal verbs, adjective agreement and verb-second main clauses |
| 3 | Reasons and opinions, subordinate clauses, the placement of `inte`, comparisons and connectors |
| 4 | Particle verbs, `sin/sitt/sina`, idiomatic chunks, register and regional variation |
| 5 | Hypothetical situations, passive constructions, argumentation and precise, natural discussion |

These are provisional challenge guides, not a required lesson order or proficiency certificate. The tutor should simplify in response to the conversation, not assume ability from a fluent French or English reply.

Vocabulary uses singular noun forms such as `en bok` and `ett hus`, and verb citation forms such as `att läsa`. Inflections can share one lemma and English sense, while particle verbs such as `att tycka om` remain distinct from `att tycka`. Exact learner quotations retain `å`, `ä`, `ö`, compounds and original Unicode. The model is instructed to supply these forms; tests exercise validation and storage, not autonomous grammar correctness.

## Implementation and platform scope

- `apps/ios/Core/Languages/Swedish.swift` supplies the content; `LanguageRegistry` drives the existing iPhone pickers, progress and archives.
- Swedish introduction and conversation guidance live in both native `TeachingPolicy` files with identical wording.
- `scripts/export_android_content.py` generates the Android module from Swift. This prepares content for the later Android version without changing Android's native interface.
- `services/api/src/live-provider.ts` admits `sv-SE`, and its tests verify the speech target with a local fake provider. Personal-key mode connects directly to OpenAI and requires no Mural backend deployment. Hosted Swedish would require deploying the matching locale support to a service you control before using it.
- iPhone debug fixtures and the opt-in language-verification helper include Swedish coffee examples. Ordinary tests do not use a real provider or API key.

## Verification and first device check

Run from the repository root:

```sh
python3 -m unittest discover -s scripts/tests -t .
python3 scripts/export_android_content.py --check
python3 scripts/check_cross_platform.py
```

Run the locale contracts and type checking from `services/api/`:

```sh
npm run check
./node_modules/.bin/tsx --test tests/languages.test.ts
```

On a Mac with the required Xcode tools:

```sh
swift test --package-path apps/ios
xcodebuild -project apps/ios/Mural.xcodeproj -scheme Mural \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/SwedishDerivedData \
  CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES build
```

Run the native UI suite on a supported iPhone simulator, including Swedish onboarding, switching back to an existing language, and retrieving a Swedish transcript with its English meaning. Core tests cover source characters, noun/particle-verb keys, supported versus independent recall, rejecting foreign-language vocabulary, hidden-word isolation and archive round trips.

When the personal key is available, check a short real iPhone conversation: greeting, an English or French beginner reply, understandable Swedish output, one clear correction, English subtitles and word lookup, a Swedish theme, then saved progress after switching and relaunching. Check actual microphone input, background audio and final closure separately from typed replies. Ask a proficient Swedish speaker to review stress, vowel/consonant length, regional acceptance and corrections before treating pronunciation quality as verified. The existing Debug-only `--verify-language=sv` helper makes real billed requests and is not part of offline verification.

See [the verification record](../verification/swedish-2026-10-05.md) for checks completed in this workspace and platform limits, [the installation guide](run-on-iphone.md) for signing and device setup, and [the language-module guide](add-language.md) for the shared workflow.
