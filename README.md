# build_prompt.sh

[🇷🇺 Русский](#-русский) · [🇬🇧 English](#-english)

---

## 🇷🇺 Русский

Интерактивный bash-скрипт для сборки промптов в схемах **RCT** и **COSTAR**.
Задаёт наводящие вопросы с примерами структуры ожидаемых данных, собирает
готовый промпт в размеченном текстовом виде **или в JSON** и (по желанию)
копирует его в буфер обмена или сохраняет в файл.

### Зачем это нужно

Схемы RCT и COSTAR помогают формулировать промпты структурно и предсказуемо.
Скрипт избавляет от ручного копипаста шаблонов и подсказывает, что писать в
каждом поле. По умолчанию формат вывода — **текстовые блоки с явными метками**
(`Role:`, `Context:`, `Task:` и т. д.): это самый надёжный способ подачи
промпта в обычный чат с ИИ. Для программной обработки (пайпы в `jq`, вызовы
API, юнит-тесты) предусмотрен флаг `--json`.

### Требования

- `bash` 4.0+
- Любая из утилит для работы с буфером обмена (опционально):
  `pbcopy` (macOS), `wl-copy` (Wayland), `xclip` или `xsel` (X11), `clip.exe` (WSL).
  Если ни одной нет — скрипт просто выведет промпт в консоль.

### Установка

```bash
git clone <repo-url>
cd <repo-dir>
chmod +x build_prompt.sh
```

### Использование

```bash
./build_prompt.sh
```

Дальше скрипт проведёт по шагам:

1. **Выбор схемы** — `RCT` или `COSTAR` (через меню `select`, либо сразу
   флагом `--scheme`).
2. **Заполнение полей** — для каждого пункта показывается заголовок и пример
   структуры ожидаемых данных. Обязательные поля не пропускают пустой ввод.
3. **Вывод готового промпта** — в текстовом или JSON-виде.
4. **Сохранение в файл** (необязательно, только в текстовом режиме) —
   введите путь или нажмите Enter.
5. **Копирование в буфер обмена** (только в текстовом режиме) — если
   доступна подходящая утилита.

### Параметры командной строки

| Флаг                     | Описание                                                          |
|--------------------------|-------------------------------------------------------------------|
| `--json`                 | Вывести результат в JSON (по умолчанию — размеченный текст)       |
| `--scheme RCT\|COSTAR`   | Задать схему заранее и пропустить интерактивное меню              |
| `-h`, `--help`           | Показать справку                                                  |

Примеры:

```bash
# Интерактивный режим, текстовый вывод
./build_prompt.sh

# Сразу выбрать схему, текстовый вывод
./build_prompt.sh --scheme COSTAR

# JSON на stdout — удобно для пайпов и автотестов
./build_prompt.sh --json --scheme RCT | jq .
```

Пример JSON-вывода (схема RCT):

```json
{
  "scheme": "RCT",
  "role": "Ты — senior DevOps-инженер с 10-летним опытом.",
  "context": "Мы мигрируем монолит на микросервисы.",
  "task": "Составь пошаговый план миграции.",
  "format": "Нумерованный список, 5–7 пунктов."
}
```

В JSON-режиме **все приглашения ввода и служебные сообщения идут в stderr**,
а сам JSON — только в stdout. Это позволяет безопасно перенаправлять вывод
(`> prompt.json`) и использовать пайпы (`| jq`, `| python -m json.tool`).
Копирование в буфер и сохранение файла в JSON-режиме не предлагаются, так
как для этого достаточно обычного перенаправления.

### Схемы

#### RCT

Минималистичная схема из трёх (опционально четырёх) блоков:

| Поле      | Назначение                                                    | Обязательность |
|-----------|---------------------------------------------------------------|----------------|
| `Role`    | Кто такой ИИ, какую роль играет                               | обязательно    |
| `Context` | Фон, который ИИ не может знать                                | обязательно    |
| `Task`    | Конкретная задача                                             | обязательно    |
| `Format`  | Формат и объём вывода                                         | опционально    |

#### COSTAR

Детализированная схема из шести блоков:

| Поле        | Назначение                                    | Обязательность |
|-------------|-----------------------------------------------|----------------|
| `Context`   | Подробный фоновый контекст                    | обязательно    |
| `Objective` | Цель ответа                                   | обязательно    |
| `Style`     | Стиль изложения                               | обязательно    |
| `Tone`      | Эмоциональная окраска                         | обязательно    |
| `Audience`  | Целевая аудитория                             | обязательно    |
| `Response`  | Формат, объём и структура вывода              | обязательно    |

### Пример сессии (RCT, текстовый режим)

```
Какую схему промпта использовать?
1) RCT
2) COSTAR
Ваш выбор: 1

── Role — кто такой ИИ ──
Пример: Ты — senior DevOps-инженер с 10-летним опытом.
> Ты — технический писатель, специализирующийся на документации для разработчиков.

── Context — фон, который ИИ не знает ──
Пример: Мы мигрируем монолит на микросервисы. Команда 5 человек, срок — 3 месяца.
> Мы выпускаем SDK v2.0; нужно обновить раздел «Быстрый старт».

── Task — конкретная задача ──
Пример: Составь пошаговый план миграции.
> Перепиши раздел «Быстрый старт», добавив проверку версии SDK.

── Format — формат вывода ──
Пример: Нумерованный список, 5–7 пунктов, до 200 слов, без воды.
> (Enter — пропустить)

══════════════ ГОТОВЫЙ ПРОМПТ (RCT) ══════════════
Role: Ты — технический писатель, специализирующийся на документации для разработчиков.
Context: Мы выпускаем SDK v2.0; нужно обновить раздел «Быстрый старт».
Task: Перепиши раздел «Быстрый старт», добавив проверку версии SDK.
══════════════════════════════════════════════════════

Сохранить в файл? Введите путь или Enter, чтобы пропустить:
✓ Скопировано в буфер обмена.
```

### Настройка

- **Свои примеры в подсказках** — отредактируйте строки с
  `read_field ... "Пример: ..."` в разделе сбора полей.
- **Добавить новую схему** — скопируйте блок `if [[ "$SCHEME" == "..." ]]`,
  добавьте пункт в `select` и соответствующие `add_field`-вызовы.
- **Другие утилиты буфера** — расширьте функцию `copy_to_clipboard()`.
- **Новые флаги** — расширьте блок парсинга аргументов в начале скрипта.

### Ограничения

- Скрипт не отправляет запрос в ИИ — он только **готовит текст промпта**.
- Не поддерживает Windows `cmd.exe` напрямую; в Windows используйте WSL
  или Git Bash.
- JSON-экранирование покрывает `\`, `"`, `\n`, `\r`, `\t`; прочие
  управляющие символы проходят как есть (для типичного пользовательского
  ввода этого достаточно).

### Лицензия

MIT.

---

## 🇬🇧 English

An interactive bash script that builds prompts using the **RCT** and **COSTAR**
frameworks. It walks you through each field with a hint and an example of the
expected data shape, assembles a ready-to-paste prompt in **labeled text
format or as JSON**, and optionally copies it to the clipboard or saves it to
a file.

### Why

RCT and COSTAR help you write structured, predictable prompts. This script
removes the copy-paste overhead and prompts you for what to put in each field.
By default, the output format is **plain text blocks with explicit labels**
(`Role:`, `Context:`, `Task:`, etc.) — the most reliable way to feed a prompt
into a regular AI chat. For programmatic use (piping into `jq`, API calls,
unit tests) there is a `--json` flag.

### Requirements

- `bash` 4.0+
- Any one of these clipboard utilities (optional):
  `pbcopy` (macOS), `wl-copy` (Wayland), `xclip` or `xsel`(X11), `clip.exe` (WSL).
  If none is available, the script just prints the prompt to stdout.

### Install

```bash
git clone <repo-url>
cd <repo-dir>
chmod +x build_prompt.sh
```

### Usage

```bash
./build_prompt.sh
```

The script then walks you through:

1. **Scheme selection** — `RCT` or `COSTAR` (via the `select` menu, or up front
   with `--scheme`).
2. **Field entry** — each field shows a heading and an example of the expected
   data shape. Required fields reject empty input.
3. **Printing** the assembled prompt — as labeled text or JSON.
4. **Optional file save** (text mode only) — type a path or press Enter.
5. **Optional clipboard copy** (text mode only) — if a supported utility is
   found.

### Command-line options

| Flag                     | Description                                                        |
|--------------------------|--------------------------------------------------------------------|
| `--json`                 | Print the result as JSON (default: labeled text)                   |
| `--scheme RCT\|COSTAR`   | Pick the scheme up front and skip the interactive menu             |
| `-h`, `--help`           | Show usage                                                         |

Examples:

```bash
# Interactive, text output
./build_prompt.sh

# Skip the menu, text output
./build_prompt.sh --scheme COSTAR

# JSON on stdout — handy for pipelines and tests
./build_prompt.sh --json --scheme RCT | jq .
```

Sample JSON output (RCT scheme):

```json
{
  "scheme": "RCT",
  "role": "You are a senior DevOps engineer with 10 years of experience.",
  "context": "We're migrating a monolith to microservices.",
  "task": "Draft a step-by-step migration plan.",
  "format": "Numbered list, 5–7 items."
}
```

In JSON mode, **all prompts and service messages go to stderr**, and only the
JSON itself goes to stdout. This makes output redirection (`> prompt.json`) and
pipes (`| jq`, `| python -m json.tool`) safe. Clipboard copy and file saving
are not offered in JSON mode — plain shell redirection is enough.

### Schemes

#### RCT

A minimal three- (optionally four-) field scheme:

| Field     | Purpose                                       | Required |
|-----------|-----------------------------------------------|----------|
| `Role`    | Who the AI is / what role it plays            | yes      |
| `Context` | Background the AI cannot otherwise know       | yes      |
| `Task`    | The specific task                             | yes      |
| `Format`  | Output format and length                      | optional |

#### COSTAR

A detailed six-field scheme:

| Field       | Purpose                                  | Required |
|-------------|------------------------------------------|----------|
| `Context`   | Detailed background context              | yes      |
| `Objective` | The goal of the response                 | yes      |
| `Style`     | Writing style                            | yes      |
| `Tone`      | Emotional tone                           | yes      |
| `Audience`  | Target audience                          | yes      |
| `Response`  | Output format, length, and structure     | yes      |

### Example session (RCT, text mode)

```
Which prompt scheme to use?
1) RCT
2) COSTAR
Your choice: 1

── Role — who the AI is ──
Example: You are a senior DevOps engineer with 10 years of experience.
> You are a technical writer specializing in developer documentation.

── Context — background the AI cannot know ──
Example: We're migrating a monolith to microservices. Team of 5, 3-month deadline.
> We're shipping SDK v2.0 and need to update the Quick Start section.

── Task — the concrete task ──
Example: Draft a step-by-step migration plan.
> Rewrite the Quick Start section, adding a version check.

── Format — output format ──
Example: Numbered list, 5–7 items, up to 200 words, no filler.
> (Enter to skip)

══════════════ READY PROMPT (RCT) ══════════════
Role: You are a technical writer specializing in developer documentation.
Context: We're shipping SDK v2.0 and need to update the Quick Start section.
Task: Rewrite the Quick Start section, adding a version check.
══════════════════════════════════════════════════════

Save to file? Enter a path or press Enter to skip:
✓ Copied to clipboard.
```

### Customization

- **Own hints/examples** — edit the `read_field ... "Example: ..."` lines in
  the field-entry section.
- **Add a new scheme** — copy an `if [[ "$SCHEME" == "..." ]]` block, add a
  menu entry to `select`, and the corresponding `add_field` calls.
- **Other clipboard utilities** — extend `copy_to_clipboard()`.
- **New flags** — extend the argument-parsing block at the top of the script.

### Limitations

- The script does **not** call any AI — it only prepares the prompt text.
- Windows `cmd.exe` is not supported directly; use WSL or Git Bash on Windows.
- JSON escaping covers `\`, `"`, `\n`, `\r`, `\t`; other control characters
  pass through as-is (fine for typical user input).

### License

MIT.
