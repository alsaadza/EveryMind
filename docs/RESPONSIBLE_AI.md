# Responsible AI in Margin

Margin's rule: **AI drafts, people decide.** This document explains how that rule is enforced in code, not just in policy.

## 1. Teacher-approved feedback

**AI never talks to a student directly about their writing.**

- **Drafts start pending.** Each AI comment, rubric level and summary is created in a `pending` state. `EssayFeedback.readyToRelease` is true only when three things hold:
  - every comment is approved (possibly edited) or rejected;
  - every rubric criterion has a teacher-confirmed level;
  - the summary is approved.
- **Release is locked until then.** The Release button stays disabled, and `ClassroomStore.release` refuses to run otherwise.
- **Students see only approved work.** They get approved comments and confirmed levels. Rejected comments, AI rationales and suggested levels never leave the teacher view.
- **Anchoring.** Every comment must quote the student's exact words. `EssayCoach.guardComments` checks each quote against the essay:
  - A quote that matches exactly is kept.
  - A quote with at least 60% overlap is re-anchored to the closest sentence.
  - Anything else is dropped, and the teacher is told how many comments were removed.
- **Tone check.** Comments with harsh wording ("lazy", "careless", "sloppy" and similar) are removed before the teacher sees the draft.
- **Judge the writing, not the opinion.** Prompts tell the model to assess reasoning and never the position taken. A unit test confirms an essay arguing the unpopular side still scores well on Claim.
- **Encouraging by construction.** Each draft includes at least one strength, uses the "glow and grow" format, and puts no grades inside comments.
- **Transparency for the teacher.** Each draft shows which engine wrote it, what the model saw (essay text only), and what the safety layer removed.
- **Transparency for the student.** Students are told that feedback was "drafted with AI assistance and reviewed, edited and approved by" their teacher.
- **Honest time-saved metric.** Review time is measured while the teacher reviews. "Time back" compares it with an adjustable baseline per essay, so it isn't an invented number. The dashboard also shows how often teachers changed the AI's comments, which keeps over-reliance visible.

## 2. Same content, every format

Accessibility formats must never water down or alter the lesson.

- **Present, never rewrite.** `LessonAdapter` splits a lesson into its original sentences. Chunked, read-aloud and visual formats only **regroup, emphasise or speak** those sentences. Nothing is summarised or rewritten.
- **What the AI may return.** Its only role is to suggest chunk boundaries and short signpost labels. The prompt asks for sentence **indices**, never text.
- **Validation.** The app checks that the indices partition the lesson exactly. If they don't, it silently falls back to deterministic chunking.
- **Fidelity check on every format.** It confirms every original sentence appears exactly once, and every number and key term is still present. The "Same content" badge shows the counts. Unit tests run it over every curated lesson, at every chunk size, in every format.
- **AI labels are marked.** They are visually marked as AI, separate from lesson text.
- **The teacher sees it too.** The check runs when they build a reading assignment, and they can preview the lesson as each reading profile before sending.

## 3. Learner agency

- **Students choose how they read.** Profiles set the starting format, and students can switch formats, fonts, spacing and tints at any time.
- **AI won't write for the student.** The essay workspace says so plainly. AI is not involved until submission, and even then its output goes to the teacher, not the student.
- **Students can respond.** They can reply to comments and revise and resubmit. Earlier versions and feedback are kept, so growth stays visible.
- **Quest controls.** In quests, learners choose the tutor's help level (Socratic, Balanced or Supportive). Hints are opt-in, solutions unlock only after real attempts, and AI can be switched off entirely.

## 4. Human oversight

- **Teachers set the rules.** They set reading profiles and accommodations, the mastery threshold, the maximum tutor help level and hint policy, and whether AI courses need approval before use.
- **AI-written assignments are drafts.** Prompts, rubrics and lesson text are editable and only reach students when a teacher presses **Send**.
- **Insights are advisory.** The suggested mini-lesson and the rubric heatmap support planning. They never rank students or infer traits.

## 5. Privacy

- **The model never learns who wrote an essay.** Names, avatars, support notes, accommodations and reading profiles are never sent to a model. Essay text is PII-scrubbed on device and again at the gateway.
- **On device by default.** The on-device engine handles everything: feedback drafting with Apple NaturalLanguage and the system spellchecker, formatting, assignment templates, tutoring and evaluation. Data is stored locally with iOS file protection and can be exported or deleted.
- **Credential isolation.** OCI keys live only on the gateway. Its audit log records purpose, counts and redaction totals, never content.
- **Shared-iPad care.** The sign-in screen never shows reading profiles or support plans.
- **Private support notes.** Teachers' support notes are visible only to teachers.
- **Quest analytics.** They are opt-in, use a fixed event schema with no identifiers, hide groups under 5 (k-anonymity) and add Laplace noise (ε = 1.0 by default). The demo cohort is synthetic.

## 6. Bias and fairness

- **Neutral prompts.** Prompts require inclusive, culturally varied examples and plain language.
- **Fair seed data.** Demo profiles were assigned so that students with ADHD or dyslexia include some of the strongest writers. The seed data does not suggest that learning differences mean weak work.
- **Accommodations aren't penalties.** They change the timing, length and presentation of work, not the grade. Rubric scoring ignores the profile entirely, and the model never sees it.
- **Spelling is weighted modestly.** It counts only within Conventions. The demo support note for a dyslexic student reminds the teacher to assess ideas separately from spelling.

## 7. Safety

- **Concerns.** The Library lets learners keep a concern private, share it anonymously or share it by name.
- **Distress.** Messages showing distress always get fixed guidance pointing to a trusted adult and to **988** (US), never AI counselling.
- **Tutor scope.** The quest tutor stays on topic and will not hand out challenge answers. A leak guard blocks any hint containing the answer.

## 8. Limitations

- **The on-device engine is heuristic.** It uses sentence classification, evidence and counterargument markers, and the system spellchecker. It can miss subtle reasoning or misread unusual structure, which is why every comment goes to a teacher. The OCI path gives richer drafts but goes through the same guards.
- **Fidelity is not comprehension.** The check proves the formats contain the same words. It cannot prove a student understood them, so the formats come with checkpoints, and teachers watch completion by format.
- **Time saved is an estimate.** It depends on the baseline the teacher sets.
- **The OCI path is untested here.** It was tested against the gateway's mock mode only. A live OCI tenancy is needed to verify model quality.
- **Demo shortcuts.** The PIN and the shared-iPad sign-in are demo conveniences. A school deployment would use managed Apple IDs or SSO and server-side storage.
