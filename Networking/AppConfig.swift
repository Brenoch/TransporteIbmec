import Foundation

/// Configuração de ambiente da aplicação.
enum AppConfig {
    /// Base URL da API (backend FastAPI).
    ///
    /// - Simulador: `http://localhost:8000/api/v1` (o simulador compartilha a rede do Mac).
    /// - Device físico: troque `localhost` pelo IP do Mac na rede local,
    ///   ex.: `http://192.168.0.10:8000/api/v1` (descubra com `ipconfig getifaddr en0`).
    static let baseURL = URL(string: "http://localhost:8000/api/v1")!

    /// Realtime Database (Firebase RTDB) para dados em tempo real (ex.: posição dos ônibus).
    static let rtdbURL = URL(string: "https://apponibusibmec-default-rtdb.firebaseio.com")!

    /// Web API Key do Firebase (caso seja necessário falar com o Firebase Auth REST direto).
    /// Deixe vazio enquanto toda a autenticação passar pelo backend FastAPI.
    static let webApiKey = "" // TODO: preencher se for usar Firebase Auth REST diretamente.
}
