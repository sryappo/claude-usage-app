import Foundation

actor UsageService {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }

    func fetchUsage() async throws -> UsageResponse {
        let token = try KeychainHelper.getAccessToken()

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/usage")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("ClaudeUsage/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UsageError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw UsageError.httpError(statusCode: httpResponse.statusCode, body: body)
        }

        return try JSONDecoder().decode(UsageResponse.self, from: data)
    }

    enum UsageError: Error, LocalizedError {
        case invalidResponse
        case httpError(statusCode: Int, body: String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from API."
            case .httpError(let code, let body):
                if code == 403 {
                    return "Access denied (403). Token may lack 'user:profile' scope. Re-run 'claude login'."
                }
                return "HTTP \(code): \(body)"
            }
        }
    }
}
