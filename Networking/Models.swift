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

// MARK: - Util

/// Para endpoints que respondem sem corpo útil.
struct EmptyResponse: Decodable {}
