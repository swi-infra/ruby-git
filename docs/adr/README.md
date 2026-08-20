# Architecture Decision Records

Each file here records one decision: what was decided, and why. ADRs are the durable
half of a plan. A plan says what we intend to do next and goes stale the moment reality
diverges from it; a decision stays true even when the work it justified changes shape.

Where each kind of thing lives:

| Artifact | Holds | Home |
| --- | --- | --- |
| Issue | what and whether, current state | GitHub |
| ADR | why, decided once | `docs/adr/` |
| Skill | how, normative policy | `.github/skills/` |

An ADR is **superseded, never edited**. If a decision is reversed, write a new ADR that
says so and add a `Superseded by ADR-NNNN` line to the old one. Do not rewrite history
in place — the point of the record is that it tells you what was believed at the time.

## Adding one

Name the file `NNNN-slug.md`, where `NNNN` is one past the highest number already here.
Keep it short. A paragraph is a legitimate ADR; the value is in recording that a
decision was made and why, not in filling out sections. Add **Considered options** or
**Consequences** only when the rejected alternative or the downstream effect is worth
remembering on its own.

Write an ADR when all three are true: the decision is hard to reverse, a future reader
would otherwise wonder why the code looks this way, and there was a real alternative
that was rejected for specific reasons.
