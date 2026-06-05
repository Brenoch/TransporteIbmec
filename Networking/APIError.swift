import Foundation

/// Envelope de erro retornado pelo backend (mesmo shape em todas as rotas).
struct APIError: Codable {
    let error: String
    let detail: String
    let field: String?
}

/// Erros de domínio do app, já classificados para a camada de UI consumir.
enum AppError: Error {
    /// Erro de negócio retornado pelo backend, com o status HTTP que veio junto.
    case api(APIError, status: Int)
    /// Falha de transporte/conexão (não houve resposta HTTP).
    case network
    /// Houve resposta, mas o corpo não pôde ser decodificado.
    case decoding
    /// Não autenticado / sessão expirada (já tentou renovar e falhou).
    case unauthorized
}

extension AppError: LocalizedError {
    /// Mensagem pronta para exibir ao usuário. Para `.api`, devolve o `detail`
    /// do envelope do backend (ex.: "Usuário já existe.").
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
