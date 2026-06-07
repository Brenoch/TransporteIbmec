import Foundation

/// Persistência dos dados de sessão.
///
/// Usa `UserDefaults` por simplicidade.
/// TODO: migrar para Keychain — tokens em texto no UserDefaults não é o ideal em produção.
final class TokenStore {
    static let shared = TokenStore()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let idToken = "auth.idToken"
        static let refreshToken = "auth.refreshToken"
        static let tipoUsuario = "auth.tipoUsuario"
        static let nome = "auth.nome"
        static let uid = "auth.uid"
    }

    private init() {}

    // MARK: Getters

    var idToken: String? { defaults.string(forKey: Keys.idToken) }
    var refreshToken: String? { defaults.string(forKey: Keys.refreshToken) }
    var tipoUsuario: String? { defaults.string(forKey: Keys.tipoUsuario) }
    var nome: String? { defaults.string(forKey: Keys.nome) }
    var uid: String? { defaults.string(forKey: Keys.uid) }

    /// Há uma sessão salva (idToken presente e não vazio).
    var hasSession: Bool { (idToken?.isEmpty == false) }

    // MARK: Mutations

    func save(idToken: String, refreshToken: String, tipoUsuario: String, nome: String, uid: String) {
        defaults.set(idToken, forKey: Keys.idToken)
        defaults.set(refreshToken, forKey: Keys.refreshToken)
        defaults.set(tipoUsuario, forKey: Keys.tipoUsuario)
        defaults.set(nome, forKey: Keys.nome)
        defaults.set(uid, forKey: Keys.uid)
    }

    /// Atualiza SOMENTE o idToken, preservando o refreshToken (que não rotaciona) e os demais dados.
    func updateIdToken(_ idToken: String) {
        defaults.set(idToken, forKey: Keys.idToken)
    }

    func clear() {
        [Keys.idToken, Keys.refreshToken, Keys.tipoUsuario, Keys.nome, Keys.uid]
            .forEach { defaults.removeObject(forKey: $0) }
    }
}
