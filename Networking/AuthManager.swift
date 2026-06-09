import Foundation
import Combine

/// Orquestra autenticação e expõe o estado de navegação raiz do app.
@MainActor
final class AuthManager: ObservableObject {

    /// Estado de alto nível que o `ContentView` observa para escolher a tela.
    enum AppState: Equatable {
        case verificando
        case deslogado
        case aluno(nome: String)
        case motorista(nome: String)
        case admin(nome: String)
        case outro(tipo: String)
    }

    @Published private(set) var state: AppState = .verificando

    private let api = APIClient.shared
    private let store = TokenStore.shared

    /// Define o estado inicial a partir do token salvo (chamar no início do app).
    func bootstrap() {
        if store.hasSession, let tipo = store.tipoUsuario {
            state = route(tipo: tipo, nome: store.nome ?? "")
        } else {
            state = .deslogado
        }
    }

    /// Login por matrícula ou CPF (nunca e-mail).
    func login(identificador: String, senha: String) async throws {
        let response: LoginResponse = try await api.request(
            path: "auth/login",
            method: .post,
            body: LoginRequest(identificador: identificador, senha: senha)
        )

        store.save(
            idToken: response.idToken,
            refreshToken: response.refreshToken,
            tipoUsuario: response.tipoUsuario,
            nome: response.nome,
            uid: response.uid
        )

        state = route(tipo: response.tipoUsuario, nome: response.nome)
    }

    /// Cadastro de novo usuário. Não loga automaticamente.
    @discardableResult
    func register(
        matricula: String,
        senha: String,
        nome: String,
        email: String,
        documento: String,
        tipoDocumento: String
    ) async throws -> RegisterResponse {
        try await api.request(
            path: "users/register",
            method: .post,
            body: RegisterRequest(
                matricula: matricula,
                senha: senha,
                nome: nome,
                email: email,
                documento: documento,
                tipoDocumento: tipoDocumento
            )
        )
    }

    /// Logout: avisa o backend (best-effort) e limpa a sessão local de qualquer forma.
    func logout() async {
        let _: MessageResponse? = try? await api.request(
            path: "auth/logout",
            method: .post,
            authenticated: true
        )
        store.clear()
        state = .deslogado
    }

    // MARK: - Roteamento por papel

    /// aluno/professor -> passageiro; motorista -> motorista; adm/qualquer outro -> placeholder.
    private func route(tipo: String, nome: String) -> AppState {
        switch tipo.lowercased() {
        case "aluno", "professor":
            return .aluno(nome: nome)
        case "motorista":
            return .motorista(nome: nome)
        case "adm":
            return .admin(nome: nome)
        default:
            return .outro(tipo: tipo)
        }
    }
}
