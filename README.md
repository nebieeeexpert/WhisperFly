# WhisperFly

> 🇬🇧 [English](#english) · 🇷🇺 [Русский](#русский)

---

## English

A macOS menu-bar push-to-talk dictation app with **free** cloud-based speech recognition.  
Fork of [qwenwishper](https://github.com/hukopo/qwenwishper) — replaces all local model inference with lightweight API calls.

### Features

- **Push-to-talk** via ⌘⇧Space global hotkey (configurable)
- **Two free transcription backends:**
  - 🟢 **Groq Whisper Large V3** — dedicated ASR, 100+ languages including Russian
  - 🟢 **Google Gemini 2.5 Flash** (via OpenRouter) — multimodal, free tier
- **AI text rewriting** — cleanup, punctuation fix, or translate-to-English via Gemini
- **Read aloud** — optionally speak back the transcribed text using the system TTS voice
- **Auto-paste** into the focused app (Accessibility API with clipboard fallback)
- **Localized UI** — the app automatically adapts to your system language (English, Russian, German, French, Spanish, Japanese, Chinese, Korean, Italian, Hindi)
- No local model downloads, no GPU required

### Setup

1. Get free API keys:
   - Groq: [console.groq.com](https://console.groq.com) → API Keys
   - OpenRouter: [openrouter.ai/keys](https://openrouter.ai/keys)

2. Create `.env` in the project root:
   ```
   GROQ_API_KEY=gsk_xxx
   OPENROUTER_API_KEY=sk-or-v1-xxx
   ```

3. Build & run:
   ```bash
   swift build
   swift run WhisperFly
   ```

4. Grant **Microphone** and **Accessibility** permissions when prompted.

### Usage

| Action | Result |
|---|---|
| Press **⌘⇧Space** | Start recording |
| Press **⌘⇧Space** again | Stop and transcribe |
| Click menu bar icon | See status, last result, settings |
| Open **Settings → General** | Change backend, language, rewrite mode, read-aloud |
| Open **Settings → API Keys** | Enter Groq / OpenRouter keys |
| Open **Settings → Advanced** | Tune max recording duration and paste delay |

### Requirements

- macOS 14 (Sonoma) or later
- Swift 6 toolchain
- Internet connection (all recognition is done via API)

### Removing macOS Quarantine (xattr)

macOS marks apps downloaded from the internet with a quarantine flag, which can trigger **"app is damaged"** or **Gatekeeper blocked** warnings. To remove this flag, run the following command in Terminal:

```bash
xattr -cr /Applications/WhisperFly.app
```

**What it does:**
- `xattr` — manipulates extended attributes on files and directories
- `-c` — **clears** all extended attributes (including `com.apple.quarantine`)
- `-r` — applies **recursively** to all files inside the `.app` bundle

**Step-by-step:**
1. Move `WhisperFly.app` to `/Applications` (or wherever you keep it)
2. Open **Terminal** (`⌘Space` → type *Terminal*)
3. Run the command above (adjust path if the app is elsewhere, e.g. `~/Desktop/WhisperFly.app`)
4. Launch the app normally

> **Why is this needed?**  
> Apple's Gatekeeper quarantines any app not signed with an Apple Developer certificate or notarized through Apple. The `xattr -cr` command is the standard developer workaround for unsigned/self-built apps.

### Architecture

```
Sources/WhisperFly/
├── App/
│   ├── AppController.swift      # Main coordinator (recording → transcribe → rewrite → paste → TTS)
│   ├── FloatingPanel.swift      # Floating status pill near the cursor
│   └── WhisperFlyApp.swift      # SwiftUI entry point / menu bar extra
├── Core/
│   ├── PipelineStatus.swift     # Enum: idle / recording / transcribing / rewriting / pasting / error
│   └── Protocols.swift          # SpeechRecognizer, TextRewriter, TextInjector, …
├── Models/
│   └── AppSettings.swift        # Codable settings + UserDefaults persistence
├── Resources/
│   ├── en.lproj/Localizable.strings
│   └── ru.lproj/Localizable.strings
├── Services/
│   ├── AudioCaptureService.swift
│   ├── AudioConverter.swift     # Shared CAF → 16 kHz WAV conversion
│   ├── GeminiRewriter.swift
│   ├── GeminiTranscriber.swift
│   ├── GroqWhisperRecognizer.swift
│   ├── HotkeyMonitor.swift
│   └── PasteService.swift
└── Views/
    ├── FloatingStatusView.swift
    ├── MenuBarContentView.swift
    └── SettingsView.swift
```

---

## Русский

Приложение для macOS — диктовка нажатием клавиши с **бесплатным** облачным распознаванием речи.  
Форк [qwenwishper](https://github.com/hukopo/qwenwishper) — вся локальная модельная инференция заменена лёгкими API-вызовами.

### Возможности

- **Запись нажатием клавиши** через глобальное сочетание ⌘⇧Space (настраивается)
- **Два бесплатных бэкенда транскрипции:**
  - 🟢 **Groq Whisper Large V3** — специализированный ASR, 100+ языков, включая русский
  - 🟢 **Google Gemini 2.5 Flash** (через OpenRouter) — мультимодальный, бесплатный тариф
- **AI-переформулировка текста** — исправление, пунктуация или перевод на английский через Gemini
- **Прочитать вслух** — озвучить распознанный текст системным голосом TTS
- **Автовставка** в активное поле ввода (Accessibility API, при неудаче — через буфер обмена)
- **Локализованный интерфейс** — приложение автоматически адаптируется к языку системы (английский, русский, немецкий, французский, испанский, японский, китайский, корейский, итальянский, хинди)
- Не требует загрузки локальных моделей и GPU

### Установка

1. Получите бесплатные API-ключи:
   - Groq: [console.groq.com](https://console.groq.com) → API Keys
   - OpenRouter: [openrouter.ai/keys](https://openrouter.ai/keys)

2. Создайте файл `.env` в корне проекта:
   ```
   GROQ_API_KEY=gsk_xxx
   OPENROUTER_API_KEY=sk-or-v1-xxx
   ```

3. Соберите и запустите:
   ```bash
   swift build
   swift run WhisperFly
   ```

4. Разрешите доступ к **Микрофону** и **Специальным возможностям** при запросе.

### Использование

| Действие | Результат |
|---|---|
| Нажать **⌘⇧Space** | Начать запись |
| Нажать **⌘⇧Space** ещё раз | Остановить и транскрибировать |
| Кликнуть иконку в строке меню | Статус, последний результат, настройки |
| **Настройки → Основные** | Бэкенд, язык, режим переформулировки, чтение вслух |
| **Настройки → API-ключи** | Ввести ключи Groq / OpenRouter |
| **Настройки → Дополнительно** | Макс. длительность записи и задержка вставки |

### Требования

- macOS 14 (Sonoma) или новее
- Инструментарий Swift 6
- Подключение к интернету (распознавание выполняется через API)

### Снятие карантина macOS (xattr)

macOS помечает приложения, загруженные из интернета, флагом карантина, что может вызвать предупреждение **«приложение повреждено»** или блокировку Gatekeeper. Чтобы снять этот флаг, выполните команду в Терминале:

```bash
xattr -cr /Applications/WhisperFly.app
```

**Что делает команда:**
- `xattr` — управляет расширенными атрибутами файлов и папок
- `-c` — **очищает** все расширенные атрибуты (включая `com.apple.quarantine`)
- `-r` — применяет операцию **рекурсивно** ко всем файлам внутри `.app`

**Пошаговая инструкция:**
1. Переместите `WhisperFly.app` в `/Applications` (или в другое удобное место)
2. Откройте **Терминал** (`⌘Space` → введите *Терминал*)
3. Выполните команду выше (при необходимости замените путь, например `~/Desktop/WhisperFly.app`)
4. Запустите приложение обычным способом

> **Почему это нужно?**  
> Gatekeeper Apple помечает карантином любое приложение, не подписанное сертификатом Apple Developer и не нотаризованное Apple. Команда `xattr -cr` — стандартный обходной путь для неподписанных / самостоятельно собранных приложений.

### Архитектура

```
Sources/WhisperFly/
├── App/
│   ├── AppController.swift      # Главный координатор (запись → транскрипция → переформулировка → вставка → TTS)
│   ├── FloatingPanel.swift      # Плавающая таблетка статуса рядом с курсором
│   └── WhisperFlyApp.swift      # Точка входа SwiftUI / элемент строки меню
├── Core/
│   ├── PipelineStatus.swift     # Enum: idle / recording / transcribing / rewriting / pasting / error
│   └── Protocols.swift          # SpeechRecognizer, TextRewriter, TextInjector, …
├── Models/
│   └── AppSettings.swift        # Настройки (Codable) + сохранение в UserDefaults
├── Resources/
│   ├── en.lproj/Localizable.strings
│   └── ru.lproj/Localizable.strings
├── Services/
│   ├── AudioCaptureService.swift
│   ├── AudioConverter.swift     # Общая конвертация CAF → WAV 16 кГц
│   ├── GeminiRewriter.swift
│   ├── GeminiTranscriber.swift
│   ├── GroqWhisperRecognizer.swift
│   ├── HotkeyMonitor.swift
│   └── PasteService.swift
└── Views/
    ├── FloatingStatusView.swift
    ├── MenuBarContentView.swift
    └── SettingsView.swift
```
