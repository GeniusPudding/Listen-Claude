[English](README.md) · [繁體中文](README.zh-TW.md)

# ListenClaude（聽聲即克）

把 Claude Code 的回應變成語音播出來。Claude 回完話自動觸發 — 邊看邊聽,擴大人機互動的輸入頻寬。

跟 [Kaikou-Claude](https://github.com/GeniusPudding/Kaikou-Claude)（語音 → Claude）對稱;本專案是 Claude → 語音。

## 特色

- **自動觸發** — Claude Code 的 `Stop` hook,Claude 回完話就播,完全免互動。
- **本地優先** — 預設用 OS 內建 TTS（macOS `say`、Windows SAPI、Linux `spd-say`）。
- **可換引擎** — 換 [Piper TTS](https://github.com/rhasspy/piper) 可拿到離線高品質人聲。
- **可調朗讀模式** — 全文 / 只念第一段 / 重點摘要。
- **跳過廢話** — 太短的回應（如 "ok"）不念。

## 安裝

```bash
git clone https://github.com/GeniusPudding/ListenClaude.git
cd ListenClaude

# Windows
.\install.ps1

# macOS / Linux
./install.sh
```

安裝腳本會建 `.venv`、裝依賴、複製 `.env`、把 `Stop` hook 註冊到 `~/.claude/settings.json`。

## 挑聲音

最簡單的方式是在 Claude 對話框用 `/choose-voice` skill：

```
/choose-voice                                 → 列選項
/choose-voice list edge Chinese voices        → 列 Edge 的中文聲音
/choose-voice use zh-TW-HsiaoChenNeural       → 換聲音
/choose-voice 我現在用哪個聲音
```

### 引擎 1: Edge TTS（預設,免費,高品質）

[Microsoft Edge 的神經網路聲音](https://learn.microsoft.com/azure/ai-services/speech-service/language-support),免費、不需 API key。安裝時自動裝。

熱門中文聲音：
- `zh-TW-HsiaoChenNeural` — TW 女,溫暖（預設）
- `zh-TW-YunJheNeural` — TW 男
- `zh-CN-XiaoxiaoNeural` — CN 女,熱門
- `zh-CN-YunyangNeural` — CN 男,播音腔
- `yue-HK-WanLungNeural` — 粵語男

完整清單：`.venv/bin/edge-tts --list-voices | grep zh`

```
TTS_ENGINE=edge
TTS_VOICE=zh-TW-HsiaoChenNeural
```

### 引擎 2: 系統內建（免費,免裝）

OS 內建聲音。

```bash
# macOS
say -v '?' | grep zh
# Windows
powershell "Add-Type -AssemblyName System.Speech; (New-Object System.Speech.Synthesis.SpeechSynthesizer).GetInstalledVoices().VoiceInfo | Select Name,Culture"
```

常見：`Mei-Jia` (mac TW)、`Tingting` (mac CN)、`Microsoft Yating Desktop` (Win TW)。

```
TTS_ENGINE=system
TTS_VOICE=Mei-Jia
```

### 引擎 3: Piper（免費,本地,神經網路品質）

適合離線使用,品質僅次於 Edge TTS / ElevenLabs。

**方案 A — 安裝時順便下載**（一次搞定）：
```bash
# Windows
$env:PIPER_VOICE='zh_CN-huayan-medium'; .\install.ps1

# macOS / Linux
PIPER_VOICE=zh_CN-huayan-medium ./install.sh
```

**方案 B — 事後下載：**
```bash
.\scripts\install-piper-voice.ps1 zh_CN-huayan-medium       # Windows
bash scripts/install-piper-voice.sh zh_CN-huayan-medium     # macOS / Linux
```

下載完切換引擎：
```bash
.\scripts\set-voice.ps1 zh_CN-huayan-medium piper     # Windows
bash scripts/set-voice.sh zh_CN-huayan-medium piper   # macOS / Linux
```

線上試聽：[Piper samples](https://rhasspy.github.io/piper-samples/)。完整清單：https://huggingface.co/rhasspy/piper-voices/tree/main

### 引擎 4: ElevenLabs（雲端,付費,頂級品質）

1. 到 https://elevenlabs.io/app/settings/api-keys 拿 API key。
2. 開 https://elevenlabs.io/app/voice-library 線上試聽,複製喜歡的 voice ID。
3. ```
   TTS_ENGINE=elevenlabs
   TTS_VOICE=<voice_id>
   ELEVENLABS_API_KEY=<你的金鑰>
   ```

## 開關 (skill / 腳本)

安裝後 `/listen` skill 已註冊到 Claude Code。任何 session 都能用：

```
/listen          → 切換目前狀態
/listen on       → 開啟
/listen off      → 關閉
/listen status   → 查狀態
```

也可以直接跑腳本：

```bash
.\scripts\toggle.ps1 [on|off|status]   # Windows
bash scripts/toggle.sh [on|off|status] # macOS / Linux
```

切換用 marker 檔(`$TMPDIR/listen-claude.disabled`)實現,下一次 Claude 回應立即生效,不用重啟任何東西。

## 設定

寫在 repo 根目錄的 `.env`。

| 變數 | 預設 | 說明 |
|------|------|------|
| `TTS_ENABLED` | `1` | `0` 暫停 TTS（不用 uninstall） |
| `TTS_ENGINE` | `system` | `system` 或 `piper` |
| `TTS_VOICE` |（空） | 引擎對應的 voice ID |
| `TTS_MODE` | `first` | `full` / `first` / `summary` |
| `TTS_MIN_WORDS` | `20` | 短於此字數的回應不念 |
| `TTS_MAX_CHARS` | `500` | 截斷過長回應 |
| `TTS_RATE` | `200` | 大略 wpm |
| `PIPER_VOICES_DIR` | `~/.cache/piper-voices` | Piper 模型檔目錄 |

## 運作原理

```
Claude 回完話
        ↓ Stop hook 觸發
scripts/on_stop.{ps1,sh} 從 stdin 收 JSON
        ↓
listen_bridge.runner:
  1. 解析 transcript_path
  2. 讀 transcript JSONL 抓最後一則 assistant message
  3. 套用 TTS_MODE（全文 / 只第一段 / 摘要）
  4. 去掉 code block 跟 markdown 噪音
  5. 截斷到 TTS_MAX_CHARS
  6. 派給 TTS_ENGINE
        ↓
TTS 在背景播音 — 不會阻塞 Claude Code。
```

## 日誌

`%TEMP%\listen-claude.log`(Windows) 或 `$TMPDIR/listen-claude.log`(Unix)。

## 解除安裝

```bash
.\uninstall.ps1      # Windows
./uninstall.sh       # macOS / Linux
```

從 `~/.claude/settings.json` 移除 Stop hook。檔案保留。

## 與其他 Claude Code plugin 共存

ListenClaude 只加 `Stop` hook,跟用 `SessionStart` / `SessionEnd` / `PreToolUse` 等其他 hook 的 plugin 不衝突 — 包含 [Kaikou-Claude](https://github.com/GeniusPudding/Kaikou-Claude)（中文語音輸入）。`patch_settings.py` 用 `scripts/on_stop` 子路徑識別自己的 entry,重裝/解除不會誤砍別人的 hook。
