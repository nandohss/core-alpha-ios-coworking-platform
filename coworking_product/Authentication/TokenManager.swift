import Foundation
import Amplify
import AWSCognitoAuthPlugin
import AWSPluginsCore

class TokenManager: ObservableObject {
    static let shared = TokenManager()
    
    private init() {}
    
    /// Chame isso ao iniciar o app, logar, ou quando o app voltar para foreground
    func refreshToken() {
        Task {
            do {
                let session = try await Amplify.Auth.fetchAuthSession()
                if let cognitoSession = session as? AuthCognitoTokensProvider {
                    let tokens = try cognitoSession.getCognitoTokens().get()
                    let idToken = tokens.idToken
                    
                    // Salva no UserDefaults padrão, onde o repositório espera
                    UserDefaults.standard.set(idToken, forKey: "authToken")
                    print("✅ TokenManager: Auth token atualizado no UserDefaults.")
                } else {
                    print("⚠️ TokenManager: Sessão não é do tipo CognitoTokensProvider.")
                }
            } catch {
                print("❌ TokenManager: Erro ao buscar token: \(error)")
            }
        }
    }
    
    /// Atalho para limpar token no logout
    func clearToken() {
        UserDefaults.standard.removeObject(forKey: "authToken")
        print("🧹 TokenManager: Token removido.")
    }
}
