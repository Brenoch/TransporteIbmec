import SwiftUI

struct CarteirinhaDigitalView: View {
    var body: some View {
        ZStack {
            Color.surface.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                HStack {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text("Carteirinha Digital")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.white)

                    Spacer()

                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal)
                .frame(height: 60)
                .background(Color.primaryContainer)

                ScrollView {
                    VStack(spacing: 22) {
                        Spacer().frame(height: 20)

                        VStack(spacing: 8) {
                            ZStack(alignment: .bottomTrailing) {
                                Image("student")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 130, height: 130)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                    .shadow(radius: 8)

                                Text("ATIVO")
                                    .font(.caption2)
                                    .bold()
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.successGreen)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }

                            Text("Ricardo Almeida")
                                .font(.title2)
                                .bold()
                                .foregroundColor(Color.primaryContainer)

                            Text("Matrícula: 2023081492")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Text("Administração")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        VStack(spacing: 16) {
                            Image("qrcode")
                                .resizable()
                                .frame(width: 180, height: 180)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(radius: 5)

                            Text("VALID UNTIL: 12/2026")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack {
                                Image("ibmec")
                                    .resizable()
                                    .frame(width: 40, height: 20)

                                Rectangle()
                                    .frame(width: 1, height: 12)
                                    .foregroundColor(.gray.opacity(0.4))

                                Text("Ibmec Scholar ID")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(Color.secondaryFixed)
                        .cornerRadius(24)

                        VStack(spacing: 12) {
                            Button(action: {}) {
                                Label("Compartilhar", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.primaryContainer)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }

                            Button(action: {}) {
                                Label("Baixar Offline", systemImage: "arrow.down.circle")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "#D7E2FF"))
                                    .foregroundColor(Color.primaryContainer)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.primaryContainer.opacity(0.1))
                                    )
                            }
                        }

                        Spacer().frame(height: 30)

                        Button(action: {}) {
                            Label("Sair da Conta", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.error)
                                .padding(.bottom, 40)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}
