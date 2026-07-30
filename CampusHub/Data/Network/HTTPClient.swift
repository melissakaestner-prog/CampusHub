import Foundation

/// Abstração do transporte HTTP. Permite substituir o URLSession por um
/// mock nos testes (injeção de dependências via inicializador).
protocol HTTPClientProtocol {
    func get<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func post<T: Decodable>(_ endpoint: Endpoint, body: some Encodable) async throws -> T
}

final class URLSessionHTTPClient: HTTPClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func get<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        try await send(request(for: endpoint, method: "GET", body: nil))
    }

    func post<T: Decodable>(_ endpoint: Endpoint, body: some Encodable) async throws -> T {
        let data: Data
        do {
            data = try encoder.encode(body)
        } catch {
            throw AppError.decoding
        }
        return try await send(request(for: endpoint, method: "POST", body: data))
    }

    private func request(for endpoint: Endpoint, method: String, body: Data?) throws -> URLRequest {
        guard let url = endpoint.url(relativeTo: baseURL) else {
            throw AppError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AppError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AppError.network("Resposta inválida do servidor.")
        }
        switch http.statusCode {
        case 200...299:
            break
        case 409:
            throw AppError.scheduleConflict
        default:
            throw AppError.server(statusCode: http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AppError.decoding
        }
    }
}
