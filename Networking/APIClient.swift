import Foundation

/// Cliente REST central do app.
///
/// É um `actor` para serializar o acesso à sessão (leitura do token, renovação)
/// e evitar corridas quando várias telas disparam requests ao mesmo tempo.
actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let tokenStore: TokenStore
    private let decoder = JSONDecoder()

    init(session: URLSession = .shared, tokenStore: TokenStore = .shared) {
        self.session = session
        self.tokenStore = tokenStore
    }

    /// Executa uma request e decodifica a resposta em `T`.
    ///
    /// - Sempre envia `Content-Type` e `Accept: application/json`.
    /// - Se `authorized`, injeta `Authorization: Bearer <idToken>` do `TokenStore`.
    /// - Em 401, tenta renovar a sessão uma única vez (ver `renovarSessao`).
    func request<T: Decodable>(_ path: String,
                               method: String = "GET",
                               body: Encodable? = nil,
                               authorized: Bool = true) async throws -> T {
        let data = try await perform(path: path,
                                     method: method,
                                     body: body,
                                     authorized: authorized,
                                     allowRefresh: authorized)

        // Endpoints sem corpo útil (ex.: logout) → devolve EmptyResponse sem decodificar.
        if data.isEmpty, let empty = EmptyResponse() as? T {
            return empty
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AppError.decoding
        }
    }

    // MARK: - Núcleo

    private func perform(path: String,
                         method: String,
                         body: Encodable?,
                         authorized: Bool,
                         allowRefresh: Bool) async throws -> Data {
        guard let url = URL(string: AppConfig.baseURL.absoluteString + path) else {
            throw AppError.network
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if authorized, let token = tokenStore.idToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            req.httpBody = try body.toJSONData()
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw AppError.network
        }

        guard let http = response as? HTTPURLResponse else {
            throw AppError.network
        }

        switch http.statusCode {
        case 200..<300:
            return data

        case 401:
            // Tenta UMA renovação; se conseguir, refaz a request sem permitir novo refresh.
            if allowRefresh, await renovarSessao() {
                return try await perform(path: path,
                                         method: method,
                                         body: body,
                                         authorized: authorized,
                                         allowRefresh: false)
            }
            tokenStore.clear()
            throw AppError.unauthorized

        default:
            if let apiError = try? decoder.decode(APIError.self, from: data) {
                throw AppError.api(apiError, status: http.statusCode)
            }
            // Backend não devolveu o envelope esperado: ainda assim entrega algo exibível.
            let fallback = APIError(error: "erro_desconhecido",
                                    detail: "Erro \(http.statusCode).",
                                    field: nil)
            throw AppError.api(fallback, status: http.statusCode)
        }
    }

    // MARK: - Renovação de sessão

    /// POST /auth/refresh com o refreshToken salvo. Retorna `true` se renovou.
    private func renovarSessao() async -> Bool {
        guard let refresh = tokenStore.refreshToken else { return false }

        struct RefreshBody: Encodable { let refreshToken: String }
        // O backend renova SOMENTE o idToken; o refreshToken salvo é preservado.
        struct RefreshResponse: Decodable {
            let idToken: String
        }

        do {
            let data = try await perform(path: "/auth/refresh",
                                         method: "POST",
                                         body: RefreshBody(refreshToken: refresh),
                                         authorized: false,
                                         allowRefresh: false)
            let novo = try decoder.decode(RefreshResponse.self, from: data)
            tokenStore.updateTokens(idToken: novo.idToken)   // preserva o refreshToken já salvo
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Workaround Swift 5.5

/// Em Swift < 5.7, um `Encodable` existencial não conforma a `Encodable`, então
/// `JSONEncoder().encode(body)` com `body: Encodable` não compila. Chamar um
/// método de protocolo despacha para o tipo concreto, onde `Self: Encodable`,
/// e aí `encode(self)` é válido.
private extension Encodable {
    func toJSONData() throws -> Data {
        try JSONEncoder().encode(self)
    }
}
