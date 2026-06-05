import SwiftUI

struct CadastroAlunoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager

    @State private var nome = ""
    @State private var email = ""
    @State private var matricula = ""
    @State private var documento = ""
    @State private var tipoDocumento = "CPF"          // "CPF" | "Passaporte"
    @State private var senha = ""
    @State private var confirmarSenha = ""
    @State private var aceitouTermos = false

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var sucesso = false

    private let tiposDocumento = ["CPF", "Passaporte"]

    private var senhasConferem: Bool {
        senha == confirmarSenha
    }

    private var podeEnviar: Bool {
        !nome.isEmpty && !email.isEmpty && !matricula.isEmpty &&
        !documento.isEmpty && !senha.isEmpty && senhasConferem &&
        aceitouTermos && !isLoading
    }

    var body: some View {
        ZStack {
            Color.surface
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    topo

                    Group {
                        campo(titulo: "Nome completo", placeholder: "Digite seu nome", text: $nome)
                        campo(titulo: "E-mail institucional", placeholder: "nome@aluno.ibmec.edu.br", text: $email)
                        campo(titulo: "Matricula", placeholder: "2023xxxxxx", text: $matricula)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Tipo de documento")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Picker("Tipo de documento", selection: $tipoDocumento) {
                                ForEach(tiposDocumento, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.segmented)
                        }

                        campo(titulo: tipoDocumento == "CPF" ? "CPF" : "Passaporte",
                              placeholder: tipoDocumento == "CPF" ? "000.000.000-00" : "Número do passaporte",
                              text: $documento)

                        campoSeguro(titulo: "Senha", placeholder: "Crie sua senha", text: $senha)
                        campoSeguro(titulo: "Confirmar senha", placeholder: "Repita sua senha", text: $confirmarSenha)
                    }

                    if !confirmarSenha.isEmpty && !senhasConferem {
                        aviso("As senhas não coincidem.")
                    }
                    if let errorMessage = errorMessage {
                        aviso(errorMessage)
                    }

                    Toggle(isOn: $aceitouTermos) {
                        Text("Li e aceito os Termos de Uso e Politica de Privacidade")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .toggleStyle(.switch)

                    Button(action: finalizarCadastro) {
                        HStack(spacing: 10) {
                            if isLoading {
                                ProgressView().tint(.white)
                            }
                            Text(isLoading ? "Enviando..." : "Finalizar cadastro")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(podeEnviar ? Color.primaryContainer : Color.outline.opacity(0.4))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(!podeEnviar)
                }
                .padding(20)
            }
        }
        .navigationTitle("Cadastro")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.primaryContainer)
                }
            }
        }
        .alert("Cadastro realizado", isPresented: $sucesso) {
            Button("OK") { dismiss() }
        } message: {
            Text("Sua conta foi criada. Verifique seu e-mail para confirmar o acesso e faça login.")
        }
    }

    private var topo: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(Color.primaryContainer)

            Text("Criar conta")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color.primaryContainer)

            Text("Preencha os dados para solicitar acesso ao transporte")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 6)
    }

    private func campo(titulo: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo)
                .font(.caption)
                .foregroundColor(.secondary)

            TextField(placeholder, text: text)
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.secondaryFixed, lineWidth: 1)
                )
        }
    }

    private func campoSeguro(titulo: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo)
                .font(.caption)
                .foregroundColor(.secondary)

            SecureField(placeholder, text: text)
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.secondaryFixed, lineWidth: 1)
                )
        }
    }

    private func aviso(_ texto: String) -> some View {
        Text(texto)
            .font(.caption)
            .foregroundColor(Color.error)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func finalizarCadastro() {
        errorMessage = nil
        isLoading = true

        let req = RegisterRequest(matricula: matricula,
                                  senha: senha,
                                  nome: nome,
                                  email: email,
                                  documento: documento,
                                  tipoDocumento: tipoDocumento)

        Task { @MainActor in
            defer { isLoading = false }
            do {
                _ = try await authManager.register(req)
                sucesso = true                       // alert → OK volta para o login
            } catch let error as AppError {
                errorMessage = error.errorDescription // ex.: usuario_ja_existe → detail
            } catch {
                errorMessage = "Não foi possível concluir o cadastro."
            }
        }
    }
}
