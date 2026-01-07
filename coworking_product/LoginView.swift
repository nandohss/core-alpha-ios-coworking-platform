import SwiftUI
import Amplify
import UIKit

// MARK: - Blur util (mantido, caso use depois)
struct VisualEffectBlur: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - Login View
struct LoginView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("userId") var userId: String = ""
    @AppStorage("hasCompletedProfile") var hasCompletedProfile: Bool = false

    @State private var isAmplifyReady = false
    @State private var isLoading = false

    var body: some View {
        ZStack {
            // Background light
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color(.systemGray6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                Spacer()

                Text("Entre ou\ncadastre-se")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)

                // Social buttons
                HStack(spacing: 24) {
                    SocialButton(
                        imageName: "google",
                        altText: "Google"
                    ) {
                        Task {
                            guard isAmplifyReady else { return }

                            let session = try await Amplify.Auth.fetchAuthSession()
                            if session.isSignedIn {
                                _ = await Amplify.Auth.signOut()
                                hasCompletedProfile = false
                            }

                            loginComGoogle()
                        }
                    }

                    SocialButton(
                        imageName: "metamask_logo",
                        altText: "MetaMask (temporariamente indisponível)"
                    ) {
                        // desativado por enquanto
                    }
                    .disabled(true)
                    .opacity(0.8) // deixa visível mesmo desativado
                }

                Text("Conecte")
                    .foregroundColor(.gray)
                    .padding(.top, 32)

                Button {
                    print("Cadastro tradicional")
                } label: {
                    Text("Criar conta")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                .padding(.top, 16)

                Spacer()
            }
            .padding()

            if isLoading {
                LoadingOverlayView(message: "Carregando...")
            }
        }
        .onAppear {
            verificarConfiguracaoAmplify()
        }
    }

    // MARK: - Amplify
    func verificarConfiguracaoAmplify() {
        Task {
            do {
                let session = try await Amplify.Auth.fetchAuthSession()
                isLoggedIn = session.isSignedIn
                isAmplifyReady = true
            } catch {
                print("❌ Amplify não pronto:", error)
                isAmplifyReady = false
            }
        }
    }

    func loginComGoogle() {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first
        else {
            print("❌ Janela principal não encontrada")
            return
        }

        Task {
            do {
                let result = try await Amplify.Auth.signInWithWebUI(
                    for: .google,
                    presentationAnchor: window
                )
                print("✅ Login Google:", result)
                buscarDadosDoUsuario()
            } catch {
                print("❌ Erro login Google:", error)
            }
        }
    }

    func buscarDadosDoUsuario() {
        Task {
            isLoading = true

            do {
                let attributes = try await Amplify.Auth.fetchUserAttributes()
                let email = attributes.first { $0.key == .email }?.value ?? ""
                let name = attributes.first { $0.key == .name }?.value ?? ""
                let sub = attributes.first { $0.key.rawValue == "sub" }?.value ?? ""

                userId = sub
                let completed = UserDefaults.standard.bool(forKey: "didCompleteProfile_\(sub)")
                hasCompletedProfile = completed

                registrarUsuarioNoBackend(
                    userId: sub,
                    email: email,
                    name: name,
                    apelido: "sem_apelido"
                )

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isLoading = false
                    isLoggedIn = true
                }

            } catch {
                print("❌ Erro atributos:", error)
                isLoading = false
            }
        }
    }

    func registrarUsuarioNoBackend(
        userId: String,
        email: String,
        name: String,
        apelido: String
    ) {
        guard let url = URL(string: "https://i6yfbb45xc.execute-api.sa-east-1.amazonaws.com/pro/register") else {
            return
        }

        let body: [String: String] = [
            "userId": userId,
            "email": email,
            "name": name,
            "apelido": apelido
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request).resume()
    }
}

// MARK: - Social Button
struct SocialButton: View {
    var imageName: String
    var altText: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(imageName)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)   // ícone maior
                .frame(width: 72, height: 72)   // botão maior
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
                .cornerRadius(16)
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 10,
                    x: 0,
                    y: 6
                )
        }
        .accessibilityLabel(Text(altText))
    }
}
