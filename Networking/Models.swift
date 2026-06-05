import Foundation

// As chaves JSON batem 1:1 com os nomes das propriedades (camelCase), então não
// é preciso CodingKeys nem keyDecodingStrategy.

// MARK: - Autenticação

struct LoginRequest: Codable {
    let identificador: String
    let senha: String
}

struct LoginResponse: Codable {
    let idToken: String
    let refreshToken: String
    let tipoUsuario: String
    let nome: String
    let uid: String
    let emailVerificado: Bool
}

// MARK: - Cadastro

struct RegisterRequest: Codable {
    let matricula: String
    let senha: String
    let nome: String
    let email: String
    let documento: String
    /// "CPF" | "Passaporte"
    let tipoDocumento: String
}

struct RegisterResponse: Codable {
    let uid: String
    let matricula: String
    let tipo: String
    let nome: String
    let email: String
    let emailVerificado: Bool
    let emailPendenteEnvio: Bool
}

// MARK: - Usuário

struct UserMe: Codable {
    let matricula: String
    let nome: String
    let email: String
    let tipo: String
    let tipoDocumento: String
    let emailVerificado: Bool
}

// MARK: - Itinerários / Rotas

struct GeoPoint: Codable {
    let latitude: Double
    let longitude: Double
}

struct LocalizacaoAtual: Codable {
    let local: GeoPoint
    let endereco: String?
}

struct Itinerario: Codable {
    let id: String
    let nome: String
    let rotas: [String]
    let horarios: [String]
    let endereco: String
    let emRota: Bool
    let suspensa: Bool
    let localizacaoAtual: LocalizacaoAtual
}

struct IniciarRotaRequest: Codable {
    let horario: String
}

struct IniciarRotaResponse: Codable {
    let itinerarioId: String
    let horario: String
    let startedAt: Int
    let rtdbPath: String
}

struct EncerrarRotaResponse: Codable {
    let itinerarioId: String
    let endedAt: Int
}

// MARK: - Utilitário

/// Para endpoints que respondem sem corpo útil (ex.: logout). O `APIClient`
/// trata corpo vazio e devolve esta struct sem tentar decodificar.
struct EmptyResponse: Decodable {}
