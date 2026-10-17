# Margin: Pitch

## The problem

Two problems show up in almost every classroom:

1. **Teachers are drowning in grading.** Written feedback is one of the strongest levers on student writing, and one of the most time-consuming parts of teaching. A stack of 120 essays at 10 to 15 minutes each is a lost weekend. Most AI writing tools answer by grading *for* the teacher, which takes the professional out of the loop and lets unreviewed machine judgements reach children.
2. **Students with learning differences get the same text as everyone else.** A student with dyslexia faces a dense block of serif text. A student with ADHD faces four pages with no handholds. Simplified versions exist, but they change the content: the student gets less, and the teacher can't be sure what they read.

## Our answer: Margin

**AI drafts, the teacher decides, and every learner gets the same lesson in the way they read best.**

- **Feedback in the margin.** The moment a student submits, AI drafts margin comments, rubric levels with rationales, and a glow-and-grow summary.
  - The teacher reviews it in a focused workspace: approve, edit or reject each comment, with one-key shortcuts.
  - Release unlocks only when every decision is made.
  - Every comment is anchored to the student's own words. Hallucinated quotes and harsh wording are removed before the teacher even sees the draft.
- **One lesson, five ways.** Standard, dyslexia-friendly, chunked focus, read aloud with word-by-word highlighting, and visual.
  - A "Same content" check proves every sentence, number and key term from the original is present, exactly once.
  - When AI helps decide how to chunk a lesson, it returns sentence numbers, never text, and the app verifies them.
- **A teacher dashboard that works like a product, not a demo:**
  - AI-drafted assignments (essays with rubrics and standards, reading lessons, quest courses) that the teacher edits and sends.
  - Rosters with reading profiles and accommodations that apply automatically: extended time moves due dates, reduced length lowers word targets.
  - Class insights that turn rubric patterns into tomorrow's mini-lesson.
- **Quests for curiosity.** Any topic becomes an AI-written book and a hand-inked map. Guide characters ask for reasoning, not just answers. Struggle triggers a new explanation instead of a dead end.

## Three-minute demo

| Time | Step | What judges see |
|---|---|---|
| 0:00 | **Welcome** | Seurat on the left. A promise on the right: *"Every comment a student sees, their teacher approved."* Tap **Teacher** and enter PIN 2468. |
| 0:15 | **Today** | Nine essays have drafts ready. Time back, average review time, and how often the teacher changed the AI. Students who haven't started. Reading profiles across classes. |
| 0:35 | **Review Jonah's essay** | His opening says the topic "should be talked about more". The AI *questions* it rather than praising it, and every comment highlights the exact words. Edit one, reject one with **R**, approve the rest with **A**. Confirm rubric levels with the AI's suggestion and rationale visible. Approve the summary. |
| 1:15 | **Release preview** | Exactly what Jonah will see. Rejected comments and AI rationales are gone. Release. The queue advances to the next essay. |
| 1:30 | **New assignment** | Reading on *The Water Cycle*. **Draft with AI**, then the **Same-content check** shows all sentences, figures and terms intact. **Preview as Dyslexia-friendly.** Send to the class: Theo, Leah and Lucas get +2 days automatically. |
| 2:00 | **Student: Lucas (Listen)** | The new assignment is waiting. It opens in read-aloud, with each word lighting up as it's spoken. Switch to **Chunked**: one idea at a time and a focus timer. Switch to **Visual**: term cards and step flows. Tap the **Same content** badge to see the proof. |
| 2:30 | **Student: Maya** | Returned feedback, anchored in her essay, signed by Ms. Ellis. Reply to a comment, then **Revise & resubmit**. |
| 2:45 | **Insights** | Rubric heatmap, the suggested mini-lesson ("Claim: show three openings side by side…"), and the most common next steps. |
| 2:55 | **Close** | Oracle Cloud Generative AI through a privacy gateway, or fully on device. Names never reach a model. |

## How it meets the judging criteria

| Criterion | Where it shows |
|---|---|
| **Strengthens learning** | Specific, anchored feedback reaches students faster and is still teacher-quality. The revise-and-resubmit loop shows the previous next step. Accessible formats remove barriers without lowering the bar. Quests ask for reasoning, with hints before answers. |
| **Human oversight** | No AI comment reaches a student without teacher approval. AI assignments are drafts until sent. The teacher owns profiles, accommodations, mastery thresholds and help levels. Course review covers AI-written books. |
| **Learner agency** | Students choose and switch formats, fonts, spacing and tints. The AI won't write their essays. They can reply to feedback and revise. In quests, they pick the tutor's help level, ask for hints themselves, and can turn AI off. |
| **Responsible and transparent AI** | Every AI artefact is marked. Drafts show their engine and what the safety layer removed. Students are told feedback was AI-assisted and teacher-approved. A fidelity proof backs every reformatted lesson. |
| **Privacy** | The model never sees student names, support notes or profiles. PII is scrubbed twice. The engine runs on device by default. OCI keys stay on the gateway, whose audit log holds no content. Quest analytics use k-anonymity and differential privacy. |
| **Use of OCI** | `GatewayProvider` sends feedback, assignments, lesson structure, courses, tutoring, evaluation, hints, remediation and insights to OCI Generative AI (Llama 3.3 or Cohere Command). The app falls back to the on-device engine if OCI can't be reached. |
| **Craft** | The UI was designed by hand, not generated: Fraunces, Figtree and Source Serif, plus Lexend, OpenDyslexic and Atkinson for accessibility. Covers are CC0 museum art and the quest map is engraved. Tests cover it: 30 unit tests, 4 end-to-end UI journeys and 7 gateway tests. |

## Why it would actually get used

- **Teachers stay the author.** The AI saves the drafting, not the judgement. Over time, "AI comments you changed" shows whether that trust is earned.
- **Accommodations live in one place.** They are set once per student and follow the student into every assignment, instead of a spreadsheet and a mental note.
- **It works on a school iPad today.** Offline, with no accounts and no cloud bill. OCI makes the drafts richer when it's available.
