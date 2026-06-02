import SwiftUI

struct CadastroAlunoView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var nome = ""
    @State private var email = ""
    @State private var matricula = ""
    @State private var senha = ""
    @State private var confirmarSenha = ""
    @State private var aceitouTermos = false

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
                        campoSeguro(titulo: "Senha", placeholder: "Crie sua senha", text: $senha)
                        campoSeguro(titulo: "Confirmar senha", placeholder: "Repita sua senha", text: $confirmarSenha)
                    }

                    Toggle(isOn: $aceitouTermos) {
                        Text("Li e aceito os Termos de Uso e Politica de Privacidade")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .toggleStyle(.switch)

                    Button(action: {}) {
                        Text("Finalizar cadastro")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(aceitouTermos ? Color.primaryContainer : Color.outline.opacity(0.4))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(!aceitouTermos)
                }
                .padding(20)
            }
        }
        .navigationTitle("Cadastro")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.primaryContainer)
                }
            }
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
}
