import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager()

    var body: some View {
        Group {
            switch authManager.state {
            case .verificando:
                SplashView()

            case .deslogado:
                NavigationView {
                    LoginAlunoView()
                }
                .navigationViewStyle(.stack)

            case .aluno(let nome):
                AppPrincipalView(nomeAluno: nome)

            case .motorista(let nome):
                HomeMotoristaPlaceholderView(nome: nome)

            case .outro(let tipo):
                TipoNaoSuportadoView(tipo: tipo)
            }
        }
        .environmentObject(authManager)
        .task {
            await authManager.bootstrap()
        }
    }
}

// MARK: - Splash (placeholder; a Fase 2 melhora)

private struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.primaryContainer, Color.primary],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "bus.fill")
                    .font(.system(size: 56))
                    .foregroundColor(Color(hex: "#F5AC00"))
                ProgressView()
                    .tint(.white)
            }
        }
    }
}

// MARK: - App principal do aluno (as tabs atuais)

private struct AppPrincipalView: View {
    let nomeAluno: String

    var body: some View {
        TabView {
            MapaRotaView(nomeAluno: nomeAluno)
                .tabItem { Label("Mapa", systemImage: "map") }

            HomeAlunoView(nomeAluno: nomeAluno)
                .tabItem { Label("Home", systemImage: "house") }

            CarteirinhaDigitalView()
                .tabItem { Label("Carteirinha", systemImage: "person.text.rectangle") }
        }
        .tint(Color.primaryContainer)
    }
}

// MARK: - Placeholder do motorista (Fase 3 constrói)

private struct HomeMotoristaPlaceholderView: View {
    let nome: String
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        ZStack {
            Color.surface.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "steeringwheel")
                    .font(.system(size: 52))
                    .foregroundColor(Color.primaryContainer)
                Text("Home do Motorista")
                    .font(.title2).fontWeight(.bold)
                    .foregroundColor(Color.primaryContainer)
                Text(nome.isEmpty ? "Motorista" : nome)
                    .foregroundColor(.secondary)
                Text("Em construção (Fase 3).")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Button("Sair") {
                    Task { await authManager.logout() }
                }
                .padding(.top, 8)
            }
            .padding()
        }
    }
}

// MARK: - Tipo de usuário não suportado

private struct TipoNaoSuportadoView: View {
    let tipo: String
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        ZStack {
            Color.surface.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "desktopcomputer")
                    .font(.system(size: 48))
                    .foregroundColor(Color.primaryContainer)
                Text("Acesso pelo app indisponível")
                    .font(.headline)
                    .foregroundColor(Color.primaryContainer)
                Text("Este perfil (\(tipo)) deve usar o painel administrativo.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button("Sair") {
                    Task { await authManager.logout() }
                }
                .padding(.top, 4)
            }
            .padding()
        }
    }
}

// MARK: - Login

private struct LoginAlunoView: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var identificador = ""
    @State private var senha = ""
    @State private var mostrarSenha = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.primaryContainer, Color.primary],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack {
                cabecalho
                Spacer()
                cartaoLogin
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .navigationBarHidden(true)
    }

    private var cabecalho: some View {
        VStack(spacing: 10) {
            Image(systemName: "bus.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "#F5AC00"))

            Text("ibmec")
                .font(.title).fontWeight(.bold)
                .foregroundColor(.white)

            Text("Bem-vindo(a)")
                .font(.title3).fontWeight(.bold)
                .foregroundColor(.white)

            Text("Acesse o app de transporte universitario")
                .font(.caption)
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(.top, 40)
    }

    private var cartaoLogin: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color(hex: "#F5AC00"))
                .frame(width: 40, height: 4)
                .padding(.top, 10)

            Text("Entrar")
                .font(.headline)
                .foregroundColor(Color.primaryContainer)

            VStack(alignment: .leading, spacing: 6) {
                Text("Matrícula ou CPF")
                    .font(.caption)
                    .foregroundColor(.gray)

                TextField("Digite sua matrícula ou CPF", text: $identificador)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Senha")
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack {
                    Group {
                        if mostrarSenha {
                            TextField("Digite sua senha", text: $senha)
                        } else {
                            SecureField("Digite sua senha", text: $senha)
                        }
                    }

                    Button(action: { mostrarSenha.toggle() }) {
                        Image(systemName: mostrarSenha ? "eye" : "eye.slash")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(Color.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: realizarLogin) {
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView().tint(.white)
                    }
                    Text(isLoading ? "Entrando..." : "Entrar")
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color.primaryContainer)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isLoading || identificador.isEmpty || senha.isEmpty)

            NavigationLink {
                EsqueciSenhaView()
            } label: {
                Text("Esqueci minha senha")
                    .font(.subheadline)
                    .foregroundColor(Color.primaryContainer)
            }

            HStack(spacing: 4) {
                Text("Nao tem conta?")
                    .font(.footnote)
                    .foregroundColor(.gray)

                NavigationLink {
                    CadastroAlunoView()
                } label: {
                    Text("Criar cadastro")
                        .font(.footnote).fontWeight(.semibold)
                        .foregroundColor(Color.primaryContainer)
                }
            }

            Spacer(minLength: 8)

            Text("Ao entrar, voce concorda com os Termos de Uso e Politica de Privacidade.")
                .font(.caption2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(maxHeight: 560)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func realizarLogin() {
        errorMessage = nil
        isLoading = true

        Task { @MainActor in
            defer { isLoading = false }
            do {
                try await authManager.login(identificador: identificador, senha: senha)
                // Sucesso: o AuthManager troca o `state` e a raiz re-roteia sozinha.
            } catch let error as AppError {
                // Para .api, errorDescription devolve o `detail` do envelope do backend.
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "Não foi possível conectar ao servidor."
            }
        }
    }
}
