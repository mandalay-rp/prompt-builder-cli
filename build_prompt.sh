#!/usr/bin/env bash
# build_prompt.sh — интерактивный генератор промптов по схемам RCT / COSTAR
set -euo pipefail

OUTPUT_JSON=0
SCHEME=""

usage() {
    cat >&2 <<'EOF'
Usage: build_prompt.sh [OPTIONS]

Интерактивный генератор промптов по схемам RCT и COSTAR.

Options:
  --json               Вывести результат в JSON (по умолчанию — размеченный текст)
  --scheme RCT|COSTAR  Заранее выбрать схему (пропустить меню)
  -h, --help           Показать эту справку

Примеры:
  ./build_prompt.sh
  ./build_prompt.sh --scheme COSTAR
  ./build_prompt.sh --json --scheme RCT | jq .
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) OUTPUT_JSON=1; shift ;;
        --scheme)
            if [[ $# -lt 2 ]]; then
                echo "Ошибка: --scheme требует значение (RCT или COSTAR)" >&2
                exit 2
            fi
            SCHEME="$2"; shift 2 ;;
        --scheme=*) SCHEME="${1#*=}"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Неизвестный аргумент: $1" >&2; usage; exit 2 ;;
    esac
done

if [[ -n "$SCHEME" && "$SCHEME" != "RCT" && "$SCHEME" != "COSTAR" ]]; then
    echo "Ошибка: --scheme должен быть RCT или COSTAR" >&2
    exit 2
fi

die() { exit 0; }

F_KEYS=()
F_VALS=()
add_field() { F_KEYS+=("$1"); F_VALS+=("$2"); }

read_field() {
    local __var="$1" __label="$2" __example="$3" __req="${4:-обязательно}"
    local __val=""
    while :; do
        printf '\n── %s ──\n' "$__label" >&2
        printf 'Пример: %s\n' "$__example" >&2
        if [[ "$__req" == "опционально" ]]; then
            printf '> (Enter — пропустить) ' >&2
        else
            printf '> ' >&2
        fi
        read -r __val || die
        if [[ -n "$__val" ]]; then break; fi
        if [[ "$__req" == "опционально" ]]; then break; fi
        printf '⚠ Поле обязательно, введите значение.\n' >&2
    done
    printf -v "$__var" '%s' "$__val"
}

copy_to_clipboard() {
    local text="$1"
    if   command -v pbcopy               >/dev/null 2>&1; then printf '%s' "$text" | pbcopy
    elif command -v xclip                >/dev/null 2>&1; then printf '%s' "$text" | xclip -selection clipboard
    elif command -v xsel                 >/dev/null 2>&1; then printf '%s' "$text" | xsel --clipboard --input
    elif command -v termux-clipboard-set >/dev/null 2>&1; then printf '%s' "$text" | termux-clipboard-set
    elif command -v clip.exe             >/dev/null 2>&1; then printf '%s' "$text" | clip.exe
    elif command -v wl-copy              >/dev/null 2>&1; then printf '%s' "$text" | wl-copy
    else return 1
    fi
}

json_escape() {
    local s="$1"
    s=${s//\\/\\\\}
    s=${s//\"/\\\"}
    s=${s//$'\n'/\\n}
    s=${s//$'\r'/\\r}
    s=${s//$'\t'/\\t}
    printf '%s' "$s"
}

# ───── Выбор схемы ─────
if [[ -z "$SCHEME" ]]; then
    printf 'Какую схему промпта использовать?\n' >&2
    PS3='Ваш выбор: '
    select SCHEME in "RCT" "COSTAR"; do
        if [[ -n "${SCHEME:-}" ]]; then break; fi
        printf 'Введите 1 или 2.\n' >&2
    done
fi

# ───── Сбор полей ─────
if [[ "$SCHEME" == "RCT" ]]; then
    read_field ROLE "Role — кто такой ИИ" \
        "Ты — senior DevOps-инженер с 10-летним опытом."
    read_field CONTEXT "Context — фон, который ИИ не знает" \
        "Мы мигрируем монолит на микросервисы. Команда 5 человек, срок — 3 месяца."
    read_field TASK "Task — конкретная задача" \
        "Составь пошаговый план миграции."
    read_field FORMAT "Format — формат вывода" \
        "Нумерованный список, 5–7 пунктов, до 200 слов, без воды." \
        "опционально"

    add_field "scheme"  "RCT"
    add_field "role"    "$ROLE"
    add_field "context" "$CONTEXT"
    add_field "task"    "$TASK"
    if [[ -n "$FORMAT" ]]; then add_field "format" "$FORMAT"; fi
else
    read_field CONTEXT "Context — фоновый контекст" \
        "Мы запускаем SaaS-продукт для малого бизнеса; нужен пост для LinkedIn."
    read_field OBJECTIVE "Objective — цель ответа" \
        "Написать пост, который генерирует заявки на демо."
    read_field STYLE "Style — стиль изложения" \
        "Профессиональный, но живой; без канцелярита."
    read_field TONE "Tone — тональность" \
        "Уверенный и воодушевляющий."
    read_field AUDIENCE "Audience — целевая аудитория" \
        "Владельцы малого бизнеса, не знакомые с технологиями."
    read_field RESPONSE "Response — формат и объём ответа" \
        "Текст поста до 150 слов, с призывом к действию в конце."

    add_field "scheme"    "COSTAR"
    add_field "context"   "$CONTEXT"
    add_field "objective" "$OBJECTIVE"
    add_field "style"     "$STYLE"
    add_field "tone"      "$TONE"
    add_field "audience"  "$AUDIENCE"
    add_field "response"  "$RESPONSE"
fi

# ───── Вывод ─────
if (( OUTPUT_JSON )); then
    n=${#F_KEYS[@]}
        printf '{\n'
        for ((i=0; i<n; i++)); do
            k="${F_KEYS[$i]}"
            v=$(json_escape "${F_VALS[$i]}")
            if (( i < n-1 )); then
                printf '  "%s": "%s",\n' "$k" "$v"
            else
                printf '  "%s": "%s"\n' "$k" "$v"
            fi
        done
        printf '}\n'
        exit 0
fi

# ───── Текстовый режим ─────
PROMPT=""
if [[ "$SCHEME" == "RCT" ]]; then
    PROMPT+="Role: $ROLE"$'\n'
    PROMPT+="Context: $CONTEXT"$'\n'
    PROMPT+="Task: $TASK"$'\n'
    if [[ -n "$FORMAT" ]]; then PROMPT+="Format: $FORMAT"$'\n'; fi
else
    PROMPT+="Context: $CONTEXT"$'\n'
    PROMPT+="Objective: $OBJECTIVE"$'\n'
    PROMPT+="Style: $STYLE"$'\n'
    PROMPT+="Tone: $TONE"$'\n'
    PROMPT+="Audience: $AUDIENCE"$'\n'
    PROMPT+="Response: $RESPONSE"$'\n'
fi

printf '\n══════════════ ГОТОВЫЙ ПРОМПТ (%s) ══════════════\n' "$SCHEME" >&2
printf '%s' "$PROMPT"
printf '══════════════════════════════════════════════════════\n' >&2

printf '\nСохранить в файл? Введите путь или Enter, чтобы пропустить: ' >&2
read -r SAVE_PATH || true
if [[ -n "${SAVE_PATH:-}" ]]; then
    printf '%s' "$PROMPT" > "$SAVE_PATH"
    printf '✓ Сохранено: %s\n' "$SAVE_PATH" >&2
fi

if copy_to_clipboard "$PROMPT"; then
    printf '✓ Скопировано в буфер обмена.\n' >&2
else
    printf 'ℹ Буфер обмена недоступен.\n' >&2
fi
