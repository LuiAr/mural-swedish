# iPhone study tools

These tools extend Words and saved conversations. Talk keeps its existing layout. Learning records and study material stay on the device and travel with a JSON learning backup. The Android archive format preserves the new material; the new study interfaces are currently on iPhone.

## Listen to words and sentences

Open a word in **Words**, or open the flashcards beside **Your words**. **Listen** plays at the normal speed; **Slow** uses a slower pace. A playing control becomes **Stop**. Flashcard examples stay hidden with the meaning until you reveal the card.

Playback uses the learning language's installed iPhone voice and makes no OpenAI request. If that voice is missing, download it in iPhone accessibility settings and try again. Saved sentences are labelled as conversation excerpts, rather than presented as independently checked model answers.

End or pause Talk before listening here. Changing a card or language, leaving the screen, backgrounding the app or starting Talk stops playback. Check the speaker and headphones on a physical iPhone after an audio update.

## Daily review

Choose **Daily review** in Words. Each sitting contains up to ten due words and lasts at most five minutes. Think of the Swedish word from its saved English meaning, optionally type an answer, then reveal it and choose **Remembered** or **Needs practice**.

Each grade is saved immediately, so closing the sheet leaves the remaining words available next time. Remembered reviews use intervals of one, three, seven and fourteen days. Needs practice returns the word after one day. This is a simple practice schedule, not a calibrated memory prediction.

Self-grading does not add conversation evidence or increase spoken-recall bars. Existing flashcards remain available for browsing whenever you want.

## Conversation recap and retry

Open **Words → Past conversations**, choose an ended conversation, then **Review this conversation → Create recap**. A recap uses the saved transcript and your existing personal OpenAI key. Creating one makes a text API request; opening a saved recap or playing it with the device voice makes no new API request.

The recap offers at most one wording correction with a short English explanation. It can also report that no clear correction was found. The quoted learner sentence must match the saved source. This does not assess pronunciation, and a suggested correction can be mistaken.

**Try again** hides the suggestion while you type another attempt. Reveal it for self-comparison. This practice leaves the original transcript and spoken proficiency unchanged. Correcting a misheard transcript or extending the conversation invalidates its old recap.

Creating a recap requires AI processing permission and the personal-key provider. Finish a paused conversation before creating its recap. No hosted account or server deployment is required.

## Swedish word forms

Open a Swedish word in Words and use its **Word forms** section. Create a card for its saved meaning using the existing personal key. Supported noun cards show indefinite and definite singular and plural forms; verb cards show infinitive, present, past and supine forms. Missing or uncertain forms are identified explicitly. Other word types can return an unavailable result.

Generated forms are reference material and can be mistaken. They are saved separately from conversation evidence, can be read offline after generation and do not change recall bars. **Refresh forms** makes another text request while keeping the previous card available if the request fails. Hiding a word or removing all of its supporting learning records removes its card. No new API key or hosted purchase setup is needed.

## Verification

Core tests cover schedules, old backups, imports, source invalidation, language separation and unchanged spoken evidence. New persisted Core types have Kotlin counterparts. The native Checks job builds the simulator app and unsigned iPhone Release app, and runs the study interfaces against offline fixtures.

The Swedish fixture uses temporary preview storage:

```text
--preview --preview-key --screenshot=words --preview-swedish-study
--preview-recap --preview-word-forms --preview-pronunciation
```

Preview generation returns fixed samples and does not contact a provider. Installed device voices, physical audio routing and signed installation still need the owner's Mac and iPhone. Do not start a live conversation or make billable requests merely to verify these screens.
