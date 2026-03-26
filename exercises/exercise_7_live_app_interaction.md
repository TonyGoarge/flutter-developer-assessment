# Exercise 7: Live App Interaction — Find the Visual Bugs

| Detail     | Value          |
|------------|----------------|
| **Time**   | ~25 minutes    |
| **Points** | 20             |
| **Type**   | Run & Report   |

---

## Why This Exercise Exists

Some bugs can **only** be found by running the app and interacting with it.
Reading code is not enough. This exercise tests your eye for UI/UX quality
and your ability to report bugs clearly.

---

## Task

Run the assessment app (`flutter run`) and interact with every screen.
Find **at least 5 visual/UX bugs** that are **not visible by reading code alone**.

For each bug you find, create a report in `answers/visual_bugs_report.md` with:

```
## Bug #1: [Short title]
- **Where:** [Screen/widget where it occurs]
- **Steps to reproduce:**
  1. Step 1
  2. Step 2
  3. ...
- **Expected behavior:** [What should happen]
- **Actual behavior:** [What actually happens]
- **Screenshot:** [Attach or link a screenshot]
- **Severity:** Critical / High / Medium / Low
- **Proposed fix:** [Your suggested code fix or approach]
```

---

## What to Look For

These categories of bugs exist in the app:

1. **Layout issues** — Overflow, clipping, incorrect alignment on different screen sizes
2. **Animation/transition issues** — Jank, flicker, abrupt transitions
3. **Input handling** — Keyboard overlap, unresponsive touch targets, focus issues
4. **State issues** — Stale data, incorrect loading states, missing empty states
5. **Platform issues** — Safe area violations, status bar overlap, notch handling

---

## How to Test

- Run on **at least 2 different screen sizes** (use emulator device picker)
- Test with **keyboard open** on input fields
- Test **rotation** (landscape mode)
- Test **dark mode** vs light mode
- Test with **large font/accessibility settings** enabled
- Scroll quickly, tap rapidly, navigate back and forth

---

## Submission

1. Create `answers/visual_bugs_report.md` with your bug reports
2. Include screenshots in an `answers/screenshots/` directory (or link to them)
3. Commit everything to your repo

---

## Evaluation Criteria

| Criterion | Points | What We Look For |
|-----------|--------|------------------|
| Bugs found (min 5) | 8 | Real bugs, not false positives. Quality over quantity. |
| Report clarity | 4 | Clear reproduction steps that we can follow |
| Screenshots | 3 | Visual evidence of each bug |
| Fix proposals | 5 | Practical, correct fixes — not "just add padding" |

---

## Important

- **AI cannot do this exercise.** It requires running the app and visually inspecting behavior.
- Don't just report code-level issues you found by reading — those belong in exercises 1-5.
- Focus on things that a **user** would notice and report.
