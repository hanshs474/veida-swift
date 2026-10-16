# Veida for Swift

Veida AI is an unlimited free AI image generator. This package calls its image API from iOS and macOS
apps: pass a prompt, get back a link to the finished image, or pass an image URL and an instruction to
edit it.

No API key is needed to start: without one, each call is one free run on
[Veida AI](https://veida.ai/?utm_source=cocoapods&utm_medium=readme) Image v1, about seven a day per machine. Get a key at
[veida.ai/settings/apikeys](https://veida.ai/settings/apikeys?utm_source=cocoapods&utm_medium=readme) to run on your account.

## Install

CocoaPods:

```ruby
pod 'Veida', '~> 1.0'
```

Swift Package Manager: add `https://github.com/hanshs474/veida-swift` and the `Veida` product.

## Use

```swift
import Veida

let veida = Veida()                    // or Veida(apiKey: "...")
let image = try await veida.generate("a paper boat on a puddle, overcast light", aspectRatio: "16:9")
print(image.url, image.watermarked)

let edited = try await veida.edit(image.url, instruction: "make it night, lit by a street lamp, keep the boat and framing")
```

Errors come back as `Veida.VeidaError` (`.quota` when the free allowance is spent, `.rejected` when a prompt is refused).

## Edits in a browser

The same requests run in a page on the [ChatGPT image editor](https://veida.ai/image/chatgpt-image-editor?utm_source=cocoapods&utm_medium=readme):
upload a photo, say what to change and what to keep.

## License

MIT
