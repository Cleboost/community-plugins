# AGENTS.md

Instructions for AI coding agents working in this repository.

**Read this file before editing anything.** Most review churn here is not “hard Luau” — it is missing required files, wrong manifest fields, broken translations, or README sections that CI checks literally.

---

## What this repo is

- Community plugin source for [Noctalia](https://github.com/noctalia-dev/noctalia).
- Each plugin is **one top-level directory** with trusted, **unsandboxed Luau**.
- CI validates every plugin on every PR. Treat CI as the contract, not suggestions.

---

## Agent workflow (do this in order)

1. **Scope the change**
   - One plugin directory per PR. Never touch multiple plugin folders in one PR.
   - New plugin or update? If updating, bump `version` in `plugin.toml`.

2. **Read the right docs** (do not guess the API)
   - [Plugin development overview](https://docs.noctalia.dev/v5/plugins/development/)
   - [Manifest (`plugin.toml`)](https://docs.noctalia.dev/v5/plugins/development/manifest/)
   - [Entry types](https://docs.noctalia.dev/v5/plugins/development/entries/)
   - [Declarative UI](https://docs.noctalia.dev/v5/plugins/development/declarative-ui/)
   - [Runtime API](https://docs.noctalia.dev/v5/plugins/development/runtime-api/)
   - [Local dev workflow](https://docs.noctalia.dev/v5/plugins/development/workflow/)
   - Canonical example plugin: [`noctalia/example`](https://github.com/noctalia-dev/official-plugins/tree/main/example)

3. **Copy patterns from a similar plugin in this repo**
   - Launcher: `bitwarden/`, `file-search/`, `zed-provider/`
   - Widget + panel + service: `hassio/`, `todo/`, `eyecare/`
   - Settings + nested translations: `eyecare/`
   - Match naming, file layout, and style of the closest existing plugin.

4. **Fetch API types for Luau editing**
   ```sh
   curl -O https://raw.githubusercontent.com/noctalia-dev/official-plugins/main/noctalia.d.luau
   ```
   This file is gitignored here. Re-fetch when working with newer API symbols. `.vscode/settings.json` and `.luaurc` already point luau-lsp at it.

5. **Implement inside exactly one `<plugin>/` directory**

6. **Run the validator locally before you stop**
   ```sh
   python3 .github/workflows/validate-plugins.py
   python3 -m unittest discover -s .github/workflows -p 'test_*.py'
   ```
   Fix every `error:` line. Do not open a PR hoping CI will teach you what broke.

7. **Open a PR using the GitHub PR template** — see [Submitting a pull request](#submitting-a-pull-request) below.

---

## Submitting a pull request

**Every PR must follow the GitHub pull request template.** GitHub pre-fills the description from [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md) when you open a PR. Do not replace it with a one-line summary or a generic “added plugin” message.

Keep the template structure. Fill in **every section**:

| Template section | What to put there |
| --- | --- |
| **Plugin** | Canonical `id` (`<author>/<plugin>`); tick **New plugin** or **Update** (with `version` bumped) |
| **What it does** | Short user-facing description — what the plugin does and why someone would install it |
| **External dependencies** | Every CLI/service the plugin shells out to (must match `dependencies` in `plugin.toml`); write `None` if self-contained |
| **Testing** | How you tested: which entries, IPC commands, settings; compositor(s) checked; **Noctalia version**; **Plugin API level** (must match `plugin_api` in `plugin.toml`) |
| **Screenshots / Videos** | Required for anything with a visual surface (widget, panel, launcher UI, etc.) |
| **Checklist** | Tick every item that applies; do not delete unchecked boxes — leave them if not applicable |
| **Code review attestation** | Confirm readability, no remote code execution, disclosed network/FS/process side effects, valid license |

Rules for agents creating PRs:

- Use `gh pr create` (or the GitHub UI) so the template body is included automatically.
- If writing the body manually, copy the full template from [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md) and fill it in — do not invent a different format.
- Mark the PR as **Draft** if it is not ready for review (as the template header says).
- **External dependencies** and **Code review attestation** are not optional prose — reviewers use them to judge trust and scope.

---

## Hard rules (CI will fail)

### Repository layout

| Rule | Example |
| --- | --- |
| Plugin lives at `<plugin>/plugin.toml` (depth 1) | `bitwarden/plugin.toml` ✅ — `src/bitwarden/plugin.toml` ❌ |
| Directory name **must equal** the id suffix | id `cleboost/bitwarden` → folder `bitwarden/` |
| id format | `<author>/<plugin>`, both segments lowercase `[a-z0-9][a-z0-9._-]*` |
| Never edit `catalog.toml` | CI generates it |
| No symlinks inside plugin dirs | ship real files |
| One plugin per PR | do not refactor unrelated plugins “while you are here” |

### Required files per plugin

Every published plugin must ship:

```
<plugin>/
  plugin.toml
  README.md
  thumbnail.webp          # exactly 960×540 WebP, ≤ 512 KiB
  translations/en.json
  <entry scripts>.luau
```

Generate thumbnails with the [thumbnail generator](https://assets.noctalia.dev/plugins/thumbnail-generator.html).

### `plugin.toml` gotchas

| Field | Rule |
| --- | --- |
| `version` | Strict semver `MAJOR.MINOR.PATCH`; bump on every plugin change |
| `plugin_api` | Positive integer; use current documented level for new plugins |
| `description` | ≤ **120 characters** (catalog copy, not a feature essay) |
| `tags` | Lowercase, from the allowed list in `README.md` / `validate-plugins.py`; propose new tags in the PR, do not invent them |
| `dependencies` | Exact CLI names; also document them in README `## Requirements` |
| `launcher_provider.prefix` | **Lowercase letters only** (`a-z`), no `/`, no digits, no symbols — users type `/<prefix>` |
| Entry `id` values | Unique across the whole manifest |
| Entry `entry` paths | Relative, inside plugin dir, must exist |
| `setting` `label_key` / `description_key` | Must exist in `translations/en.json` |
| `select` settings | Need `options`, each with `value` + `label_key`; `default` must match a `value` |

Allowed entry types: `widget`, `panel`, `shortcut`, `desktop_widget`, `launcher_provider`, `service`.  
At least **one** entry is required.

Panel sizing: `width` / `height` are positive numbers or `"fill"`; `"fill"` requires `placement = "floating"`.

### `translations/en.json` gotchas

**This trips up agents constantly.**

| ✅ Do | ❌ Don't |
| --- | --- |
| Nest with JSON objects | Flat dotted keys like `"settings.foo.label": "Foo"` |
| Lowercase segments only | `"zh-Hans"`, `"Label"`, `"settings._bad"` |
| Keys: `a-z`, `0-9`, `-`, `_` (no leading `_` in a segment) | Dots inside a single object key |
| Every `label_key` / `description_key` from manifest resolves here | Machine-translated `fr.json`, `de.json`, etc. in your PR |

**Good** (nested):

```json
{
  "settings": {
    "eyecare-sound": {
      "label": "Enable Audio Feedback",
      "description": "Play notification sound when breaks start or finish"
    }
  }
}
```

Manifest reference: `label_key = "settings.eyecare-sound.label"`

**Bad** (flat dotted key — CI rejects):

```json
{
  "settings.eyecare-sound.label": "Enable Audio Feedback"
}
```

Locale value keys inside `options` must also be lowercase (`zh-hans`, not `zh-Hans`).

Agents: **only commit `translations/en.json`**. Other locales come from [Noctalia Translate](https://i18n.noctalia.dev) via `./.tools/i18n-pull.sh` (maintainers / translation workflow).

### `README.md` gotchas

Follow [`README_TEMPLATE.md`](README_TEMPLATE.md). CI parses Markdown literally.

Required:

- `# Title` (h1)
- Short intro (≥ 8 words) under the title
- `## Plugin` — non-empty; must include `` `author/plugin` `` exactly
- `## Usage` — non-empty
- Every entry id from `plugin.toml` appears in backticks in `## Plugin`
- Every panel: exact command `noctalia msg panel-toggle <id>:<panel-id>` somewhere in the README
- Every launcher provider: `` `/<prefix>` `` documented in `## Plugin`
- If `dependencies` non-empty → `## Requirements` mentioning each dependency in backticks
- If any settings exist → `## Settings` (non-empty)

Also:

- **No raw HTML** (use Markdown)
- Headings inside code fences do **not** count as sections

### Luau gotchas

Every `.luau` file:

```luau
--!nonstrict
```

| ✅ Do | ❌ Don't |
| --- | --- |
| `noctalia.getConfig("key")` | `barWidget.getConfig`, `panel.getConfig`, `launcher.getConfig`, `desktopWidget.getConfig` (removed API) |
| Read `noctalia.d.luau` for available APIs | Invent APIs or copy Roblox Luau patterns |
| UTF-8 source files | Minified / obfuscated / generated Luau |
| Declare external commands in `dependencies` | Shell out to undeclared binaries |
| Document network, FS writes, spawned processes in README + PR | Hidden side effects |

Entry scripts expose callbacks documented in the official docs (`onQuery`, `onActivate`, service lifecycle, etc.). Copy the entry type you need from `noctalia/example` or a plugin here — do not improvise entry shapes.

Config reload vs hot reload: `.luau` edits hot-reload; manifest changes need a config reload in Noctalia.

---

## Security and review expectations

Plugins run as the user. Reviewers reject PRs that hide behavior.

You must ensure:

- Code is readable human Luau, not obfuscated
- No downloading and executing remote code
- Every `noctalia.download`, `noctalia.run` / `noctalia.runAsync`, `noctalia.writeFile`, and network call is explained in the PR and README `## Notes` when non-obvious
- `license` in `plugin.toml` matches your rights to publish the code

---

## Local testing (recommended)

Add this checkout as a path source:

```sh
noctalia msg plugins source add dev path /absolute/path/to/community-plugins
noctalia msg plugins enable <author>/<plugin>
```

Test the surfaces you touched: widget, panel toggle command, launcher prefix, shortcut, service behavior, settings changes.

---

## Common CI failures → fix

| Error | Fix |
| --- | --- |
| `id must be '<author>/<folder>'` | Align `id` suffix with directory name |
| `prefix must contain only lowercase letters` | `bw` not `bw2` or `/bw` |
| `description is N characters` | Shorten to ≤ 120 |
| `tags[N] 'foo' is not an allowed tag` | Pick from allowed list or propose new tag in PR |
| `label_key references missing translations/en.json key` | Add nested key or fix typo |
| `invalid translation key format` | Remove dotted flat keys; nest objects; lowercase only |
| `missing panel IPC command` | Add exact `noctalia msg panel-toggle ...` line |
| `thumbnail.webp is WxH` | Re-export 960×540 WebP from generator |
| `'barWidget.getConfig' was removed` | Use `noctalia.getConfig` |
| `missing required '## Settings' section` | Add settings docs when manifest has settings |
| `unknown root field` | Only use fields defined in official manifest docs |

When stuck, read the validator source: `.github/workflows/validate-plugins.py` — it **is** the spec.

---

## PR checklist (copy before submitting)

- [ ] PR description follows [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md) — all sections filled, checklist and attestation included
- [ ] Exactly **one** plugin directory changed
- [ ] `version` bumped (if updating existing plugin)
- [ ] `plugin.toml`, `README.md`, `thumbnail.webp`, `translations/en.json` present and valid
- [ ] `catalog.toml` **not** edited
- [ ] `python3 .github/workflows/validate-plugins.py` passes locally
- [ ] README lists every entry id, panel command, launcher prefix, dependency, and setting
- [ ] No non-English translation files added by the agent
- [ ] **External dependencies** and **Code review attestation** sections in the PR are complete and accurate
- [ ] Visual plugin: screenshots or video attached in **Screenshots / Videos**

---

## What not to do (saves everyone time)

- Do not edit unrelated plugins, root CI, or `catalog.toml` “to be helpful”
- Do not add `__pycache__`, `.pyc`, build artifacts, or secrets
- Do not commit `noctalia.d.luau` (gitignored; fetch locally)
- Do not add machine-translated locale files
- Do not use HTML in README
- Do not use entry-specific `getConfig` aliases
- Do not invent manifest fields, tags, or APIs not in the docs
- Do not submit a PR without running the validator
- Do not open a PR with a blank or custom description — use [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md)

---

## Quick reference links

| Resource | URL |
| --- | --- |
| Docs home | https://docs.noctalia.dev |
| Plugin development | https://docs.noctalia.dev/v5/plugins/development/ |
| Example plugin | https://github.com/noctalia-dev/official-plugins/tree/main/example |
| API types (`noctalia.d.luau`) | https://raw.githubusercontent.com/noctalia-dev/official-plugins/main/noctalia.d.luau |
| Thumbnail generator | https://assets.noctalia.dev/plugins/thumbnail-generator.html |
| README template | [`README_TEMPLATE.md`](README_TEMPLATE.md) |
| PR template | [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md) |
| Validator | [`.github/workflows/validate-plugins.py`](.github/workflows/validate-plugins.py) |
| Human-oriented repo guide | [`README.md`](README.md) |

When official docs and this file disagree, **the validator + official docs win**. Update this file if you find a real mismatch.
