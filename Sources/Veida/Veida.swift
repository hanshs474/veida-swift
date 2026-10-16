import Foundation

/// Veida AI image generation. Without an API key calls run on the free tier
/// (one run per call on Veida AI Image v1, about seven a day per machine).
/// Get a key at https://veida.ai/settings/apikeys to run on your account.
public struct Veida {
    public static let baseURL = URL(string: "https://veida.ai")!

    /// One finished picture.
    public struct Image: Sendable {
        /// Permanent CDN link to the image.
        public let url: URL
        /// Whether a watermark was drawn on it.
        public let watermarked: Bool
    }

    public enum VeidaError: Error, LocalizedError {
        case invalid(String), quota(String), rejected, service(String), timeout
        public var errorDescription: String? {
            switch self {
            case .invalid(let m): return "veida: \(m)"
            case .quota(let m): return "veida: \(m)"
            case .rejected: return "veida: prompt refused"
            case .service(let m): return "veida: \(m)"
            case .timeout: return "veida: deadline passed"
            }
        }
    }

    public let apiKey: String?
    public let session: URLSession

    public init(apiKey: String? = nil, session: URLSession = .shared) {
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["VEIDA_API_KEY"]
        self.session = session
    }

    /// Turn a prompt into a new image. `aspectRatio`: "1:1", "16:9", "9:16", "4:3" or "3:4".
    public func generate(_ prompt: String, aspectRatio: String = "1:1", timeout: TimeInterval = 360) async throws -> Image {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw VeidaError.invalid("prompt is required") }
        return try await run([
            "provider": "kie", "mediaType": "image", "model": "veida-image-v1", "scene": "text-to-image",
            "prompt": prompt, "options": ["aspect_ratio": aspectRatio],
        ], timeout: timeout)
    }

    /// Rewrite an existing image. `source` must be a public http(s) URL.
    public func edit(_ source: URL, instruction: String, timeout: TimeInterval = 360) async throws -> Image {
        guard source.scheme == "http" || source.scheme == "https" else { throw VeidaError.invalid("source must be a public http(s) url") }
        return try await run([
            "provider": "kie", "mediaType": "image", "model": "veida-image-v1", "scene": "image-to-image",
            "prompt": instruction, "options": ["image_input": [source.absoluteString]],
        ], timeout: timeout)
    }

    private func headers() -> [String: String] {
        if let key = apiKey, !key.isEmpty { return ["authorization": "Bearer \(key)"] }
        let id = (0..<8).map { _ in String(format: "%02x", UInt8.random(in: 0...255)) }.joined()
        return ["x-anon-id": "swift-\(id)"]
    }

    private func json(_ req: URLRequest) async throws -> [String: Any] {
        let (data, _) = try await session.data(for: req)
        return (try JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    private func run(_ payload: [String: Any], timeout: TimeInterval) async throws -> Image {
        let auth = headers()
        var submit = URLRequest(url: Veida.baseURL.appendingPathComponent("api/ai/generate"))
        submit.httpMethod = "POST"
        submit.setValue("application/json", forHTTPHeaderField: "content-type")
        auth.forEach { submit.setValue($0.value, forHTTPHeaderField: $0.key) }
        submit.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let env = try await json(submit)
        guard (env["code"] as? Int) == 0 else { throw VeidaError.service(env["message"] as? String ?? "request refused") }
        let d = env["data"] as? [String: Any] ?? [:]
        if (d["wall"] as? Bool) == true {
            throw VeidaError.quota("free allowance spent — pass an apiKey from https://veida.ai/settings/apikeys to keep going")
        }
        guard let task = d["id"] as? String, !task.isEmpty else { throw VeidaError.service("the service returned no task id") }

        // Polling is what moves a queued run forward.
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            try await Task.sleep(nanoseconds: 5_000_000_000)
            var poll: URLRequest
            if auth["authorization"] != nil {
                poll = URLRequest(url: Veida.baseURL.appendingPathComponent("api/ai/query"))
                poll.httpMethod = "POST"
                poll.setValue("application/json", forHTTPHeaderField: "content-type")
                poll.httpBody = try JSONSerialization.data(withJSONObject: ["taskId": task])
            } else {
                var c = URLComponents(url: Veida.baseURL.appendingPathComponent("api/ai/anon-query"), resolvingAgainstBaseURL: false)!
                c.queryItems = [.init(name: "taskId", value: task), .init(name: "provider", value: "kie"), .init(name: "mediaType", value: "image")]
                poll = URLRequest(url: c.url!)
            }
            auth.forEach { poll.setValue($0.value, forHTTPHeaderField: $0.key) }
            guard let q = try? await json(poll), (q["code"] as? Int) == 0 else { continue }
            let qd = q["data"] as? [String: Any] ?? [:]
            if let clean = qd["cleanImages"] as? [String], let u = clean.first, let url = URL(string: u) {
                return Image(url: url, watermarked: false)
            }
            if let imgs = qd["images"] as? [String], let u = imgs.first, let url = URL(string: u) {
                let wm = (qd["watermarked"] as? [Bool])?.first ?? false
                return Image(url: url, watermarked: wm)
            }
            if let s = qd["status"] as? String, s == "failed" || s == "error" { throw VeidaError.rejected }
        }
        throw VeidaError.timeout
    }
}
