//
//  coworking_productApp.swift
//  coworking_product
//
//  Created by Fernando on 03/07/25.
//

import SwiftUI
import Amplify
import AWSCognitoAuthPlugin
import AWSS3StoragePlugin // ✅ Importa o plugin de Storage

@main
struct coworking_productApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @AppStorage("hasCompletedProfile") private var hasCompletedProfile = false
    @AppStorage("userId") private var userId: String = ""
    @State private var showSplash = true

    private func syncProfileCompletionFromDefaults() {
        if let id = UserDefaults.standard.string(forKey: "userId") {
            let completed = UserDefaults.standard.bool(forKey: "didCompleteProfile_\(id)")
            hasCompletedProfile = completed
            print("🔄 Sync hasCompletedProfile =", completed, "for user", id)
        }
    }

    init() {
        Amplify.Logging.logLevel = .verbose
        configureAmplify()
        
        verificarHosterAoIniciar()
        
        syncProfileCompletionFromDefaults()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            print("✅ Pronto para login")
        }
    }

    private func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin()) // ✅ Adiciona o plugin de Storage
            try Amplify.configure()
            print("✅ Amplify configurado com sucesso!")
        } catch {
            print("❌ Erro ao configurar Amplify: \(error)")
        }
    }
    
    func verificarHosterAoIniciar() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }

        // Exemplo de chamada GET à sua Lambda
        guard let url = URL(string: "https://i6yfbb45xc.execute-api.sa-east-1.amazonaws.com/pro/users/\(userId)") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let isHoster = json["isHoster"] as? Bool {
                UserDefaults.standard.set(isHoster, forKey: "isHoster")
                print("✅ isHoster atualizado ao iniciar: \(isHoster)")
            }
        }.resume()
    }

    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashScreenView {
                    showSplash = false
                }
            } else {
                if !hasLaunchedBefore {
                    ContentView()
                        .onAppear { hasLaunchedBefore = true }
                } else {
                    if isLoggedIn {
                        AnyView(MainView())
                            .onAppear { syncProfileCompletionFromDefaults() }
                            .onChange(of: userId) { _ in syncProfileCompletionFromDefaults() }
                            .onChange(of: isLoggedIn) { _ in syncProfileCompletionFromDefaults() }
                            .fullScreenCover(
                                isPresented: Binding(
                                    get: { isLoggedIn && !userId.isEmpty && !UserDefaults.standard.bool(forKey: "didCompleteProfile_\(userId)") },
                                    set: { _ in }
                                )
                            ) {
                                CompleteUserProfileView(
                                    isPresented: Binding(
                                        get: { !hasCompletedProfile },
                                        set: { _ in }
                                    )
                                )
                            }
                    } else {
                        AnyView(LoginView())
                    }
                }
            }
        }
    }
}

