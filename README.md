# ImmerseWrapper

開發 ImmerseWrapper 的動機很簡單：Immersive Translate 通常需要搭配付費 API 才能獲得較好的使用體驗，而自行架設具備足夠效能的 LLM，硬體與維護成本又相對較高。由於我平時已訂閱 ChatGPT Plus 與 Google AI Pro，但 Gemini 的使用率並不高，因此產生了透過 Antigravity（`agy`）CLI 將既有模型資源轉換為翻譯服務的構想，希望在不需額外支付 API 費用的情況下，提供 Immersive Translate 一個實用的本機後端。基於這個想法，我使用 Codex 協助開發了 ImmerseWrapper。

The motivation behind ImmerseWrapper is straightforward: Immersive Translate generally works best with a paid API, while self-hosting an LLM with sufficient performance can involve considerable hardware and maintenance costs. Since I already subscribe to ChatGPT Plus and Google AI Pro—but rarely use Gemini—I began exploring whether Antigravity's `agy` CLI could turn those existing model resources into a practical translation service. This provides Immersive Translate with a local backend without requiring an additional paid API subscription. Based on this idea, I developed ImmerseWrapper with the assistance of Codex.

## About Immersive Translate

[Immersive Translate](https://immersivetranslate.com/en/) is a bilingual AI translation tool supporting website and PDF translation, video subtitle translation, online meeting translation, image translation, and more. ImmerseWrapper provides a local Ollama/OpenAI-compatible bridge between Immersive Translate and authenticated Antigravity or Codex CLI sessions.

## Current model baseline

- Antigravity: `gemini-3.6-flash` or newer, with reasoning effort configured separately.
- Codex: `gpt-5.6-luna` or newer, with reasoning effort configured separately.

Actual model availability depends on the authenticated account. Use `agy models` to confirm the available Antigravity model slugs before pinning one.

## Documentation

- [Quick start](QUICKSTART.md)
- [User guide](USERGUIDE.md)

Release bundles also include `immerse-bench`, a command-line diagnostic that can
compare direct Agy/Codex latency with the complete ImmerseWrapper HTTP path. See
the user guide for quota, privacy, and interpretation notes.

## Tested on

- WSL2 / Ubuntu
- Kubuntu 26.04 LTS
