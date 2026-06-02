import Foundation

struct LoginResponse {
    let sucesso: Bool
    let mensagem: String
}

final class AuthService {
    static let shared = AuthService()

    private init() {}

    func loginAluno(login: String, senha: String) async throws -> LoginResponse {
        try await Task.sleep(nanoseconds: 900_000_000)

        guard !login.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !senha.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return LoginResponse(sucesso: false, mensagem: "Preencha login e senha.")
        }

        if login.lowercased() == "aluno" && senha == "123456" {
            return LoginResponse(sucesso: true, mensagem: "Login efetuado com sucesso")
        }

        return LoginResponse(sucesso: false, mensagem: "Credenciais inválidas.")
    }
}
