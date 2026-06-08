import Foundation

/// Cliente REST baseado em URLSession async/await.
/// É um `actor` para serializar o acesso (especialmente a renovação de token).
actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let store = TokenStore.shared

    init(session: URLSession = .shared) {
        self.session = session
        // O backend envia/recebe camelCase, batendo com os nomes dos models —
        // por isso NÃO usamos convertFromSnakeCase/convertToSnakeCase.
    }

    enum Method: String {
        case get = "GET"
        case post = "POST"
    }

    /// Executa uma request e decodifica a resposta em `T`.
    ///
    /// - Parameters:
    ///   - authenticated: envia `Authorization: Bearer <idToken>` e, em caso de 401,
    ///     tenta UMA renovação via `/auth/refresh` e repete a chamada.
    func request<T: Decodable>(
        path: String,
        method: Method = .get,
        body: Encodable? = nil,
        authenticated: Bool = false
    ) async throws -> T {
        var urlRequest = try buildRequest(path: path, method: method, body: body, authenticated: authenticated)

        var (data, http) = try await perform(urlRequest)

        // 401 -> tenta UMA renovação e repete a request original.
        if authenticated, http.statusCode == 401 {
            try await refreshIdToken()
            urlRequest = try buildRequest(path: path, method: method, body: body, authenticated: authenticated)
            (data, http) = try await perform(urlRequest)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw mapError(data: data, status: http.statusCode)
        }

        // Suporte a respostas sem corpo útil.
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AppError.decoding(error)
        }
    }

    // MARK: - Private

    private func buildRequest(path: String, method: Method, body: Encodable?, authenticated: Bool) throws -> URLRequest {
        // Concatenação direta (preserva "/" e segmentos já percent-encoded, ex.: ids com espaço).
        guard let url = URL(string: AppConfig.baseURL.absoluteString + "/" + path) else {
            throw AppError.network(URLError(.badURL))
        }
        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if authenticated, let token = store.idToken, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            req.httpBody = try encoder.encode(AnyEncodable(body))
        }
        return req
    }

    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw AppError.network(URLError(.badServerResponse))
            }
            return (data, http)
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.network(error)
        }
    }

    /// Renova o idToken via `POST /auth/refresh`.
    /// Atualiza SOMENTE o idToken e PRESERVA o refreshToken salvo (ele não rotaciona).
    private func refreshIdToken() async throws {
        guard let refresh = store.refreshToken, !refresh.isEmpty else {
            throw AppError.unauthorized
        }

        let url = AppConfig.baseURL.appendingPathComponent("auth/refresh")
        var req = URLRequest(url: url)
        req.httpMethod = Method.post.rawValue
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(RefreshRequest(refreshToken: refresh))

        let (data, http) = try await perform(req)
        guard (200..<300).contains(http.statusCode) else {
            throw AppError.unauthorized
        }

        do {
            let refreshed = try decoder.decode(RefreshResponse.self, from: data)
            store.updateIdToken(refreshed.idToken) // só idToken; refreshToken intacto
        } catch {
            throw AppError.decoding(error)
        }
    }

    private func mapError(data: Data, status: Int) -> AppError {
        // Erros de negócio do backend (HTTPException): {"detail": {error, detail, field?}}.
        if let wrapper = try? decoder.decode(DetailWrapper.self, from: data) {
            return .api(wrapper.detail, status: status)
        }
        // Erros no topo (ex.: validação 422): {error, detail, ...}.
        if let apiError = try? decoder.decode(APIError.self, from: data) {
            return .api(apiError, status: status)
        }
        if status == 401 { return .unauthorized }
        let fallback = APIError(error: "http_\(status)", detail: "Erro inesperado (HTTP \(status)).", field: nil)
        return .api(fallback, status: status)
    }

    /// Envelope aninhado usado pelos erros de negócio do backend.
    private struct DetailWrapper: Decodable { let detail: APIError }
}

/// Apaga o tipo concreto de um `Encodable` para poder codificá-lo (Swift 5.5 não abre existenciais).
private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { encodeClosure = wrapped.encode }
    func encode(to encoder: Encoder) throws { try encodeClosure(encoder) }
}
