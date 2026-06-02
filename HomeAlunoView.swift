import SwiftUI

struct HomeAlunoView: View {
    let nomeAluno: String

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.blue)

                Text("Home do Aluno")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Bem-vindo, \(nomeAluno.isEmpty ? "aluno" : nomeAluno)!")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Início")
        .navigationBarTitleDisplayMode(.inline)
    }
}
