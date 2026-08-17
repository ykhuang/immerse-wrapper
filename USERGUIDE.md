# ImmerseWrapper 使用指南

適用版本：`0.1.1`  
最後驗證：2026-08-17（WSL2 Ubuntu 跨機安裝流程）

這份文件提供 wheel 使用者完整的安裝、設定、service 與維護流程。wheel 只包含
ImmerseWrapper 程式與 Python dependency metadata；Codex／Antigravity CLI、登入狀態、
`.env` 與 systemd service 不包含在 wheel 內。

## 1. 前置需求

- WSL2 Ubuntu（[Microsoft：安裝 WSL](https://learn.microsoft.com/zh-tw/windows/wsl/install)）。
- Python 3.11 以上。
- `python3-venv`。
- 至少安裝並登入一個 backend：
  - Antigravity CLI (`agy`)（[Google：安裝與認證](https://antigravity.google/docs/cli/install)）；或
  - Codex CLI (`codex`)。
- Windows 與 WSL 的 `127.0.0.1` 能正常互通。

先確認要使用的 CLI：

```bash
command -v agy
agy --version

command -v codex
codex --version
```

只需要確認實際要啟用的 backend。登入必須由將來執行 ImmerseWrapper 的同一個 WSL
使用者完成。

## 2. 驗證 wheel

進入收到發布檔案的目錄：

```bash
sha256sum -c local_cli_translation_adapter-0.1.1-py3-none-any.whl.sha256
```

預期結果：

```text
local_cli_translation_adapter-0.1.1-py3-none-any.whl: OK
```

## 3. 建立 venv 並安裝

有網路時，pip 會自動下載 FastAPI、Pydantic Settings、Uvicorn 等 Python 相依套件。
離線安裝需要另外準備包含所有相依 wheel 的 `wheelhouse/`。

```bash
sudo apt update
sudo apt install -y python3-venv

python3 -m venv ~/.venvs/immerse-wrapper
~/.venvs/immerse-wrapper/bin/python -m pip install --upgrade pip
~/.venvs/immerse-wrapper/bin/python -m pip install \
  ./local_cli_translation_adapter-0.1.1-py3-none-any.whl
```

確認 console command：

```bash
~/.venvs/immerse-wrapper/bin/immerse-wrapper --version
```

預期結果：

```text
immerse-wrapper 0.1.1
```

不必每次 `source` venv；後續指令可直接使用上面的完整路徑。

## 4. 建立獨立設定檔

不要把實際設定或憑證寫入 wheel。將隨附範例複製到 WSL 使用者設定目錄：

```bash
mkdir -p ~/.config/immerse-wrapper
cp immerse-wrapper.env.example ~/.config/immerse-wrapper/immerse-wrapper.env
chmod 600 ~/.config/immerse-wrapper/immerse-wrapper.env
```

使用文字編輯器修改：

```bash
nano ~/.config/immerse-wrapper/immerse-wrapper.env
```

處理優先序為「程序環境變數 > 明確指定的 env file > 程式預設值」。正式啟動一律使用
`--env-file`，避免工作目錄中的其他 `.env` 被誤用。

### Antigravity 基本設定

下列設定適合一般網頁翻譯；模型名稱必須是目前 Agy 帳號可用的名稱，也可以留空以使用
CLI 預設模型：

```dotenv
ADAPTER_HOST=127.0.0.1
ADAPTER_PORT=11435
ALLOW_NON_LOOPBACK_BIND=false

BACKEND_MODE=cli
DEFAULT_BACKEND=antigravity
ENABLE_ANTIGRAVITY=true
ANTIGRAVITY_COMMAND=agy
ANTIGRAVITY_MODEL=gemini-3.5-flash-low
ANTIGRAVITY_REASONING_EFFORT=
ENABLE_CODEX=false
ENABLE_LEGACY_GEMINI=false

MAX_CONCURRENCY=3
REQUEST_TIMEOUT_SECONDS=120

ENABLE_OPENAI_COMPAT=true
ENABLE_MICRO_BATCHING=true
BATCH_WINDOW_MS=300
BATCH_MAX_ITEMS=6
BATCH_MAX_CHARS=20000
BATCH_MAX_PENDING=128
BATCH_FALLBACK_INDIVIDUAL=true

LOG_LEVEL=INFO
LOG_VERBOSE=true
LOG_REQUEST_BODY=false
LOG_RESPONSE_BODY=false
DEBUG_PROTOCOL=false
OBSERVE_REQUEST_SHAPE=false
```

YouTube 字幕較重視即時性時，可先把 `BATCH_WINDOW_MS` 改成 `60`；一般網頁建議先從
`300` 開始。

Agy 1.1.5 以上支援獨立的 reasoning effort；目前驗證版本為 1.1.13。原本的完整 model
slug 已包含 effort，因此以下設定仍然有效，且不需要重複指定 effort：

```dotenv
ANTIGRAVITY_MODEL=gemini-3.5-flash-low
ANTIGRAVITY_REASONING_EFFORT=
```

若希望像 Codex 一樣分開管理，可使用 base model 加上 `low`、`medium` 或 `high`：

```dotenv
ANTIGRAVITY_MODEL=gemini-3.5-flash
ANTIGRAVITY_REASONING_EFFORT=low
```

完整 model slug 與獨立 effort 同時設定時必須一致；例如 `gemini-3.5-flash-low` 搭配
`high` 會在啟動設定驗證時失敗。可用 `agy models` 查詢可用模型，並以
`agy --model <MODEL> -p '/effort'` 確認解析結果。

### Codex exec 基本設定

Codex 有兩種 transport。`exec` 會為每個 backend call 啟動一次 `codex exec`，程序彼此
獨立、失敗隔離簡單，也能使用多個 concurrency，但每次都有 CLI 啟動與載入成本。
`app-server` 則維持一個 Codex 程序並透過 JSONL 傳送多次請求，可以降低頻繁翻譯時的
啟動延遲，代價是需要管理 persistent process 的啟動、timeout 與中斷；目前實作限制
`MAX_CONCURRENCY=1`，啟動失敗時可設定回退到 `exec`。兩種 transport 都沿用相同的
HTTP、micro-batch 與翻譯處理流程。

把 backend 區塊改成：

```dotenv
BACKEND_MODE=cli
DEFAULT_BACKEND=codex
ENABLE_ANTIGRAVITY=false
ENABLE_CODEX=true
CODEX_COMMAND=codex
CODEX_MODEL=gpt-5.4-mini
CODEX_REASONING_EFFORT=low
CODEX_TRANSPORT=exec
CODEX_SANDBOX=read-only
CODEX_EPHEMERAL=true
MAX_CONCURRENCY=3
```

模型與 reasoning effort 是不同參數；不要把 `gpt-5.4-mini-low` 當成模型名稱。

若要使用 persistent app-server，改成：

```dotenv
CODEX_TRANSPORT=app-server
MAX_CONCURRENCY=1
CODEX_APP_SERVER_START_TIMEOUT_SECONDS=10
CODEX_APP_SERVER_FALLBACK_TO_EXEC=true
```

目前 app-server 模式要求 `MAX_CONCURRENCY=1`；設定不符時啟動驗證會直接失敗。

## 5. 常用 `.env` 參數

| 參數 | 用途與建議 |
| --- | --- |
| `ADAPTER_HOST` | 保持 `127.0.0.1`，僅允許本機使用。 |
| `ADAPTER_PORT` | HTTP port，預設 `11435`；修改後 Immersive Translate URL 也要同步。 |
| `DEFAULT_BACKEND` | `antigravity` 或 `codex`。對應的 `ENABLE_*` 必須是 `true`。 |
| `BACKEND_MODE` | 正式翻譯使用 `cli`；`mock` 只用於協定測試。 |
| `MAX_CONCURRENCY` | 同時執行的 backend call 數。Agy/Codex exec 可先用 `3`；Codex app-server 必須為 `1`。 |
| `REQUEST_TIMEOUT_SECONDS` | Adapter 等待 backend 的上限；目前預設 `120` 秒。這不能延長 Immersive Translate 自己的 timeout。 |
| `ANTIGRAVITY_MODEL` | Agy 模型；留空表示使用 CLI/account 預設值。 |
| `ANTIGRAVITY_REASONING_EFFORT` | 可選的 Agy reasoning effort：`low`、`medium` 或 `high`。完整 model slug 已含 effort 時可留空。 |
| `CODEX_MODEL` | Codex 模型 ID，不包含 reasoning effort。 |
| `CODEX_REASONING_EFFORT` | `minimal`、`low`、`medium`、`high` 或 `xhigh`；翻譯通常先用 `low`。 |
| `CODEX_TRANSPORT` | `exec` 每次啟動 CLI；`app-server` 使用 persistent transport。 |
| `ENABLE_MICRO_BATCHING` | `true` 時將相容的短請求合併成較少的 CLI call。 |
| `BATCH_WINDOW_MS` | 最多等待多久收集 batch；到達 item 上限時會提前送出。 |
| `BATCH_MAX_ITEMS` | 單一 backend call 最多代表幾個原始 HTTP request，預設建議 `6`。 |
| `BATCH_MAX_CHARS` | Batch prompt／輸出的安全字元上限，建議 `20000`。它不會觸發提早送出；超限時視為 batch codec failure，並在 `BATCH_FALLBACK_INDIVIDUAL=true` 時退回逐筆翻譯。 |
| `BATCH_MAX_PENDING` | 等待 batching 或 backend 完成的請求上限；一般 `64`，較大 burst 可用 `128`。 |
| `BATCH_FALLBACK_INDIVIDUAL` | batch 回傳無法安全拆分時，是否退回逐筆翻譯。建議 `true`。 |
| `LOG_VERBOSE` | `true` 時，每次啟動在工作目錄的 `logs/` 建立 timestamp log。 |
| `LOG_REQUEST_BODY` / `LOG_RESPONSE_BODY` | 可能寫入翻譯內容；一般保持 `false`。 |
| `OBSERVE_REQUEST_SHAPE` | 僅在分析 batching 時開啟；記錄結構、hash 與字數，不記錄 prompt 文字。 |
| `ENABLE_CORS` | 預設 `false`。只有瀏覽器相容性確實需要時才啟用並限制 `CORS_ALLOW_ORIGINS`。 |

其他安全限制、body 大小、CLI stdout/stderr 上限及 runtime path 可保留 `.env.example`
預設值。每次修改設定後都要重新啟動程式。

## 6. 安裝、啟動與檢查 service

安裝 systemd user service。這個步驟不需要 `sudo`，也不會啟用自動啟動：

```bash
bash install-user-service.sh
systemctl --user status immerse-wrapper.service
```

安裝完成後應顯示 `Loaded: loaded` 及 `disabled`。S4 先以手動方式啟動：

```bash
systemctl --user start immerse-wrapper.service
systemctl --user status immerse-wrapper.service
```

確認狀態為 `active (running)`，再執行：

```bash
curl http://127.0.0.1:11435/health
curl http://127.0.0.1:11435/api/tags
journalctl --user -u immerse-wrapper.service -n 50 --no-pager
```

也可以從 Windows PowerShell 測試：

```powershell
curl.exe http://127.0.0.1:11435/health
```

常用 service 操作：

```bash
systemctl --user stop immerse-wrapper.service
systemctl --user restart immerse-wrapper.service
journalctl --user -u immerse-wrapper.service -f
```

`systemctl --user stop immerse-wrapper.service` 不保證立刻返回。這個命令會同步等待 service
完成 graceful shutdown；如果 Immersive Translate 已送入尚未完成的 HTTP request、
micro-batch 或 CLI backend 工作，ImmerseWrapper 會先等待或清理這些工作，再記錄
`server_stopped` 並變成 `inactive`。目前 unit 的 `TimeoutStopSec=150`，因此最慢可能接近
150 秒後才由 systemd 結束。等待期間可以在另一個 terminal 觀察：

```bash
systemctl --user status immerse-wrapper.service
journalctl --user -u immerse-wrapper.service -f
```

看到 `server_stopped` 以及 `inactive (dead)` 才代表正常停止完成。避免直接使用
`SIGKILL`；強制中止會跳過 batch、backend subprocess、log 與 persistent transport 的
正常清理。

若只需要手動啟動，可維持 unit 為 `disabled`。若希望 WSL 的 systemd user manager
啟動時自動啟動 ImmerseWrapper，重新執行安裝器並明確加入 `--enable`：

```bash
bash install-user-service.sh --enable
systemctl --user is-enabled immerse-wrapper.service
```

預期顯示 `enabled`。`--enable` 不會立刻啟動 service；需要立即啟動時仍使用
`systemctl --user start immerse-wrapper.service`。

WSL instance 停止時，systemd service 也會停止。正式發布不建立 Windows 登入排程；
使用 ImmerseWrapper 前請手動開啟 Ubuntu，並在使用期間保持 WSL session 開啟。

## 7. Immersive Translate 設定

以目前已驗證的本機協定設定：

```text
Base URL: http://127.0.0.1:11435
Antigravity virtual model: antigravity-translate
Codex virtual model: codex-translate
```

Adapter 同時提供 Ollama-compatible endpoints 與 OpenAI-compatible
`/v1/chat/completions`。如果修改 `ADAPTER_PORT`，Base URL 必須使用相同 port。

## 8. 更新或移除 wheel

先停止正在執行的 ImmerseWrapper，再安裝新版：

```bash
~/.venvs/immerse-wrapper/bin/python -m pip install --upgrade \
  ./local_cli_translation_adapter-<new-version>-py3-none-any.whl

~/.venvs/immerse-wrapper/bin/immerse-wrapper --version
~/.venvs/immerse-wrapper/bin/immerse-wrapper check-config \
  --env-file ~/.config/immerse-wrapper/immerse-wrapper.env
```

升級不會自動修改使用者的 env file。發布說明若指出新增、移除或變更參數，必須先更新
設定再啟動。

若要移除 ImmerseWrapper，先停止正在執行的程序，再執行：

```bash
bash uninstall-user-service.sh

~/.venvs/immerse-wrapper/bin/python -m pip uninstall \
  local-cli-translation-adapter
```

這不會刪除使用者設定、log 或 runtime data。如不再需要，可以另外移除：

```text
~/.config/immerse-wrapper/
~/.cache/immerse-wrapper/
~/.local/share/immerse-wrapper/
~/.local/state/immerse-wrapper/
```

若 `~/.venvs/immerse-wrapper/` 沒有供其他程式使用，也可以在確認路徑後刪除整個 venv。
