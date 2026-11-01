# Contextual AI Translation for KOReader

A small, standalone KOReader plugin that translates selected text using nearby book context. It starts with a natural translation and adds a brief note when a nuance helps the reader. It does not alter the book text.

## Install

Copy `ai-translate.koplugin` into KOReader's `plugins` directory and restart KOReader.

## Configure

Open **AI Translate** in KOReader's Tools menu. Choose a provider and target language, then enter the provider's API key. Gemini and OpenAI use built-in endpoints and models; a custom OpenAI-compatible provider needs an HTTPS endpoint and model name. The plugin version is shown in this settings window.

The API key is saved in KOReader's `settings/ai-translate.lua` on the device. Keep that file private. The plugin sends only the selection and a limited amount of nearby text, never the entire book.

## Use

Select a word or passage and tap **Translate** in the selection or dictionary popup. The request can be cancelled from the progress dialog. Results appear in KOReader's native text viewer.

## Test

Run `luajit tests/pure_spec.lua` for the isolated Lua tests. Final UI and network checks require a Kindle running KOReader.
