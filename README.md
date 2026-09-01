# immerse-wrapper
開發 ImmerseWrapper 的動機很簡單：Immersive Translate 通常需要搭配付費 API 才能獲得較好的使用體驗，而自行架設具備足夠效能的 LLM，硬體與維護成本又相對較高。由於我平時已訂閱 ChatGPT Plus 與 Google AI Pro，但 Gemini 的使用率並不高，因此產生了透過 Antigravity（agy）CLI 將既有模型資源轉換為翻譯服務的構想，希望在不需額外支付 API 費用的情況下，提供 Immersive Translate 一個實用的本機後端。基於這個想法，我使用 Codex 協助開發了 ImmerseWrapper。

The motivation behind ImmerseWrapper is straightforward: Immersive Translate generally works best with a paid API, while self-hosting an LLM with sufficient performance can involve considerable hardware and maintenance costs. Since I already subscribe to ChatGPT Plus and Google AI Pro—but rarely use Gemini—I began exploring whether Antigravity’s agy CLI could turn those existing model resources into a practical translation service. This would provide Immersive Translate with a local backend without requiring an additional paid API subscription. Based on this idea, I developed ImmerseWrapper with the assistance of Codex.

# About Immerse Translate
Immersive Translate is a free, bilingual AI translation tool that supports website translation, PDF translation with original layouts preserved, video subtitle translation (YouTube, Netflix), online meeting translation, image translation, and comic translation—all in one platform. Powered by AI terminology libraries and context-aware translation, it integrates over 20 leading translation engines, including ChatGPT, DeepL, DeepSeek, and Gemini, and supports more than 100 language pairs. Available on Chrome, Edge, iOS, and mobile devices. Refer to https://immersivetranslate.com/en/.

Tested on:
* WSL/Ubuntu
* Kubuntu 26.04 LTS
