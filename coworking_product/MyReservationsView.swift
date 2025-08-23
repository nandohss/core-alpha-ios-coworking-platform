import SwiftUI
import Amplify

// MARK: - Model da Reserva
struct ReservaResumo: Identifiable, Decodable {
    var id: String { "\(spaceId_reservation)_\(date_reservation)" }
    let spaceId_reservation: String
    let datetime_reservation: String
    let status: String
    let userId: String
    let date_reservation: String
    let hour_reservation: String
    let created_at: String

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "pt_BR")
        if let date = formatter.date(from: date_reservation) {
            formatter.dateStyle = .long
            return formatter.string(from: date)
        }
        return date_reservation
    }

    var formattedHour: String {
        return "\(hour_reservation)h"
    }
}

// MARK: - Modelo do Espaço
struct CoworkingInfo: Decodable {
    let spaceId: String
    let name: String
    let imagemUrl: String?
}

// MARK: - ViewModel
@MainActor
class MinhasReservasViewModel: ObservableObject {
    @Published var reservas: [ReservaResumo] = []
    @Published var coworkings: [String: CoworkingInfo] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    var reservasAgrupadas: [String: [ReservaResumo]] {
        Dictionary(grouping: reservas, by: { "\($0.spaceId_reservation)_\($0.date_reservation)" })
    }

    func carregarReservas(userId: String) async {
        print("🔄 Iniciando carregamento de reservas para usuário: \(userId)")
        guard let url = URL(string: "https://i6yfbb45xc.execute-api.sa-east-1.amazonaws.com/pro/reservations/user?userId=\(userId)") else {
            self.errorMessage = "URL inválida"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 JSON recebido:\n\(jsonString)")
            }
            let decoded = try JSONDecoder().decode([ReservaResumo].self, from: data)
            self.reservas = decoded
            await carregarCoworkings()
        } catch {
            self.errorMessage = "Erro ao carregar reservas: \(error.localizedDescription)"
        }
    }

    func carregarCoworkings() async {
        guard let url = URL(string: "https://i6yfbb45xc.execute-api.sa-east-1.amazonaws.com/pro/spaces") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([CoworkingInfo].self, from: data)
            var mapa: [String: CoworkingInfo] = [:]
            for coworking in decoded {
                mapa[coworking.spaceId] = coworking
            }
            self.coworkings = mapa
        } catch {
            print("Erro ao carregar coworkings: \(error.localizedDescription)")
        }
    }
}

// MARK: - View
struct MyReservationsView: View {
    @StateObject private var viewModel = MinhasReservasViewModel()
    @State private var userId: String? = nil

    var body: some View {
        NavigationStack {
            VStack {
                if userId == nil {
                    ProgressView("Carregando usuário...")
                } else if viewModel.isLoading {
                    ProgressView("Carregando reservas...")
                } else if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red)
                } else if viewModel.reservas.isEmpty {
                    Text("Nenhuma reserva encontrada.")
                        .foregroundColor(.gray)
                        .padding(.top, 100)
                } else {
                    List {
                        ForEach(viewModel.reservasAgrupadas.sorted(by: { $0.key < $1.key }), id: \.key) { _, reservasGrupo in
                            if let primeira = reservasGrupo.first,
                               let coworking = viewModel.coworkings[primeira.spaceId_reservation] {
                                NavigationLink(destination: ReservationGroupDetailView(reservas: reservasGrupo, coworking: coworking)) {
                                    HStack(spacing: 12) {
                                        AsyncImage(url: URL(string: coworking.imagemUrl ?? "")) { image in
                                            image.resizable()
                                        } placeholder: {
                                            Color.gray.opacity(0.2)
                                        }
                                        .frame(width: 80, height: 60)
                                        .cornerRadius(8)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(coworking.name)
                                                .font(.headline)
                                            Text(primeira.formattedDate)
                                                .font(.subheadline)
                                            Text(reservasGrupo.map { $0.formattedHour }.joined(separator: ", "))
                                                .font(.footnote)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .task {
                if let attributes = try? await Amplify.Auth.fetchUserAttributes(),
                   let sub = attributes.first(where: { $0.key.rawValue == "sub" })?.value {
                    userId = sub
                    await viewModel.carregarReservas(userId: sub)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Minhas Reservas")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}


struct ReservationGroupDetailView: View {
    let reservas: [ReservaResumo]
    let coworking: CoworkingInfo

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AsyncImage(url: URL(string: coworking.imagemUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipped()

                VStack(spacing: 12) {
                    Text(coworking.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    if let data = reservas.first?.formattedDate {
                        Text("Data: \(data)")
                            .font(.subheadline)
                    }

                    Text("Horários: \(reservas.map { $0.formattedHour }.joined(separator: ", "))")
                        .font(.footnote)
                        .foregroundColor(.gray)

                    if let qrString = gerarQRString(reservas: reservas, coworking: coworking) {
                        Image(uiImage: generateQRCode(from: qrString))
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                            .padding()
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 24)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Detalhes da Reserva")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
        }
    }

    func gerarQRString(reservas: [ReservaResumo], coworking: CoworkingInfo) -> String? {
        let horas = reservas.map { $0.hour_reservation }.joined(separator: ", ")
        return "Espaço: \(coworking.name)\nData: \(reservas.first?.date_reservation ?? "")\nHorários: \(horas)"
    }

    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")

        if let outputImage = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
           let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgimg)
        }
        return UIImage()
    }
}

