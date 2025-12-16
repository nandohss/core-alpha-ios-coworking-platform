import SwiftUI
import Charts
import Combine

// MARK: - ViewModel de KPI (cálculo real)
final class MySpacesKPIViewModel: ObservableObject {
    @Published private(set) var totalSpaces: Int = 0
    @Published private(set) var availableSpaces: Int = 0
    @Published private(set) var monthlyRevenue: Double = 0
    @Published private(set) var monthlyReservations: Int = 0

    func recompute(spaces: [SpaceDTO], reservations: [ReservationLite] = []) {
        totalSpaces = spaces.count
        availableSpaces = spaces.filter { ($0.availability ?? true) == true }.count

        let cal = Calendar.current
        let now = Date()
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: now))!

        let currentMonth = reservations.filter { $0.date >= startOfMonth && $0.date <= now }
        monthlyReservations = currentMonth.count
        monthlyRevenue = currentMonth.reduce(0) { $0 + $1.totalPrice }
    }

    func occupancyBreakdown(spaces: [SpaceDTO]) -> [(status: String, value: Double)] {
        let free = spaces.filter { ($0.availability ?? true) == true }.count
        let occupied = spaces.count - free
        return [("Ocupado", Double(max(occupied, 0))), ("Livre", Double(max(free, 0)))]
    }

    var revenueBRL: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "BRL"
        f.locale = Locale(identifier: "pt_BR")
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: monthlyRevenue)) ?? "R$ 0"
    }
}

// “Contrato” leve para reservas enquanto você pluga o tipo real
struct ReservationLite {
    let date: Date
    let totalPrice: Double
}

// MARK: - MySpacesView (com Top 2 espaços)
/// Tela principal do hoster com KPIs, atalhos e navegação.
/// A listagem completa continua em `AllMySpacesView`.
struct MySpacesView: View {
    @Binding var selectedTabMain: Int
    @State private var selectedTabLocal = 0
    @State private var showAddSpaceForm = false

    // Reuso de VMs
    @StateObject private var spacesVM = AllMySpacesViewModel()
    @StateObject private var kpiVM = MySpacesKPIViewModel()

    // init explícito p/ evitar erro do @Binding
    init(selectedTabMain: Binding<Int>) {
        self._selectedTabMain = selectedTabMain
    }

    // MARK: - Modelos de UI
    struct Metric: Identifiable {
        let id = UUID()
        let value: String
        let label: String
        let icon: String
        let tint: Color
    }

    struct EarningsEntry: Identifiable {
        let id = UUID()
        let month: String
        let amount: Double
    }

    struct OccupancyEntry: Identifiable {
        let id = UUID()
        let status: String
        let value: Double
    }

    // MARK: - KPIs (agora reais)
    private var metrics: [Metric] {
        [
            .init(value: "\(kpiVM.totalSpaces)",         label: "Espaços",        icon: "square.grid.2x2.fill",  tint: Color(.darkGray)),
            .init(value: "\(kpiVM.availableSpaces)",     label: "Disponíveis",    icon: "checkmark.seal.fill",    tint: Color(red: 0, green: 0.6, blue: 0.2)),
            .init(value: kpiVM.revenueBRL,               label: "Receita mensal", icon: "dollarsign.circle.fill", tint: Color(red: 0, green: 0.6, blue: 0.2)),
            .init(value: "\(kpiVM.monthlyReservations)", label: "Reservas",       icon: "calendar.badge.clock",   tint: .purple)
        ]
    }

    // MARK: - Dados para gráficos
    private var occupancyData: [OccupancyEntry] {
        kpiVM.occupancyBreakdown(spaces: spacesVM.spaces).map {
            .init(status: $0.status, value: $0.value)
        }
    }

    // Mock da Receita (mantido até plugar analytics reais)
    private let earningsData: [EarningsEntry] = [
        .init(month: "Jan", amount: 10000),
        .init(month: "Fev", amount: 23000),
        .init(month: "Mar", amount: 27000),
        .init(month: "Abr", amount: 35000),
        .init(month: "Jun", amount: 30000)
    ]

    // Grid adaptativo — KPIs menores
    private var metricColumns: [GridItem] = [
        .init(.adaptive(minimum: 135), spacing: 10)
    ]

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            ZStack {
                HStack {
                    Button(action: { selectedTabMain = 2 }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
                Text("Meus espaços")
                    .font(.title2).bold()
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(Color(.systemBackground))
            .overlay(Divider(), alignment: .bottom)

            TabView(selection: $selectedTabLocal) {
                // Aba 0
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {

                        // ===== KPIs =====
                        LazyVGrid(columns: metricColumns, spacing: 10) {
                            ForEach(metrics) { metric in
                                MetricCardCenteredSmall(metric: metric)
                            }
                        }
                        .padding(.horizontal, 16)

                        // ===== Gerenciar espaços (Top 2) =====
                        ManageSpacesTopTwo(vm: spacesVM,
                                           onAdd: { showAddSpaceForm = true })
                        .sheet(isPresented: $showAddSpaceForm) {
                            // Seu formulário atual
                            AddOrEditSpaceFormView(isPresented: $showAddSpaceForm)
                        }
                        .padding(.horizontal, 16)

                        // ===== Gráficos =====
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            EarningsChartView(data: earningsData).frame(height: 200)
                            OccupancyChartView(data: occupancyData).frame(height: 200)
                        }
                        .padding(.horizontal, 16)

                        Spacer(minLength: 28)
                    }
                    .padding(.vertical)
                }
                .tag(0)

                // Aba 1: Reservas (CoHoster)
                CoHosterReservationsView()
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            MySpacesTabBar(selectedTab: $selectedTabLocal)
        }
        .edgesIgnoringSafeArea(.bottom)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            if spacesVM.spaces.isEmpty { spacesVM.loadSpaces() }
            kpiVM.recompute(spaces: spacesVM.spaces) // calcula já com os espaços carregados
        }
        .onReceive(spacesVM.$spaces) { new in
            kpiVM.recompute(spaces: new)
        }

    }
}

// MARK: - Seção com Top 2 (usa o VM do pai)
private struct ManageSpacesTopTwo: View {
    @ObservedObject var vm: AllMySpacesViewModel
    var onAdd: (() -> Void)?

    // limites visuais dos cards
    private let maxCardWidth: CGFloat = 180
    private let spacing: CGFloat = 16

    private var topTwo: [SpaceDTO] {
        Array(vm.filteredAndSorted().prefix(2))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header
            HStack {
                Text("Gerenciar espaços")
                    .font(.headline).bold()
                Spacer()
                Button(action: { onAdd?() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Adicionar")
                            .font(.subheadline).fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.systemGray))
                    )
                }
                .buttonStyle(.plain)
            }

            // Conteúdo carregado
            if vm.isLoading && vm.spaces.isEmpty {
                ProgressView().frame(maxWidth: .infinity, alignment: .center)
            } else if let err = vm.errorMessage {
                VStack(spacing: 6) {
                    Text("Erro ao carregar").font(.subheadline).bold()
                    Text(err).font(.caption).foregroundColor(.secondary)
                    Button("Tentar novamente", action: vm.loadSpaces)
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 4)
                }
            } else {
                let items = topTwo

                switch items.count {
                case 0:
                    EmptyView().frame(maxWidth: .infinity)
                case 1:
                    // 1 card centralizado (largura limitada)
                    GeometryReader { geo in
                        let available = geo.size.width
                        let itemWidth = min(maxCardWidth, available)
                        HStack {
                            Spacer(minLength: 0)
                            NavigationLink(destination: CoHosterSpaceManagementView(spaceId: items[0].spaceId)) {
                                SpaceGridCard(space: items[0])
                                    .frame(width: itemWidth)
                            }
                            .buttonStyle(.plain)
                            Spacer(minLength: 0)
                        }
                    }
                    .frame(height: 180 + 60)
                default: // 2+
                    // 2 cards lado a lado, sem estourar
                    GeometryReader { geo in
                        let available = geo.size.width
                        let itemWidth = min(maxCardWidth, (available - spacing) / 2)

                        HStack(spacing: spacing) {
                            ForEach(items.prefix(2), id: \.spaceId) { space in
                                NavigationLink(destination: CoHosterSpaceManagementView(spaceId: space.spaceId)) {
                                    SpaceGridCard(space: space)
                                        .frame(width: itemWidth)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(width: available, alignment: .center)
                    }
                    .frame(height: 180 + 60)
                }
            }

            // “Ver todos” dentro da caixa
            NavigationLink(destination: AllMySpacesView()) {
                HStack(spacing: 6) {
                    Text("Ver todos")
                        .font(.headline).bold()
                        .foregroundColor(Color(.darkGray))
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(.darkGray))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
        .onAppear {
            if vm.spaces.isEmpty { vm.loadSpaces() }
        }
    }
}

// MARK: - Card do Espaço (imagem + nome + status — nome menor, 1 linha)
private struct SpaceGridCard: View {
    let space: SpaceDTO

    private var isAvailable: Bool { space.availability ?? true }
    private var statusText: String { isAvailable ? "Disponível" : "Ocupado" }
    private var statusColor: Color { isAvailable ? Color(red: 0, green: 0.6, blue: 0.2) : .gray }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Imagem
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                if let s = space.imagemUrl,
                   let url = URL(string: s.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty: ProgressView()
                        case .success(let image): image.resizable().scaledToFill()
                        case .failure:
                            Image(systemName: "photo")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                        @unknown default: EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 120)
            .clipped()

            // Nome (1 linha, menor) + Status
            VStack(alignment: .leading, spacing: 4) {
                Text(space.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(.label))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(statusColor)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Subviews (KPIs/Gráficos)

/// KPI centrado — versão menor
struct MetricCardCenteredSmall: View {
    let metric: MySpacesView.Metric
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(metric.tint.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: metric.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(metric.tint)
            }
            Text(metric.value)
                .font(.title3).bold()
                .foregroundColor(.primary)
                .minimumScaleFactor(0.85)
                .lineLimit(1)
                .multilineTextAlignment(.center)
            Text(metric.label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.tertiarySystemFill), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.035), radius: 5, x: 0, y: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metric.label): \(metric.value)")
    }
}

// ===== Receita: verde, R$, sem grade =====
struct EarningsChartView: View {
    let data: [MySpacesView.EarningsEntry]

    private var brlFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "BRL"
        f.locale = Locale(identifier: "pt_BR")
        f.maximumFractionDigits = 0
        return f
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Receita (últimos 6 meses)").font(.headline)

            Chart(data) { (entry: MySpacesView.EarningsEntry) in
                BarMark(
                    x: .value("Mês", entry.month),
                    y: .value("Valor", entry.amount as Double)
                )
                .foregroundStyle(Color(red: 0, green: 0.6, blue: 0.2)) // verde
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(.clear)
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine().foregroundStyle(.clear)
                    AxisTick()
                    if let v = value.as(Double.self),
                       let s = brlFormatter.string(from: NSNumber(value: v)) {
                        AxisValueLabel(s)
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
    }
}

// ===== Ocupação: Ocupado cinza escuro, Livre cinza claro =====
struct OccupancyChartView: View {
    let data: [MySpacesView.OccupancyEntry]
    var body: some View {
        VStack(alignment: .leading) {
            Text("Ocupação").font(.headline)

            Chart(data) { entry in
                SectorMark(
                    angle: .value("Valor", entry.value),
                    innerRadius: .ratio(0.6),
                    angularInset: 1
                )
                .foregroundStyle(by: .value("Status", entry.status))
            }
            .chartForegroundStyleScale([
                "Ocupado": Color(.darkGray),
                "Livre":   Color(.lightGray)
            ])
            .chartLegend(.hidden)
            .overlay(Text(ocupacaoPercentualTexto).font(.title).bold())

            HStack {
                Label("Ocupado", systemImage: "square.fill")
                    .foregroundColor(Color(.darkGray))
                Spacer()
                Label("Livre", systemImage: "square.fill")
                    .foregroundColor(Color(.lightGray))
            }
            .font(.caption)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
    }

    private var ocupacaoPercentualTexto: String {
        let ocupado = data.first { $0.status == "Ocupado" }?.value ?? 0
        let total = data.reduce(0) { $0 + $1.value }
        return total > 0 ? "\(Int((ocupado/total)*100))%" : "0%"
    }
}

// MARK: - Placeholder de Detalhe (caso ainda não tenha a tela real)
private struct SpaceDetailPlaceholder: View {
    let name: String
    var body: some View {
        Text("Detalhes do espaço \(name)")
            .navigationTitle(name)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        MySpacesView(selectedTabMain: .constant(2))
    }
}

// MARK: - Dependências externas referenciadas:
// - AddOrEditSpaceFormView(isPresented:)
// - CoHosterReservationsView()
// - MySpacesTabBar(selectedTab:)
// - AllMySpacesView / AllMySpacesViewModel (já existentes)
// - SpaceDTO (modelo do seu domínio)

