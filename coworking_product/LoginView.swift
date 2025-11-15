import SwiftUI
import Amplify
import UIKit

struct VisualEffectBlur: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct LoginView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("userId") var userId: String = "" // ✅ Armazena userId (sub do Cognito)

    @State private var isAmplifyReady = false
    @State private var isLoading = false

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.white, Color(.systemGray5)]),
                           startPoint: .top,
                           endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                Text("Entre ou\ncadastre-se")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 40)

                VStack(spacing: 20) {
                    SocialButton(imageName: "google", altText: "Google") {
                        Task {
                            guard isAmplifyReady else { return }

                            let session = try await Amplify.Auth.fetchAuthSession()
                            if session.isSignedIn {
                                _ = await Amplify.Auth.signOut()
                            }

                            await loginComGoogle()
                        }
                    }

                    AppleSignInButton {
                        Task {
                            guard isAmplifyReady else { return }

                            let session = try await Amplify.Auth.fetchAuthSession()
                            if session.isSignedIn {
                                _ = await Amplify.Auth.signOut()
                            }

                            await loginComApple()
                        }
                    }
                }

                Text("Conecte")
                    .foregroundColor(.gray)
                    .padding(.top, 40)

                Button(action: {
                    print("Cadastro tradicional")
                }) {
                    Text("Criar conta")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
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
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("❌ Janela principal não encontrada")
            return
        }

        Task {
            do {
                let result = try await Amplify.Auth.signInWithWebUI(for: .google, presentationAnchor: window)
                print("✅ Login com Google concluído: \(result)")
                buscarDadosDoUsuario()
            } catch {
                print("❌ Erro no login com Google: \(error)")
            }
        }
    }

    func loginComApple() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("❌ Janela principal não encontrada")
            return
        }

        Task {
            do {
                let result = try await Amplify.Auth.signInWithWebUI(for: .apple, presentationAnchor: window)
                print("✅ Login com Apple concluído: \(result)")
                buscarDadosDoUsuario()
            } catch {
                print("❌ Erro no login com Apple: \(error)")
            }
        }
    }

    func buscarDadosDoUsuario() {
        Task {
            isLoading = true

            do {
                let attributes = try await Amplify.Auth.fetchUserAttributes()
                let email = attributes.first(where: { $0.key == .email })?.value ?? ""
                let name = attributes.first(where: { $0.key == .name })?.value ?? ""
                let sub = attributes.first(where: { $0.key.rawValue == "sub" })?.value ?? ""
                let apelido = "sem_apelido"

                self.userId = sub // ✅ Salva o userId localmente

                print("📥 Email: \(email)\n📥 Nome: \(name)\n📥 userId (sub): \(sub)")

                registrarUsuarioNoBackend(userId: sub, email: email, name: name, apelido: apelido)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isLoading = false
                    isLoggedIn = true
                }

            } catch {
                print("❌ Erro ao buscar atributos: \(error)")
                isLoading = false
            }
        }
    }

    func registrarUsuarioNoBackend(userId: String, email: String, name: String, apelido: String) {
        guard let url = URL(string: "https://i6yfbb45xc.execute-api.sa-east-1.amazonaws.com/pro/register") else {
            print("❌ URL inválida")
            return
        }

        let dados: [String: String] = [
            "userId": userId,
            "email": email,
            "name": name,
            "apelido": apelido
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(dados)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erro ao chamar Lambda: \(error)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Resposta HTTP inválida")
                return
            }

            print("📡 Lambda HTTP Status: \(httpResponse.statusCode)")

            if let data = data {
                print("📦 Resposta da Lambda: \(String(data: data, encoding: .utf8) ?? "sem conteúdo")")
            }
        }.resume()
    }
}

struct SocialButton: View {
    var imageName: String
    var altText: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 2)
        }
        .accessibilityLabel(Text(altText))
    }
}

struct AppleSignInButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "apple.logo")
                    .font(.system(size: 20, weight: .bold))
                Text("Sign in with Apple")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .accessibilityLabel(Text("Sign in with Apple"))
    }
}
