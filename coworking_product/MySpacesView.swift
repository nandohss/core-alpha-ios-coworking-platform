import SwiftUI
import Charts

struct MySpacesView: View {
    @Binding var selectedTabMain: Int
    @State private var selectedTabLocal = 0
    @State private var showAddSpaceForm = false

    // init explícito p/ evitar erro do @Binding
    init(selectedTabMain: Binding<Int>) {
        self._selectedTabMain = selectedTabMain
    }

    // MARK: - Modelos
    struct Metric: Identifiable {
        let id = UUID()
        let value: String
        let label: String
        let icon: String
        let tint: Color
    }
    struct Space: Identifiable {
        let id = UUID()
        let name: String
        let imageName: String
        let status: Status
        enum Status { case available, occupied }
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

    // MARK: - Dados (pt-BR)
    private let metrics: [Metric] = [
        .init(value: "12",       label: "Espaços",         icon: "square.grid.2x2.fill",  tint: Color(.darkGray)),
        .init(value: "8",        label: "Disponíveis",     icon: "checkmark.seal.fill",    tint: Color(red: 0, green: 0.6, blue: 0.2)),
        .init(value: "R$ 3.200", label: "Receita mensal",  icon: "dollarsign.circle.fill", tint: Color(red: 0, green: 0.6, blue: 0.2)),
        .init(value: "34",       label: "Reservas",        icon: "calendar.badge.clock",   tint: .purple)
    ]
    private let spaces: [Space] = [
        .init(name: "Sala de Conferência", imageName: "room1", status: .available),
        .init(name: "Open Workspace",      imageName: "room2", status: .occupied),
        .init(name: "Sala de Reunião",     imageName: "room3", status: .available)
    ]
    private let earningsData: [EarningsEntry] = [
        .init(month: "Jan", amount: 10000),
        .init(month: "Fev", amount: 23000),
        .init(month: "Mar", amount: 27000),
        .init(month: "Abr", amount: 35000),
        .init(month: "Jun", amount: 30000)
    ]
    // 👉 “Livre” no lugar de “Disponível”
    private let occupancyData: [OccupancyEntry] = [
        .init(status: "Ocupado", value: 50),
        .init(status: "Livre",   value: 50)
    ]

    // Grid adaptativo — KPIs menores
    private var metricColumns: [GridItem] = [
        .init(.adaptive(minimum: 135), spacing: 10)
    ]

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

                        // Gerenciar espaços
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Gerenciar espaços")
                                    .font(.headline).bold()
                                Spacer()
                                Button(action: { showAddSpaceForm = true }) {
                                    Label("Adicionar", systemImage: "plus")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 8)
                                        .background(Color(.darkGray))
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 16)
                            .sheet(isPresented: $showAddSpaceForm) {
                                AddOrEditSpaceFormView(isPresented: $showAddSpaceForm)
                            }

                            // “Ver todos” — somente cor do texto (sem cápsula)
                            NavigationLink(destination: AllSpacesView()) {
                                HStack(spacing: 4) {
                                    Text("Ver todos")
                                        .font(.subheadline).bold()
                                        .foregroundColor(Color(.darkGray))
                                    Image(systemName: "chevron.right")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Color(.darkGray))
                                }
                            }
                            .padding(.horizontal, 16)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(spaces) { space in
                                        SpaceCard(space: space)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                        .padding(.horizontal)

                        // Gráficos
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
    }
}


// MARK: - Subviews

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

struct SpaceCard: View {
    let space: MySpacesView.Space
    var body: some View {
        NavigationLink(destination: Text(space.name)) {
            VStack(alignment: .leading, spacing: 8) {
                Image(space.imageName)
                    .resizable().scaledToFill()
                    .frame(width: 140, height: 100).clipped().cornerRadius(8)
                Text(space.name).font(.headline).foregroundColor(Color(.darkGray))
                Text(statusText).font(.caption2).bold().foregroundColor(statusColor)
            }
            .frame(width: 140)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
    }

    private var statusText: String {
        switch space.status { case .available: return "Disponível" case .occupied: return "Ocupado" }
    }
    private var statusColor: Color {
        switch space.status {
        case .available: return Color(red: 0, green: 0.6, blue: 0.2)
        case .occupied:  return .gray
        }
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

            Chart(data) {
                BarMark(
                    x: .value("Mês", $0.month),
                    y: .value("Valor", $0.amount)
                )
                .foregroundStyle(Color(red: 0, green: 0.6, blue: 0.2)) // verde
            }
            // Sem grid: escondemos linhas de grade
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

struct AllSpacesView: View {
    var body: some View {
        List { Text("Aqui vai a lista completa de espaços cadastrados") }
            .navigationTitle("Todos os espaços")
    }
}

#Preview {
    MySpacesView(selectedTabMain: .constant(2))
}
