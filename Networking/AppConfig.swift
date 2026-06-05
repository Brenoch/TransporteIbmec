import Foundation

/// Configuração central de endpoints do app.
///
/// Para apontar para outro backend (ex.: rodar num iPhone físico, que não enxerga
/// o `localhost` do Mac), basta trocar a constante `baseURL` abaixo por algo como
/// `http://192.168.0.10:8000/api/v1` (o IP da sua máquina na rede local).
enum AppConfig {

    /// API REST do backend. Default para o simulador (acessa o host via localhost).
    static let baseURL = URL(string: "http://localhost:8000/api/v1")!

    /// Firebase Realtime Database — usado nas fases de rota em tempo real (3+).
    static let rtdbURL = URL(string: "https://apponibusibmec-default-rtdb.firebaseio.com")!

    /// Web API Key do Firebase. Necessária apenas se o app for chamar a Web API
    /// do Firebase diretamente. Hoje toda a autenticação passa pelo backend REST.
    /// TODO: preencher quando/se for utilizada.
    static let webApiKey = ""
}
