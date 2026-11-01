# Contextual translation refactor

## Outcome

Improve the OpenAI translation prompt so nearby context resolves ambiguity while the output contains only a natural translation of the selection. Use `gpt-6-luna` with no reasoning effort for fast Chat Completions responses.

## Files and changes

- `ai-translate.koplugin/config.lua`: change only the built-in OpenAI model default to `gpt-6-luna`.
- `ai-translate.koplugin/translator.lua`: strengthen `Translator.prompt(selected, context, target_language)` for meaning, references, idioms, terminology, tone, natural target-language wording, and strict limits on source content and output. Preserve the current prompt for Gemini and custom providers, and add `reasoning_effort = "none"` only to OpenAI request bodies. Keep public signatures and response parsing unchanged.
- `tests/pure_spec.lua`: assert the new OpenAI model and request field, prompt requirements, and absence of the field and prompt changes for Gemini/custom.

## Verification

Run `luajit tests/pure_spec.lua`, LuaJIT bytecode syntax checks for plugin Lua files, and inspect the changed request paths. Kindle network and visual behavior require a later device test; no device is currently mounted.

## Outcome and limitations

Implemented. `luajit tests/pure_spec.lua` passed, and every plugin Lua file passed LuaJIT bytecode syntax checks. Tests assert the OpenAI model, reasoning field, and prompt constraints; Gemini and custom request behavior remains unchanged. The updated plugin has not been installed on or tested with the Kindle. Live API behavior, account access to `gpt-6-luna`, translation quality, and latency remain unverified.

The OpenAI prompt was subsequently refined to preserve formality, allow faithful rephrasing, and treat selected text and context as data rather than instructions. The same tests and syntax checks passed after that change.

Later product decisions broadened the plugin into contextual translation with brief notes. All providers now share one prompt, and the output is requested as plain text for KOReader. Version `0.3.2` was installed on the Kindle and the copied files were verified. The user confirmed that the OpenAI translation worked well on the Kindle. Gemini and custom-provider results still need device testing. The original OpenAI-only scope above records the initial refactor request.
