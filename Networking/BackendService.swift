import Foundation

/// Acesso aos endpoints de dados (perfil, itinerários) — todos autenticados via Bearer.
struct BackendService {
    static let shared = BackendService()

    private let api = APIClient.shared

    /// Perfil do usuário logado (aluno/professor/adm).
    func me() async throws -> MeResponse {
        try await api.request(path: "users/me", authenticated: true)
    }

    /// Itinerários não suspensos (qualquer perfil autenticado).
    func itinerarios() async throws -> [Itinerario] {
        try await api.request(path: "itinerarios", authenticated: true)
    }

    /// Detalhe de um itinerário pelo id (nome da rota).
    func itinerario(id: String) async throws -> Itinerario {
        let encoded = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        return try await api.request(path: "itinerarios/\(encoded)", authenticated: true)
    }

    /// Posição ao vivo do ônibus de uma rota, lida direto do Firebase RTDB.
    /// Lê `/localizacao/{id}/atual.json` autenticando com o idToken (`?auth=`).
    /// Retorna nil se não houver dado (rota sem ônibus em circulação).
    func liveLocation(itinerarioId: String) async throws -> LiveLocation? {
        guard let token = TokenStore.shared.idToken, !token.isEmpty else { return nil }
        let id = itinerarioId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? itinerarioId
        let urlString = AppConfig.rtdbURL.absoluteString + "/localizacao/\(id)/atual.json?auth=\(token)"
        guard let url = URL(string: urlString) else { return nil }

        let (data, _) = try await URLSession.shared.data(from: url)
        // RTDB devolve o literal "null" quando o node não existe.
        if let raw = String(data: data, encoding: .utf8), raw == "null" { return nil }
        return try? JSONDecoder().decode(LiveLocation.self, from: data)
    }
}
