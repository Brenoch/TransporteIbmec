import Foundation

/// Envelope de erro retornado pelo backend para status HTTP >= 400.
/// Formato: `{ "error": ..., "detail": ..., "field"?: ... }`.
struct APIError: Decodable {
    let error: String
    let detail: String
    let field: String?
}

/// Erros da camada de rede do app.
enum AppError: Error, LocalizedError {
    /// Erro de negócio retornado pelo backend (mostrar `detail` ao usuário).
    case api(APIError, status: Int)
    /// Falha de transporte (sem conexão, timeout, etc.).
    case network(Error)
    /// Falha ao decodificar a resposta.
    case decoding(Error)
    /// Sessão inválida / não autenticado (após tentativa de refresh).
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .api(let apiError, _):
            return apiError.detail
        case .network:
            return "Não foi possível conectar ao servidor."
        case .decoding:
            return "Resposta inesperada do servidor."
        case .unauthorized:
            return "Sua sessão expirou. Faça login novamente."
        }
    }
}
