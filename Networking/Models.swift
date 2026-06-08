import Foundation

// MARK: - Auth

struct LoginRequest: Encodable {
    let identificador: String
    let senha: String
}

struct LoginResponse: Decodable {
    let idToken: String
    let refreshToken: String
    let tipoUsuario: String
    let nome: String
    let uid: String
    let emailVerificado: Bool
}

struct RefreshRequest: Encodable {
    let refreshToken: String
}

struct RefreshResponse: Decodable {
    let idToken: String
}

struct MessageResponse: Decodable {
    let message: String
}

// MARK: - Users

struct RegisterRequest: Encodable {
    let matricula: String
    let senha: String
    let nome: String
    let email: String
    let documento: String
    let tipoDocumento: String // "CPF" | "Passaporte"
}

struct RegisterResponse: Decodable {
    let uid: String
    let matricula: String
    let tipo: String
    let nome: String
    let email: String
    let emailVerificado: Bool
    let emailPendenteEnvio: Bool
}

struct MeResponse: Decodable {
    let matricula: String
    let nome: String
    let email: String
    let tipo: String
    let tipoDocumento: String
    let emailVerificado: Bool
}

// MARK: - Itinerários / Rotas

struct GeoPoint: Decodable {
    let latitude: Double
    let longitude: Double
}

struct Localizacao: Decodable {
    let local: GeoPoint?
    let endereco: String?
}

struct Itinerario: Decodable, Identifiable {
    let id: String
    let nome: String
    let rotas: [String]
    let horarios: [String]
    let endereco: String?
    let emRota: Bool
    let suspensa: Bool
    let localizacaoAtual: Localizacao?
}

/// Posição ao vivo do ônibus, lida do RTDB em `/localizacao/{id}/atual`.
/// Atenção: o RTDB usa snake_case (diferente da API REST, que é camelCase).
struct LiveLocation: Decodable {
    let lat: Double
    let lng: Double
    let endereco: String?
    let emRota: Bool?
    let horario: String?
    let motoristaNome: String?

    enum CodingKeys: String, CodingKey {
        case lat, lng, endereco, horario
        case emRota = "em_rota"
        case motoristaNome = "motorista_nome"
    }

    var temPosicao: Bool { lat != 0 || lng != 0 }
}

// MARK: - Util

/// Para endpoints que respondem sem corpo útil.
struct EmptyResponse: Decodable {}
