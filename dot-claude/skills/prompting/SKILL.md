---
name: prompting
description: >
  Load this skill when writing or editing a prompt intended for an LLM —
  including system prompts, user instructions, few-shot examples, or any text
  whose primary purpose is to direct model behavior. Do not load for general
  documentation, code comments, or user-facing copy.

  Examples of when to load this skill:
  - "write a system prompt for a customer support agent"
  - "improve this prompt so the model follows instructions more reliably"
  - "add few-shot examples to this prompt"
  - "rewrite this prompt to reduce hallucinations"
  - "help me structure this prompt for a coding assistant"
  - The text you are editing is intended to direct model behavior — even if it lives inside a `.py`, `.ts`, or other source file
---

# Prompting Philosophy

## Assume zero context

Write as if the model knows nothing about your system, your users, or the problem domain. Everything the model needs to behave correctly must be stated explicitly. If you find yourself thinking "it should be obvious that...", write it down.

## Positive instructions over negative

Tell the model what to do, not just what to avoid. "Respond in 1–3 sentences using a professional tone" outperforms "don't be too long or too formal." Negative instructions eliminate one failure mode and leave the model guessing at what to do instead.

Negative constraints have their place, but exhaust positive instructions first.

## Explain the why behind constraints

Include the reason when you add a rule. "Never mention competitor pricing, because this creates legal liability" is significantly more robust than "never mention competitor pricing." When the model understands the intent, it can generalize correctly to edge cases you did not anticipate.

## Start simple

The best prompt is the shortest one that passes your evals. Add complexity only when you observe a specific failure. Every additional instruction adds cognitive load for the model and maintenance burden for you.

---

## Standard structure

Not every prompt needs all sections, but when a section is present, keep this order:

1. **IDENTITY** — Who is this agent? What role?
2. **OBJECTIVE** — What is this prompt's single job?
3. **CONTEXT** — What runtime data does the agent have access to?
4. **INSTRUCTIONS** — How to accomplish the objective
5. **CONSTRAINTS** — Hard rules and guardrails
6. **OUTPUT FORMAT** — Structure, length, tone
7. **EXAMPLES** — Worked input → output pairs (when needed)

Use level-1 ALL CAPS headings for top-level sections. This helps both humans and models parse structure at a glance.

## Define scope boundaries

State what the prompt IS and IS NOT responsible for. Without explicit boundaries, the model will try to be helpful by overstepping into adjacent concerns.

```
You are NOT responsible for:
- Recommending specific products
- Capturing contact information
```

## Use numbered steps for multi-step logic

When the model needs to do multiple things in order, use numbered steps. Do not rely on it to infer order of operations from a prose paragraph.

## Constraint hierarchies

When constraints can conflict, make the priority order explicit with a numbered hierarchy where lower numbers always win:

```
When guidelines conflict, follow this priority order:
1. Factual accuracy — never alter dates, prices, or names
2. Brevity — keep responses to 1–4 sentences
3. Tone — match the persona's communication style
```

---

## Specify the output contract

Always state explicitly what the model should produce — format, length, structure, and valid values. Never rely on the model to infer these. If downstream code parses the output, the schema must be locked down completely.

For JSON: provide the exact schema with field names and types.
For text: specify length, tone, and what to include or exclude.
For classification: list the exact valid labels.

## Define fallback behavior

Specify what the model should do when things go wrong: required variable is empty, input is unintelligible, no classification matches, a tool call fails. A prompt that only defines the happy path will behave unpredictably on failure cases.

---

## Wrap injected data in XML tags

Use XML-style tags to create clear boundaries between instructions and dynamic content. This prevents the model from confusing data with instructions and protects against prompt injection.

```xml
<conversation_history>
{{history}}
</conversation_history>
```

Use descriptive, lowercase_snake_case tag names. Avoid generic names like `<data>` or `<input>`.

---

## Examples

Include examples when:
- The output format is complex or unusual
- The classification task has subtle distinctions
- Tone and style are hard to capture in abstract instructions alone
- You have observed the model misinterpreting instructions without them

Do not include examples when the task is straightforward and the output format is simple.

### Example design

- **Cover edge cases, not obvious cases.** If every example is clear-cut, the model will struggle on real ambiguous inputs.
- **Include reasoning for classification tasks.** Showing *why* an example gets a label teaches the decision boundary, not just the mapping.
- **Use 3–5 diverse examples.** Fewer risks overfitting on surface patterns; more usually provides diminishing returns.
- **Match the real distribution.** Overrepresenting rare categories in examples biases the model toward them.

Wrap examples in `<example>` tags, and a group of examples in `<examples>` tags.

---

## Avoid urgency overload

Current-generation models are instruction-following by default. Overusing `CRITICAL`, `MUST`, `NEVER`, and `ALWAYS` causes overcorrection and makes prompts harder to maintain. Reserve these markers for rules where violation would cause real harm — safety violations, data leakage, legal issues. If everything is critical, nothing is.

Prefer:
```
When the customer asks about pricing, route to the sales node. Do not answer
pricing questions directly, because pricing varies and only the sales team
has current figures.
```

Over:
```
CRITICAL: You MUST ALWAYS route to sales for pricing. NEVER respond directly.
```

## Audit for instruction bloat

Prompts accumulate rules over time. Periodically review for:
- Rules that duplicate each other in different words
- Rules added to fix a specific bug now handled by the model's default behavior
- Examples that are redundant with other examples

When in doubt, remove a rule and test whether the model still behaves correctly. The answer is often yes.
