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
                MotoristaPlaceholderView(nome: nome)
            case .outro(let tipo):
                AcessoIndisponivelView(tipo: tipo)
            }
        }
        .environmentObject(authManager)
        .task { authManager.bootstrap() }
    }
}

// MARK: - Splash

private struct SplashView: View {
    var body: some View {
        ZStack {
            Color.ibmecBlue.ignoresSafeArea()
            VStack(spacing: 24) {
                AuthBrandLogo()
                ProgressView()
                    .tint(.white)
            }
        }
    }
}

// MARK: - App principal (passageiro)

private struct AppPrincipalView: View {
    let nomeAluno: String
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeAlunoView(nomeAluno: nomeAluno, irParaCarteirinha: { selectedTab = 1 })
                .tabItem { Label("Home", systemImage: "house") }
                .tag(0)

            CarteirinhaDigitalView()
                .tabItem { Label("Carteirinha", systemImage: "person.text.rectangle") }
                .tag(1)
        }
        .tint(Color.ibmecBlue)
    }
}

// MARK: - Placeholders (motorista / acesso indisponível)

private struct MotoristaPlaceholderView: View {
    let nome: String
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        ZStack {
            Color.ibmecBlue.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "bus.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.ibmecAccent)

                Text("Olá, \(nome.isEmpty ? "motorista" : nome)")
                    .font(.title2).bold()
                    .foregroundColor(.white)

                Text("O app do motorista está em construção.")
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                BotaoSair()
            }
            .padding(32)
        }
    }
}

private struct AcessoIndisponivelView: View {
    let tipo: String

    var body: some View {
        ZStack {
            Color.ibmecBlue.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.ibmecAccent)

                Text("Acesso pelo app indisponível")
                    .font(.title3).bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Perfil \"\(tipo)\". Use o painel administrativo.")
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                BotaoSair()
            }
            .padding(32)
        }
    }
}

private struct BotaoSair: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        Button(action: { Task { await authManager.logout() } }) {
            Text("Sair")
                .font(.headline)
                .foregroundColor(.ibmecBlue)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(Capsule())
        }
        .padding(.top, 12)
    }
}

// MARK: - Login

private struct LoginAlunoView: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var identificador = ""
    @State private var senha = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var irParaCadastro = false
    @State private var irParaEsqueciSenha = false

    var body: some View {
        AuthScaffold {
            VStack(spacing: 6) {
                AuthBrandLogo()
                    .padding(.bottom, 6)

                Text("Bem-vindo(a)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("Acesse o aplicativo de transporte Ibmec")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        } content: {
            VStack(spacing: 0) {
                AuthTabs(
                    selected: .entrar,
                    onEntrar: {},
                    onCadastrar: { irParaCadastro = true }
                )
                .padding(.top, 20)
                .padding(.bottom, 28)

                VStack(spacing: 18) {
                    AuthField(label: "Matrícula ou CPF", text: $identificador, keyboardType: .numberPad)

                    AuthField(label: "Senha", text: $senha, isSecure: true)

                    Button(action: { irParaEsqueciSenha = true }) {
                        Text("Esqueci minha senha")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.ibmecBlue)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    AuthPrimaryButton(
                        title: isLoading ? "Entrando..." : "Entrar",
                        isLoading: isLoading,
                        enabled: !identificador.isEmpty && !senha.isEmpty,
                        action: realizarLogin
                    )
                    .padding(.top, 4)
                }

                Spacer(minLength: 16)

                termos
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 28)

            navegacao
        }
    }

    private var termos: some View {
        VStack(spacing: 2) {
            Text("Ao entrar, você concorda com nossos")
            HStack(spacing: 4) {
                Text("Termos de Uso").underline()
                Text("e")
                Text("Política de Privacidade").underline()
            }
        }
        .font(.system(size: 11))
        .foregroundColor(.gray)
        .multilineTextAlignment(.center)
    }

    private var navegacao: some View {
        Group {
            NavigationLink(destination: CadastroAlunoView(), isActive: $irParaCadastro) { EmptyView() }.hidden()
            NavigationLink(destination: EsqueciSenhaView(), isActive: $irParaEsqueciSenha) { EmptyView() }.hidden()
        }
    }

    private func realizarLogin() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                try await authManager.login(identificador: identificador, senha: senha)
                // Sucesso: o estado do AuthManager muda e o ContentView troca a tela.
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
