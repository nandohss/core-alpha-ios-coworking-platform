import SwiftUI
import Amplify

// Simple shimmer effect (same as Home)
fileprivate struct ShimmerView: View {
    @State private var start: CGFloat = -1
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.gray.opacity(0.2),
                Color.gray.opacity(0.35),
                Color.gray.opacity(0.2)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            Rectangle()
                .fill(
                    LinearGradient(colors: [.black.opacity(0.0), .black, .black.opacity(0.0)], startPoint: .leading, endPoint: .trailing)
                )
                .offset(x: UIScreen.main.bounds.width * start)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                start = 1.5
            }
        }
    }
}

fileprivate extension View {
    func shimmered() -> some View {
        self.overlay(ShimmerView().blendMode(.plusLighter))
    }
}



// MARK: - View
struct MyReservationsView: View {
    @StateObject private var viewModel = MyReservationsViewModel()
    @State private var userId: String? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if userId == nil {
                    ProgressView("Carregando usuário...")
                        .frame(maxHeight: .infinity)
                } else if viewModel.isLoading && viewModel.reservas.isEmpty {
                    // Skeleton loading (First load)
                    loadingSkeletonView
                } else if let error = viewModel.errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error).foregroundColor(.secondary).multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else if viewModel.sections.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.4))
                        Text("Nenhuma reserva encontrada")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.sections) { section in
                            Section(header: Text(section.type.rawValue).font(.headline)) {
                                ForEach(section.items) { group in
                                    if let coworking = group.coworking {
                                        NavigationLink(destination: ReservationGroupDetailView(reservas: group.items, coworking: coworking)) {
                                            CoworkerReservationRow(group: group, coworking: coworking, isHistory: section.type == .history)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        if let userId = userId {
                            await viewModel.carregarReservas(userId: userId)
                        }
                    }
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Todos") { viewModel.statusFilter = nil }
                        Divider()
                        ForEach(CoworkerReservation.ReservationStatus.allCases, id: \.self) { status in
                            Button(status.title) { viewModel.statusFilter = status }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.body)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                            )
                            .foregroundColor(.gray)
                    }
                }
            }


        }
    }
    
    var loadingSkeletonView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<6, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 120)
                        .redacted(reason: .placeholder)
                        .shimmered()
                }
                Spacer().frame(height: 32)
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
    }
}

// MARK: - Subviews
struct CoworkerReservationRow: View {
    let group: MyReservationsViewModel.ReservationGroup
    let coworking: CoworkingInfo
    let isHistory: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: coworking.imagemUrl ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 70, height: 70)
            .cornerRadius(8)
            .clipped()
            .opacity(isHistory ? 0.6 : 1.0)
            .grayscale(isHistory ? 1.0 : 0.0)

            VStack(alignment: .leading, spacing: 4) {
                Text(coworking.name)
                    .font(.headline)
                    .foregroundColor(isHistory ? .gray : .primary)
                
                // Formatted Date from the group (all share same date)
                if let first = group.items.first {
                    Text(first.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Horários e Badges
                // Se houver muitos itens, talvez não caiba tudo, mas vamos listar
                // O usuário pediu "tags". Vamos assumir 1 tag se todos forem iguais, ou listar.
                // Simplificação: Mostrar lista de horas e o status principal (assumindo consistência no grupo ou pegando o mais relevante)
                
                HStack {
                    if let first = group.items.first {
                        statusBadge(for: first)
                    }
                    
                    // Lista de horas
                    Text(group.items.map { $0.hourReservation + "h" }.joined(separator: ", "))
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    func statusBadge(for reservation: CoworkerReservation) -> some View {
        ReservationStatusBadge(status: reservation.statusEnum)
            .grayscale(isHistory && reservation.statusEnum == .refused ? 0.5 : 0.0)
    }
}

struct ReservationGroupDetailView: View {
    let reservas: [CoworkerReservation]
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
                    
                    if let status = reservas.first?.statusEnum {
                        HStack {
                            Text("Status: ")
                            Text(status.title)
                                .fontWeight(.bold)
                                .foregroundColor(colorForStatus(status))
                        }
                    }

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
    
    func colorForStatus(_ status: CoworkerReservation.ReservationStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .confirmed: return .green
        case .canceled: return .red
        case .refused: return .red
        }
    }

    func gerarQRString(reservas: [CoworkerReservation], coworking: CoworkingInfo) -> String? {
        let horas = reservas.map { $0.hourReservation }.joined(separator: ", ")
        return "Espaço: \(coworking.name)\nData: \(reservas.first?.dateReservation ?? "")\nHorários: \(horas)"
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
