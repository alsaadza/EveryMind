# Margin

**Room for every learner.** An iPad app for classrooms where AI does the heavy lifting and teachers keep the final say.

Margin was built for the Oracle *"AI That Strengthens Learning"* challenge. It goes after two problems teachers name again and again:

1. **Grading burnout.** Teachers spend hours every week writing feedback on essays. In Margin, AI drafts margin comments, rubric levels and a short "glow and grow" summary the moment a student submits. **The teacher approves, edits or rejects every comment before the student sees anything.**
2. **Learning differences.** Students with dyslexia or ADHD usually get the same wall of text as everyone else. Margin presents every lesson in five ways: standard, dyslexia-friendly, chunked focus, read aloud with word highlighting, and visual. **Every format is checked word for word against the original, so the content never changes. Only the presentation does.**

Around those two features sits a complete classroom product:
- A teacher dashboard with AI-drafted assignments sent to students.
- Rosters with per-student reading profiles and accommodations.
- Class insights.
- An AI quest mode that turns any topic into a three-chapter book and a map to explore.

## Quick start (works fully offline)

```bash
brew install xcodegen          # if needed
xcodegen generate
open EducateAI.xcodeproj       # run the EducateAI scheme on an iPad simulator or device
```

No account, key or network is needed. The app opens on a choice between **Student** and **Teacher**:

- **Teacher demo PIN: 2468.** The seeded demo has three classes and twelve students. Nine essays are waiting with AI-drafted feedback, and a reading assignment is in progress. One essay has already been returned, so the student view has an example.
- **Students sign in** shared-iPad style by tapping their name. Try **Theo** (dyslexia-friendly), **Priya** or **Zara** (Focus, for ADHD), **Lucas** (Listen) and **Kenji** (Visual). Maya has returned feedback waiting.

## What's inside

### For teachers
- **Today.** A summary of what needs you:
  - The review queue.
  - Measured review time, and minutes saved against an adjustable 12-minute-per-essay baseline.
  - How often you changed the AI's comments.
  - Students who may need a check-in.
- **Feedback review**, a full-screen workspace:
  - **The essay** sits on the left, with every AI comment highlighted on the exact words it refers to.
  - **The "margin"** on the right lists comments to **approve, edit or reject**. Keyboard shortcuts: ↑ ↓ to move, A approve, R reject, E edit.
  - **Your own comments.** Select any words to add one.
  - **Rubric.** Confirm a level for each criterion. The AI's suggested level is marked with its rationale.
  - **Summary.** Edit and approve the "glow and grow".
  - **Release.** It stays locked until every comment, score and the summary are decided. A preview shows exactly what the student will see.
- **Assignment builder.** Pick essay, reading or quest course, then:
  - Describe the topic and let AI draft the title, instructions, prompt, a four-level rubric and the standards it aligns to. For a reading, it drafts lesson text.
  - Edit everything, then preview the reading in each student profile.
  - Send it to the whole class or to chosen students.
  - Accommodations apply automatically. **Extended time** moves that student's due date back two days. **Reduced length** lowers their word target to 70%.
- **Classes and reading supports.** Rosters and join codes, with a per-student reading profile, accommodations and a private support note. The note is never shown to the student and never sent to an AI.
- **Class insights:**
  - A rubric heatmap by student and criterion, a suggested mini-lesson for the weakest criterion, and the most common next steps.
  - Reading-format usage and completion.
  - Privacy-protected quest analytics, using k-anonymity and differential privacy.
- **Course review and AI policies.** Approve, flag or edit AI-written quest content. Set the mastery threshold, hint policy and maximum tutor help level.

### For students
- **Today.** Assignments from the teacher, with personal due dates, returned feedback and quests.
- **Reading in your format.** One toolbar switches between five views, each proved identical in content by the "Same content" badge:
  - **Original.** Typography tuned to the learner, including Lexend, OpenDyslexic or Atkinson Hyperlegible fonts, letter, line and word spacing, page tints, and a draggable reading ruler.
  - **Chunked.** One or two sentences at a time with a progress trail, bolded key terms, keyboard or tap navigation and an optional focus timer that suggests breaks.
  - **Read aloud.** Speech with live word-by-word highlighting, adjustable speed, and tap-any-sentence to jump.
  - **Visual.** Key terms become cards, sequences become numbered step flows, numbers become fact callouts, and everything else becomes icon bullets.
- **Essay workspace:**
  - The prompt (with read-aloud), the source text and the rubric on the left.
  - A distraction-free editor in your reading font on the right.
  - "Read my draft aloud", a word target and autosave.
  - Margin's AI never writes for the student.
- **Returned feedback.** Only approved comments are shown, anchored in the essay, along with the summary and confirmed rubric levels. Students can reply to a comment, then **revise and resubmit**. The next version shows last time's next steps.
- **Quests.** Name any topic and AI writes a three-chapter interactive book:
  - The book becomes a hand-inked map where each chapter is a place with a guide.
  - Pages offer the same five formats plus live simulations: coins, dice, spinners, cards, Venn, probability tree, number line, fraction bar and water cycle.
  - An AI tutor has three help levels.
  - Guide challenges need an answer **and** reasoning, with escalating hints and an Apple Pencil scratchpad.
  - Mastery unlocks the next chapter. Struggling brings a newly written page and a follow-up challenge.

## Connecting OCI Generative AI

The app never holds cloud credentials. It talks to a small **privacy gateway** you run next to OCI.

```bash
cd gateway
cp .env.example .env           # set OCI_COMPARTMENT_ID, model, optional GATEWAY_TOKEN
./run.sh                       # creates a venv, installs the oci SDK, listens on :8787
./run.sh --mock                # same API with canned replies, no OCI needed
python3 -m unittest test_gateway
```

| Variable | Default |
|---|---|
| `OCI_CONFIG_FILE` | `~/.oci/config` |
| `OCI_PROFILE` | `DEFAULT` |
| `OCI_COMPARTMENT_ID` | tenancy from the config |
| `OCI_GENAI_ENDPOINT` | `https://inference.generativeai.us-chicago-1.oci.oraclecloud.com` |
| `OCI_GENAI_MODEL_ID` | `meta.llama-3.3-70b-instruct` (any `cohere.*` model also works) |
| `GATEWAY_TOKEN` | unset, so no auth |
| `PORT` | `8787` |

In the app, go to **Settings > AI Provider**, choose **OCI Generative AI**, and enter the gateway URL and token. In the simulator the URL is `http://localhost:8787`. On a device, use your Mac's LAN address. If the model returns something unusable, Margin falls back to the on-device engine and says so.

### Gateway API

| Endpoint | Purpose |
|---|---|
| `GET /health` | Mode (`oci` or `mock`) and model id |
| `POST /v1/chat` | `{system, messages, max_tokens, temperature, json, purpose}` returns `{text, model, provider, redactions}`. PII is scrubbed before the model sees it. |
| `POST /v1/signals` | De-identified learning events. Any field outside `topic, chapter_index, kind, tag, value` is rejected. |
| `GET /v1/insights?cohort=&k=5&epsilon=1.0` | Aggregates with k-anonymity suppression and Laplace noise |

The audit log records purpose, message counts, character counts and redaction counts. It never records content.

## Architecture

```
 ┌──────────────────────────── iPad (SwiftUI) ─────────────────────────────┐
 │  Teacher shell                        Student shell                     │
 │  Today · Feedback review · Builder    Today · Reader · Essay · Quests   │
 │          │                                     │                        │
 │   ClassroomStore (classes, rosters,     AppStore (quests, progress)     │
 │   assignments, submissions, feedback)   JSON on device, user-deletable  │
 │          └──────────────┬──────────────────────┘                        │
 │            AIProvider protocol (one interface, two engines)             │
 │      ┌──────────────────┴───────────────────┐                           │
 │  On-device engine                    GatewayProvider                    │
 │  EssayCoach (NaturalLanguage +       prompt library, strict JSON,       │
 │  UITextChecker), LessonAdapter,      anchor + tone guard on device,     │
 │  curated packs, rubric evaluator     fallback to on-device              │
 └──────────────────────────────────────────────┬──────────────────────────┘
                                                │ HTTPS, bearer token
                                  ┌─────────────▼─────────────┐
                                  │   Margin privacy gateway   │
                                  │  PII scrub · content-free  │
                                  │  audit log · k-anon + DP   │
                                  └─────────────┬─────────────┘
                                                │ OCI request signing
                                  ┌─────────────▼─────────────┐
                                  │   OCI Generative AI        │
                                  │ Llama 3.3 / Cohere Command │
                                  └───────────────────────────┘
```

**Safety layers between the model and a student:**
- **Feedback.** Each AI comment's quote must appear in the essay. Near-misses are re-anchored to the closest sentence and others are dropped. A tone filter removes harsh wording. The teacher then decides on every comment.
- **Reformatting.** The model may return only sentence numbers and labels of five words or fewer. A partition check and a fidelity check (sentences, figures, key terms) run before anything is shown. If a check fails, Margin falls back to deterministic formatting.

## Project layout

```
EducateAI/
├── project.yml              XcodeGen spec (iPad only, bundled fonts)
├── EducateAI/
│   ├── App/                 Entry point, role routing
│   ├── Design/              Design system (palette, type, components), art catalog
│   ├── Models/              Course, Progress, Classroom (assignments, feedback, reading prefs), seed essays
│   ├── AI/                  AIProvider, prompts, gateway + on-device engines,
│   │                        EssayCoach, LessonAdapter, AssignmentStudio, answer checker, PII filter
│   ├── Services/            AppStore, ClassroomStore, SpeechReader, insights (k-anon / DP)
│   ├── Views/               Teacher, Student, Reading, World, Book, Challenge, Tutor, Library, Settings
│   └── Resources/           Fonts (OFL), asset catalog (CC0 art, CC0 avatars, icon)
├── gateway/                 Python OCI privacy gateway + tests
└── docs/                    PITCH.md, RESPONSIBLE_AI.md, CREDITS.md, licenses/
```

## Design

Margin uses a paper-and-ink editorial look, chosen so school content feels calm and serious rather than gamified:

- **Typefaces.** Fraunces for display, Figtree for the interface and Source Serif 4 for reading. Lexend, OpenDyslexic and Atkinson Hyperlegible are offered as accessibility faces.
- **Art.** Covers are public-domain works from the Art Institute of Chicago and The Met: Hokusai, Seurat, Cassatt, Monet, Hammershøi and others, all CC0.
- **Avatars.** Student avatars are DiceBear "Notionists" (CC0).
- **Quest map.** Drawn procedurally as an engraved island.
- **Credits.** Full attributions are in [docs/CREDITS.md](docs/CREDITS.md).

## Privacy by design

- **On-device by default.** The on-device engine needs no network. Data lives in local JSON with file protection, and users can export or erase it.
- **The AI never sees who wrote an essay.** Names, support notes and accommodations are never sent to a model, and essay text is PII-scrubbed twice: on device and at the gateway.
- **Keys stay off the device.** OCI credentials live only on the gateway, whose audit log records counts, never content.
- **Opt-in, de-identified signals.** Quest signals use k=5 suppression and Laplace noise. The quest analytics use a synthetic demo cohort.
- **Support profiles stay off the sign-in screen.** Student reading profiles are never shown on the shared-iPad sign-in screen.

See [docs/RESPONSIBLE_AI.md](docs/RESPONSIBLE_AI.md).

## Tests

```bash
xcodegen generate
xcodebuild -project EducateAI.xcodeproj -scheme EducateAI \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' test
python3 gateway/test_gateway.py
```

- **Unit tests** (`EducateAITests`) cover:
  - Essay feedback:
    - Every AI comment is anchored to the essay and starts pending.
    - Feedback stays encouraging.
    - An exemplary essay scores above a struggling one.
    - Opposing positions aren't penalised.
    - Vague openings are questioned rather than praised.
    - Clock times aren't treated as evidence.
    - Spellcheck finds real misspellings.
    - The guard drops hallucinated quotes and harsh tone.
    - Release requires every decision.
  - Reading formats:
    - Every sentence is preserved for every chunk size and in the visual format.
    - The fidelity check catches dropped and duplicated sentences.
    - Invalid AI plans are rejected.
  - Accommodations apply automatically, and the seeded queue goes through to release.
  - The original quest suite: answer parsing, mastery, misconceptions, remediation, lenient JSON decoding, the hint leak guard, PII scrubbing and k-anonymity.
- **UI journeys** (`EducateAIUITests`):
  - A teacher edits, rejects and approves comments, confirms the rubric and summary, previews and releases.
  - AI drafts a reading assignment, which is previewed as a dyslexic reader, sent, then opened by a Listen-profile student who switches formats.
  - A student with dyslexia changes the reading font, writes and submits an essay, and another student reads returned feedback.
  - The full five-step quest.

**Launch arguments for demos:**
- `-resetState` restores the seeded demo.
- `-role teacher` opens the teacher view, skipping the PIN.
- `-student Theo` signs in as a student.
- `-teacherOpen review Jonah` opens an essay review.
- `-teacherOpen section insights` opens a teacher section.
- `-studentOpen reading` opens the reading assignment.
- `-autoDemo -openChapter` jumps into a quest chapter.
