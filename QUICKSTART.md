# ImmerseWrapper Quick Start（Antigravity）

適用版本：`0.1.1`

這份文件只提供 Antigravity backend 的最短安裝流程。Codex、進階參數、service lifecycle、
更新與移除方式請參考 [USERGUIDE.md](USERGUIDE.md)。

## 1. 準備環境

需要：

- WSL2 Ubuntu（[Microsoft：安裝 WSL](https://learn.microsoft.com/zh-tw/windows/wsl/install)）。
- Python 3.11 以上及 `python3-venv`。
- 已安裝並登入的 Antigravity CLI（[Google：安裝與認證](https://antigravity.google/docs/cli/install)）。

請使用之後執行 ImmerseWrapper 的同一個 Ubuntu 使用者完成 Agy 登入。

```bash
command -v agy
agy --version
```

## 2. 安裝 wheel

在 Ubuntu 進入發布檔案所在目錄：

```bash
sha256sum -c local_cli_translation_adapter-0.1.1-py3-none-any.whl.sha256

sudo apt update
sudo apt install -y python3-venv

python3 -m venv ~/.venvs/immerse-wrapper
~/.venvs/immerse-wrapper/bin/python -m pip install --upgrade pip
~/.venvs/immerse-wrapper/bin/python -m pip install \
  ./local_cli_translation_adapter-0.1.1-py3-none-any.whl
```

## 3. 設定 Antigravity

```bash
mkdir -p ~/.config/immerse-wrapper
cp immerse-wrapper.env.example ~/.config/immerse-wrapper/immerse-wrapper.env
chmod 600 ~/.config/immerse-wrapper/immerse-wrapper.env
nano ~/.config/immerse-wrapper/immerse-wrapper.env
```

至少確認下列設定；未安裝 Codex 時必須保持 `ENABLE_CODEX=false`：

```dotenv
DEFAULT_BACKEND=antigravity
BACKEND_MODE=cli
ENABLE_ANTIGRAVITY=true
ANTIGRAVITY_COMMAND=agy
ANTIGRAVITY_MODEL=gemini-3.5-flash-low
ANTIGRAVITY_SANDBOX=true
ANTIGRAVITY_MODE=plan
ENABLE_CODEX=false
```

## 4. 安裝並啟動 service

```bash
bash install-user-service.sh --enable
systemctl --user start immerse-wrapper.service
systemctl --user status immerse-wrapper.service
curl http://127.0.0.1:11435/health
```

預期 service 顯示 `active (running)`，health 回傳包含 `"status":"ok"`。

## 5. 設定 Immersive Translate

```text
Base URL: http://127.0.0.1:11435
Model: antigravity-translate
```

使用前請手動開啟 Ubuntu；WSL instance 停止時 ImmerseWrapper 也會停止。其他設定與操作
請參考 [USERGUIDE.md](USERGUIDE.md)。
