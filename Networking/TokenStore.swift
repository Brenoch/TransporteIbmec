import Foundation

/// Persistência da sessão do usuário entre execuções do app.
///
/// TODO: migrar `idToken` e `refreshToken` para o Keychain. Por enquanto usa
/// `UserDefaults` pela simplicidade — não é o lugar ideal para tokens sensíveis.
final class TokenStore {
    static let shared = TokenStore()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private enum Keys {
        static let idToken = "auth.idToken"
        static let refreshToken = "auth.refreshToken"
        static let tipoUsuario = "auth.tipoUsuario"
        static let nome = "auth.nome"
        static let uid = "auth.uid"
    }

    // MARK: Getters

    var idToken: String? { defaults.string(forKey: Keys.idToken) }
    var refreshToken: String? { defaults.string(forKey: Keys.refreshToken) }
    var tipoUsuario: String? { defaults.string(forKey: Keys.tipoUsuario) }
    var nome: String? { defaults.string(forKey: Keys.nome) }
    var uid: String? { defaults.string(forKey: Keys.uid) }

    /// Há uma sessão salva (token presente)?
    var hasSession: Bool { idToken != nil }

    // MARK: Mutações

    func save(idToken: String,
              refreshToken: String,
              tipoUsuario: String,
              nome: String,
              uid: String) {
        defaults.set(idToken, forKey: Keys.idToken)
        defaults.set(refreshToken, forKey: Keys.refreshToken)
        defaults.set(tipoUsuario, forKey: Keys.tipoUsuario)
        defaults.set(nome, forKey: Keys.nome)
        defaults.set(uid, forKey: Keys.uid)
    }

    /// Atualiza somente os tokens após uma renovação bem-sucedida (/auth/refresh).
    func updateTokens(idToken: String, refreshToken: String? = nil) {
        defaults.set(idToken, forKey: Keys.idToken)
        if let refreshToken = refreshToken {
            defaults.set(refreshToken, forKey: Keys.refreshToken)
        }
    }

    func clear() {
        [Keys.idToken, Keys.refreshToken, Keys.tipoUsuario, Keys.nome, Keys.uid]
            .forEach { defaults.removeObject(forKey: $0) }
    }
}
