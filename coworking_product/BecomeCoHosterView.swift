import SwiftUI
import UIKit
import CoreMotion
import Amplify


struct BecomeCoHosterView: View {
    @AppStorage("userId") var userId: String = ""
    @Binding var hideTabBar: Bool
    @Binding var selectedTab: Int
    
    @State private var imagemSelecionada: UIImage?
    @State private var mostrarImagePicker = false
    @State private var spaceIdGerado: String? = nil


    @StateObject private var formData = FormData()
    @State private var showForm = false
    @State private var etapaAtual = 0
    private let totalEtapas = 6

    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var focusedField: SpaceFormField?

    private var topInset: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .windows.first?.safeAreaInsets.top ?? 0
    }
    private var bottomInset: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .windows.first?.safeAreaInsets.bottom ?? 0
    }


    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            homePromo
        }
        .sheet(isPresented: $showForm) {
            AddOrEditSpaceFormView(isPresented: $showForm)
        }
    }

    private var homePromo: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                HStack {
                    Button { selectedTab = 2 } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.black.opacity(0.05))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.leading, 16)
                .padding(.top, topInset + 8)

                Text("Anuncie seu espaço")
                    .font(.largeTitle.bold())
                    .padding(.top, 10)

                infoBlock("Ganhe mais", "Fature até 3× com seu espaço ocioso.", "chart.line.uptrend.xyaxis")
                infoBlock("Visibilidade", "Seu espaço visível para milhares de usuários.", "eye.fill")
                infoBlock("Controle total", "Você escolhe horários, preços e disponibilidade.", "slider.horizontal.3")

                Button("Quero anunciar meu espaço") { showForm = true }
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
        }
    }

    private func infoBlock(_ title: String, _ text: String, _ icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .padding()
                .background(Color.black)
                .clipShape(Circle())
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundColor(.gray)
            }
        }
    }
}


func uploadImagemParaS3(_ imagem: UIImage, comId spaceId: String, completion: @escaping (String) -> Void) {
    guard let data = imagem.jpegData(compressionQuality: 0.8) else {
        print("❌ Falha ao converter imagem em JPEG")
        return
    }

    let key = "spaces/\(spaceId).jpg"

    Task {
        do {
            let options = StorageUploadDataRequest.Options(accessLevel: .guest)
            _ = try await Amplify.Storage.uploadData(key: key, data: data, options: options)
            print("✅ Imagem do espaço enviada com sucesso: \(key)")

            let url = "https://amplifycoworkingappb1e516e5e7f54784b0eff05a3d518a9eb-staging.s3.sa-east-1.amazonaws.com/public/\(key)"
            print("📸 URL permanente da imagem:", url)

            completion(url)

        } catch {
            print("❌ Falha ao enviar imagem para o S3:", error)
        }
    }
}
