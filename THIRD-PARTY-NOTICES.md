# Third-party notices

Bellow's own code is proprietary (see [LICENSE](LICENSE)). The app ships
or downloads the following components. Every one of them is under a permissive
open-source license; nothing copyleft, source-available, or non-commercial is
involved. The app bundle carries the license texts in
`Bellow.app/Contents/Resources/licenses/`.

## Shipped inside the app

| Component | What it is | License | Copyright | Text in bundle |
| --- | --- | --- | --- | --- |
| [VoxType](https://github.com/peteonrails/voxtype) `320a737e` | Dictation daemon (`bin/voxtype`), built from source with Metal | MIT | Peter Jackson | `VOXTYPE-LICENSE` |
| [whisper.cpp](https://github.com/ggml-org/whisper.cpp) and ggml | Speech-to-text engine, statically linked into VoxType via `whisper-rs-sys` | MIT | The ggml authors | `WHISPER-CPP-LICENSE` |
| Rust crates compiled into VoxType | 300-odd crates, listed with license and repository in [`docs/voxtype-crates.txt`](docs/voxtype-crates.txt) | MIT, Apache-2.0, BSD-2/3-Clause, ISC, Zlib, 0BSD, Unicode-3.0, Unlicense, CC0-1.0, CDLA-Permissive-2.0, BSL-1.0; `option-ext` is MPL-2.0 | Their respective authors | `VOXTYPE-CRATES.txt` |
| [llama.cpp](https://github.com/ggml-org/llama.cpp) and ggml `b11312` | Local model server (`llama/llama-server`) and the shared libraries it loads (`llama/lib*.dylib`), from the official macOS arm64 release archive | MIT | The ggml authors | `LLAMA-CPP-LICENSE` |
| [cpp-httplib](https://github.com/yhirose/cpp-httplib) | HTTP server compiled into llama-server (llama.cpp's `vendor/cpp-httplib`) | MIT | Yuji Hirose | `CPP-HTTPLIB-LICENSE` |
| [JSON for Modern C++](https://github.com/nlohmann/json) | JSON library compiled into llama.cpp (`vendor/nlohmann`) | MIT | Niels Lohmann | `NLOHMANN-JSON-LICENSE` |
| [stb_image](https://github.com/nothings/stb), [miniaudio](https://github.com/mackron/miniaudio), [subprocess.h](https://github.com/sheredom/subprocess.h) | Single-header libraries compiled into llama.cpp's libraries (`vendor/stb`, `vendor/miniaudio`, `vendor/sheredom`); Bellow uses none of their features | Public domain (Unlicense), each also offered under MIT or MIT-0 | Sean Barrett; David Reid; Neil Henning | Not required: used under their public-domain terms |
| [Sparkle](https://github.com/sparkle-project/Sparkle) 2.10.0 | Auto-update framework (`Frameworks/Sparkle.framework`, with its `Autoupdate` helper, `Updater.app`, and XPC services), from the project's Swift package release, arm64 slices only | MIT (with BSD and public-domain parts, all in the license file) | Sparkle Project contributors | `SPARKLE-LICENSE` |
| Cleanup prompts | The `voxtype-llm-wrapper` system prompts, examples, and sampling settings, rendered as llama-server requests (`prompts/max.json`, `prompts/standard.json`, `prompts/tiny.json`), by Bellow's author; VoxClean's number check is a port of its `number-check.awk` | Proprietary, as part of Bellow | Sam Wen | `BELLOW-LICENSE` |

`option-ext` (MPL-2.0) is used unmodified; its source is on crates.io and at
the repository named in the crate list, which satisfies the MPL's source
availability term for a file-level copyleft. All other licenses only require
attribution and inclusion of their text, which the bundle provides.

Apple frameworks (AppKit, SwiftUI, AVFoundation, Carbon, CryptoKit) are part of
macOS and are used under Apple's SDK terms; no Apple code is redistributed.

## Downloaded on first start

The app downloads these into `~/Library/Application Support/Bellow/`,
verified against the checksums pinned in
[`Resources/models.json`](Resources/models.json).

| Model | Source | License | Copyright | Text in bundle |
| --- | --- | --- | --- | --- |
| Whisper large-v3-turbo (Q5_0 GGML) | [ggerganov/whisper.cpp on Hugging Face](https://huggingface.co/ggerganov/whisper.cpp), converted from OpenAI's release | MIT | OpenAI | `WHISPER-LICENSE` |
| Qwen3.5-4B, text-only Q4_K_M GGUF, the Max tier | [unsloth/Qwen3.5-4B-GGUF on Hugging Face](https://huggingface.co/unsloth/Qwen3.5-4B-GGUF), converted by Unsloth from [Qwen/Qwen3.5-4B](https://huggingface.co/Qwen/Qwen3.5-4B) | Apache-2.0 | Alibaba Cloud | `QWEN-LICENSE` |
| Qwen3.5-2B, text-only Q4_K_M GGUF, the Standard tier | [unsloth/Qwen3.5-2B-GGUF on Hugging Face](https://huggingface.co/unsloth/Qwen3.5-2B-GGUF), converted by Unsloth from [Qwen/Qwen3.5-2B](https://huggingface.co/Qwen/Qwen3.5-2B) | Apache-2.0 | Alibaba Cloud | `QWEN-LICENSE` |
| Qwen2.5-0.5B-Instruct, Q4_K_M GGUF, the Tiny tier (chosen by hand only) | [Qwen/Qwen2.5-0.5B-Instruct-GGUF on Hugging Face](https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF), Qwen's own conversion of [Qwen/Qwen2.5-0.5B-Instruct](https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct) | Apache-2.0 | Alibaba Cloud | `QWEN2.5-LICENSE` |
Only one of the three cleanup models is downloaded on a given Mac, chosen by
its memory tier or by the user. All three are Apache 2.0 (the Qwen 2.5 3B,
considered earlier, was not; check each size when changing models). A GGUF
carries no license file, so `QWEN-LICENSE` (Qwen3.5) and `QWEN2.5-LICENSE`
(Qwen2.5, with its own copyright year) in the bundle are the texts of record
for the Qwen models.

## Keeping this current

- `./scripts/crate-licenses.sh .cache/voxtype > docs/voxtype-crates.txt`
  regenerates the crate list after bumping the VoxType pin.
- `scripts/build-macos.sh` copies every text above into the bundle, and
  `scripts/audit-bundle.py` fails the build if one is missing.
