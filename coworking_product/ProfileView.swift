import SwiftUI
import Amplify
import PhotosUI

struct ProfileView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @State private var showLogoutAlert = false
    @State private var isLoggingOut = false
    @State private var logoutErrorMessage: String? = nil

    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var isLoadingUser = true
    @State private var selectedImageData: Data? = nil
    @State private var photoItem: PhotosPickerItem? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    // ─── Cabeçalho ──────────────────────────────────────────
                    VStack(spacing: 8) {
                        PhotosPicker(
                            selection: $photoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            VStack {
                                if let imageData = selectedImageData,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 70, height: 70)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .foregroundColor(.gray)
                                        .frame(width: 70, height: 70)
                                }

                                Text("Editar")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                        .buttonStyle(.plain)

                        if !userName.isEmpty {
                            Text(userName)
                                .font(.title3.weight(.semibold))
                        }

                        if isLoadingUser {
                            ProgressView()
                        } else {
                            if !userEmail.isEmpty {
                                Text(userEmail)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()

                    // ─── Lista ─────────────────────────────────────────────
                    List {
                        ProfileNavigationItem(title: "Minhas informações",      icon: "line.3.horizontal",          destination: InfoView())
                        ProfileNavigationItem(title: "Pagamentos",              icon: "creditcard",                 destination: PaymentView())
                        ProfileNavigationItem(title: "Notificações",            icon: "bell",                       destination: NotificationView())
                        ProfileNavigationItem(title: "Segurança e privacidade", icon: "lock",                       destination: SecurityView())
                        ProfileNavigationItem(title: "Vouchers",                icon: "gift",                       destination: VoucherView())
                        ProfileNavigationItem(title: "Indicações",              icon: "arrowshape.turn.up.right",   destination: InviteView())
                        ProfileNavigationItem(title: "Saiba mais",              icon: "info.circle",                destination: AboutView())

                        // ─── Botão Sair ────────────────────────────────────
                        Button(role: .destructive) {
                            showLogoutAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.backward.square")
                                    .foregroundColor(.red)
                                Text("Sair")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .alert("Deseja mesmo sair?", isPresented: $showLogoutAlert) {
                        Button("Cancelar", role: .cancel) { }

                        Button("Sair", role: .destructive) {
                            Task {
                                await signOutUser()
                            }
                        }
                    }
                }

                // 📷 Responde à seleção de imagem
                .onChange(of: photoItem) {
                    Task {
                        if let data = try? await photoItem?.loadTransferable(type: Data.self) {
                            selectedImageData = data

                            // Envia para o S3
                            if let attributes = try? await Amplify.Auth.fetchUserAttributes(),
                               let userId = attributes.first(where: { $0.key.rawValue == "sub" })?.value {
                                await uploadPhotoToS3(data: data, userId: userId)
                            }
                        }
                    }
                }
            }

            .navigationBarTitleDisplayMode(.inline)

            // 🔄 Overlay de loading no logout
            .overlay(
                Group {
                    if isLoggingOut {
                        LoadingOverlayView(message: "Saindo...")
                    }
                }
            )

            // 🔴 Alerta de erro no logout
            .alert("Erro ao sair", isPresented: Binding<Bool>(
                get: { logoutErrorMessage != nil },
                set: { _ in logoutErrorMessage = nil }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(logoutErrorMessage ?? "Ocorreu um erro inesperado.")
            }

            // 🔄 Carrega dados e imagem do usuário
            .task {
                do {
                    let attributes = try await Amplify.Auth.fetchUserAttributes()
                    self.userName = attributes.first(where: { $0.key == .name })?.value ?? ""
                    self.userEmail = attributes.first(where: { $0.key == .email })?.value ?? ""
                    let userId = attributes.first(where: { $0.key.rawValue == "sub" })?.value ?? ""
                    self.isLoadingUser = false

                    await fetchPhotoFromS3(userId: userId)

                } catch {
                    print("❌ Erro ao carregar atributos do usuário: \(error)")
                    self.isLoadingUser = false
                }
            }
        }
    }

    // 🔐 Logout Cognito
    func signOutUser() async {
        isLoggingOut = true
        do {
            try await Amplify.Auth.signOut(options: .init(globalSignOut: true))
            print("✅ Logout concluído")
            isLoggedIn = false
        } catch {
            print("❌ Falha ao deslogar: \(error)")
            logoutErrorMessage = error.localizedDescription
        }
        isLoggingOut = false
    }

    // ⬆️ Upload para S3
    func uploadPhotoToS3(data: Data, userId: String) async {
        let key = "profile_photos/\(userId).jpg"
        do {
            _ = try await Amplify.Storage.uploadData(key: key, data: data)
            print("✅ Foto enviada para o S3 com sucesso.")
        } catch {
            print("❌ Falha ao enviar imagem para o S3:", error)
        }
    }

    // ⬇️ Download da imagem do S3
    func fetchPhotoFromS3(userId: String) async {
        let key = "profile_photos/\(userId).jpg"
        do {
            let data = try await Amplify.Storage.downloadData(key: key).value
            selectedImageData = data
            print("📥 Foto de perfil carregada do S3.")
        } catch {
            print("⚠️ Nenhuma foto encontrada no S3 ou erro ao baixar:", error)
        }
    }
}

struct ProfileNavigationItem<Destination: View>: View {
    let title: String
    let icon: String
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(title)
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    MainView()
}
