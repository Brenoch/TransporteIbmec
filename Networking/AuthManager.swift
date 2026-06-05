import Foundation
import Combine

/// Fonte de verdade da sessão. As telas observam `state` e se roteiam por ele.
@MainActor
final class AuthManager: ObservableObject {

    enum AppState {
        case verificando
        case deslogado
        case aluno(nome: String)
        case motorista(nome: String)
        case outro(tipo: String)
    }

    @Published var state: AppState = .verificando

    private let api: APIClient
    private let tokenStore: TokenStore

    init(api: APIClient = .shared, tokenStore: TokenStore = .shared) {
        self.api = api
        self.tokenStore = tokenStore
    }

    /// Define o estado inicial a partir da sessão salva, SEM chamar a API.
    /// (Chamado no `.task` da raiz, na inicialização do app.)
    func bootstrap() async {
        guard tokenStore.hasSession, let tipo = tokenStore.tipoUsuario else {
            state = .deslogado
            return
        }
        state = estado(tipo: tipo, nome: tokenStore.nome ?? "")
    }

    /// POST /auth/login. Salva os tokens e atualiza o `state`.
    func login(identificador: String, senha: String) async throws {
        let req = LoginRequest(identificador: identificador, senha: senha)
        let resp: LoginResponse = try await api.request("/auth/login",
                                                        method: "POST",
                                                        body: req,
                                                        authorized: false)
        tokenStore.save(idToken: resp.idToken,
                        refreshToken: resp.refreshToken,
                        tipoUsuario: resp.tipoUsuario,
                        nome: resp.nome,
                        uid: resp.uid)
        state = estado(tipo: resp.tipoUsuario, nome: resp.nome)
    }

    /// POST /users/register (sem auth). Devolve o usuário criado.
    @discardableResult
    func register(_ req: RegisterRequest) async throws -> RegisterResponse {
        try await api.request("/users/register",
                              method: "POST",
                              body: req,
                              authorized: false)
    }

    /// Tenta POST /auth/logout, limpa a sessão e volta para `.deslogado`.
    /// Mesmo que o logout no servidor falhe, a sessão local é descartada.
    func logout() async {
        let _: EmptyResponse? = try? await api.request("/auth/logout",
                                                       method: "POST",
                                                       authorized: true)
        tokenStore.clear()
        state = .deslogado
    }

    // MARK: - Helpers

    private func estado(tipo: String, nome: String) -> AppState {
        switch tipo.lowercased() {
        case "aluno", "professor":   // ambos usam o fluxo do passageiro (.aluno)
            return .aluno(nome: nome)
        case "motorista":
            return .motorista(nome: nome)
        default:                     // "adm" e quaisquer outros perfis
            return .outro(tipo: tipo)
        }
    }
}
