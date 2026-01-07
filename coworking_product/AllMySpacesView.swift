import SwiftUI

// MARK: - ViewModel
@MainActor
final class AllMySpacesViewModel: ObservableObject {
    // Estado
    @Published var spaces: [SpaceDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Busca & filtros
    @Published var searchText = ""
    @Published var showOnlyAvailable = false
    @Published var sort: SortOption = .byName

    // UI modais/alerts
    @Published var showAddSpaceForm = false
    @Published var spaceToDelete: SpaceDTO?

    enum SortOption: String, CaseIterable, Identifiable {
        case byName = "Nome"
        case byAvailability = "Disponibilidade"
        var id: String { rawValue }
    }

    // Derivado leve: aplica filtros/ordenacao
    func filteredAndSorted() -> [SpaceDTO] {
        var list = spaces
        if showOnlyAvailable {
            list = list.filter { ($0.availability ?? true) == true }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            list = list.filter { $0.name.lowercased().contains(q) }
        }
        switch sort {
        case .byName:
            list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .byAvailability:
            list.sort { ($0.availability ?? true) && !($1.availability ?? true) }
        }
        return list
    }

    var emptyStateDescription: String {
        if spaces.isEmpty { return "Você ainda não cadastrou espaços. Toque no ícone '+' para criar o primeiro." }
        if !searchText.isEmpty || showOnlyAvailable { return "Tente limpar os filtros ou alterar a busca." }
        return "Sem resultados."
    }

    // MARK: - Ações
    func loadSpaces() {
        guard UserDefaults.standard.bool(forKey: "isHoster") == true else {
            self.errorMessage = "Acesso restrito. Seu cadastro não consta como Hoster."
            return
        }
        guard let userId = UserDefaults.standard.string(forKey: "userId"), !userId.isEmpty else {
            self.errorMessage = "Não foi possível identificar o usuário (userId ausente)."
            return
        }
        isLoading = true
        errorMessage = nil
        APIService.listarEspacosDoHoster(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let list):
                    self.spaces = list
                case .failure(let err):
                    self.errorMessage = err.localizedDescription
                }
            }
        }
    }

    func deleteSpace(_ dto: SpaceDTO) {
        APIService.deletarEspaco(spaceId: dto.spaceId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success:
                    withAnimation { self.spaces.removeAll { $0.spaceId == dto.spaceId } }
                case .failure(let err):
                    self.errorMessage = "Falha ao excluir: \(err.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - View
struct AllMySpacesView: View {
    @StateObject private var vm = AllMySpacesViewModel()
    @State private var navigateToExistingSpaceId: String? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                NavigationLink(isActive: Binding(
                    get: { navigateToExistingSpaceId != nil },
                    set: { if !$0 { navigateToExistingSpaceId = nil } }
                )) {
                    if let id = navigateToExistingSpaceId {
                        CoHosterSpaceManagementView(viewModel: makeSpaceManagementViewModel(spaceId: id, authTokenProvider: { UserDefaults.standard.string(forKey: "authToken") }))
                    } else {
                        EmptyView()
                    }
                } label: {
                    EmptyView()
                }
                .hidden()
                // Top bar (busca + filtro) no estilo CoHosterReservationsView
                SpacesTopBar(vm: vm)
                content
            }
            .navigationTitle("Meus espaços")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // ✅ Somente o botão de adicionar; o botão Back padrão é do sistema
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        vm.showAddSpaceForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Adicionar espaço")
                }
            }
            .refreshable { vm.loadSpaces() }
            .onAppear { if vm.spaces.isEmpty { vm.loadSpaces() } }
            .sheet(isPresented: $vm.showAddSpaceForm, onDismiss: { vm.loadSpaces() }) {
                AddOrEditSpaceFormView(isPresented: $vm.showAddSpaceForm)
            }
            .alert("Excluir espaço?", isPresented: Binding(
                get: { vm.spaceToDelete != nil },
                set: { if !$0 { vm.spaceToDelete = nil } }
            )) {
                Button("Cancelar", role: .cancel) {}
                Button("Excluir", role: .destructive) {
                    if let s = vm.spaceToDelete { vm.deleteSpace(s) }
                }
            } message: { Text("Esta ação não pode ser desfeita.") }
        }
        .tint(.black) // ✅ deixa Back e ícones da barra (incl. "+") pretos
    }

    @ViewBuilder private var content: some View {
        if vm.isLoading && vm.spaces.isEmpty {
            ProgressView("Carregando espaços...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let err = vm.errorMessage {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                Text(err).multilineTextAlignment(.center)
                Button("Tentar novamente", action: vm.loadSpaces)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            let data = vm.filteredAndSorted()
            if data.isEmpty {
                ContentUnavailableView(
                    "Nenhum espaço encontrado",
                    systemImage: "building.2",
                    description: Text(vm.emptyStateDescription)
                )
            } else {
                SpacesList(data: data, onDelete: { vm.spaceToDelete = $0 })
            }
        }
    }
}

// MARK: - Top Bar (busca + filtro/ordenação)
private struct SpacesTopBar: View {
    @ObservedObject var vm: AllMySpacesViewModel

    var body: some View {
        HStack(spacing: 10) {
            // Campo de busca
            HStack {
                Image(systemName: "magnifyingglass").opacity(0.6)
                TextField("Buscar pelo nome", text: $vm.searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                if !vm.searchText.isEmpty {
                    Button { vm.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").opacity(0.5)
                    }
                    .accessibilityLabel("Limpar busca")
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))

            // Menu de filtros/ordenação
            Menu {
                Picker("Ordenar por", selection: $vm.sort) {
                    ForEach(AllMySpacesViewModel.SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                Toggle(isOn: $vm.showOnlyAvailable) {
                    Label("Mostrar apenas disponíveis", systemImage: "checkmark.seal")
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title3)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .bottom)
    }
}

// MARK: - Lista
private struct SpacesList: View {
    let data: [SpaceDTO]
    var onDelete: (SpaceDTO) -> Void

    var body: some View {
        List {
            ForEach(data, id: \.spaceId) { space in
                NavigationLink(destination: {
                    CoHosterSpaceManagementView(viewModel: makeSpaceManagementViewModel(spaceId: space.spaceId, authTokenProvider: { UserDefaults.standard.string(forKey: "authToken") }))
                }) {
                    SpaceRow(space: space)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { onDelete(space) } label: {
                        Label("Excluir", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Subviews
private struct SpaceRow: View {
    let space: SpaceDTO
    var body: some View {
        HStack(spacing: 12) {
            Thumbnail(urlString: space.imagemUrl)
                .frame(width: 64, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(space.name)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    AvailabilityPill(isAvailable: space.availability ?? true)
                    if let city = space.city, !city.isEmpty {
                        Label(city, systemImage: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
            // (Nada aqui — NavigationLink já exibe a seta de disclosure)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 6)
    }
}

private struct AvailabilityPill: View {
    let isAvailable: Bool
    var body: some View {
        Text(isAvailable ? "Disponível" : "Desativado")
            .font(.caption2).bold()
            .foregroundColor(isAvailable ? Color(red: 0, green: 0.6, blue: 0.2) : .gray)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isAvailable ? Color.green.opacity(0.14) : Color.gray.opacity(0.14))
            )
    }
}

private struct Thumbnail: View {
    let urlString: String?
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground))
            if let s = urlString, let url = URL(string: s.trimmingCharacters(in: .whitespacesAndNewlines)) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty: ProgressView()
                    case .success(let image): image.resizable().scaledToFill()
                    case .failure: Image(systemName: "photo").font(.title).foregroundStyle(.secondary)
                    @unknown default: EmptyView()
                    }
                }
            } else {
                Image(systemName: "photo").font(.title).foregroundStyle(.secondary)
            }
        }
    }
}

private struct SpaceDetailPlaceholder: View {
    let name: String
    var body: some View {
        Text("Detalhes do espaço \(name)")
            .navigationTitle(name)
    }
}

// MARK: - Preview
#Preview {
    AllMySpacesView()
}
