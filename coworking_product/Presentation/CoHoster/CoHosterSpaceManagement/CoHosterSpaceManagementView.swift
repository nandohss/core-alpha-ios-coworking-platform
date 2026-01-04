// Presentation/CoHosterSpaceManagement/Views/CoHosterSpaceManagementView.swift
import SwiftUI
import PhotosUI

struct CoHosterSpaceManagementView: View {
    @StateObject private var vm: CoHosterSpaceManagementViewModel
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case title, priceHour, priceDay, description
    }

    // Injete o ViewModel já pronto (com os casos de uso) na inicialização
    init(viewModel: CoHosterSpaceManagementViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    private var isSuccessAlertPresented: Binding<Bool> {
        Binding(
            get: { vm.successMessage != nil },
            set: { if !$0 { vm.successMessage = nil } }
        )
    }
    private var isErrorAlertPresented: Binding<Bool> {
        Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )
    }

    var body: some View {
        Form {
            statusSection
            basicsSection
            photosSection
            facilitiesSection
            availabilitySection
            rulesSection
        }
        .navigationTitle("Gerenciar espaço")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Salvar") { /* vm.saveAll() */ }
                    .tint(.black)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("OK") { focusedField = nil }
                    .tint(.black)
            }
        }
        .onAppear { Task { await vm.load() } }
        .alert("Sucesso", isPresented: isSuccessAlertPresented) {
            Button("OK", role: .cancel) {}
        } message: { Text(vm.successMessage ?? "") }
        .alert("Atenção", isPresented: isErrorAlertPresented) {
            Button("OK", role: .cancel) {}
        } message: { Text(vm.errorMessage ?? "") }
    }

    // MARK: - Seções de UI

    private var statusSection: some View {
        Section(header: Text("Status e aprovação")) {
            Toggle("Habilitar reservas", isOn: $vm.isEnabledForBookings)
                .tint(.black)
                .onChange(of: vm.isEnabledForBookings) { _ in /* vm.saveFlags() */ }
            Toggle("Aprovação automática", isOn: $vm.autoApproveBookings)
                .tint(.black)
                .onChange(of: vm.autoApproveBookings) { _ in /* vm.saveFlags() */ }
        }
    }

    private var basicsSection: some View {
        Section(header: Text("Dados do espaço")) {
            TextField("Título", text: $vm.title)
                .focused($focusedField, equals: CoHosterSpaceManagementView.Field.title)
            Stepper(value: $vm.capacity, in: 1...200) {
                Text("Capacidade: \(vm.capacity)")
            }
            HStack(alignment: .top, spacing: 12) {
                PriceInputField(label: "Preço por hora", text: $vm.pricePerHourBRL, focus: $focusedField)
                // Se quiser, inclua também preço por dia, se o ViewModel trouxer esse campo
            }
            ZStack(alignment: .topLeading) {
                if vm.descriptionText.isEmpty {
                    Text("Escreva a descrição do espaço aqui...")
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                TextEditor(text: $vm.descriptionText)
                    .focused($focusedField, equals: CoHosterSpaceManagementView.Field.description)
                    .frame(minHeight: 80)
            }
        }
    }

    private var photosSection: some View {
        Section(header: Text("Fotos")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.photoURLs, id: \.self) { url in
                        ThumbnailView(url: url)
                            .frame(width: 120, height: 90)
                            .clipped()
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 4)
            }
            PhotosPicker(selection: .constant([]), maxSelectionCount: 6, matching: .images) {
                Label("Adicionar fotos", systemImage: "plus")
            }
            .tint(.black)
        }
    }

    private var facilitiesSection: some View {
        Section(header: Text("Facilidades")) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(vm.categories.flatMap { $0.facilities }, id: \.id) { facility in
                    let isSelected = vm.selectedFacilities.contains(facility)
                    SelectableTag(title: facility.name, isSelected: isSelected) {
                        if isSelected {
                            vm.selectedFacilities.remove(facility)
                        } else {
                            vm.selectedFacilities.insert(facility)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var availabilitySection: some View {
        Section(header: Text("Disponibilidade")) {
            WeekdaySelector(selected: $vm.selectedWeekdays)
        }
    }

    private var rulesSection: some View {
        Section(header: Text("Regras de reserva")) {
            HStack {
                Stepper(value: $vm.minDurationMinutes, in: 30...480, step: 15) {
                    Text("Duração mínima: \(vm.minDurationMinutes) min").font(.subheadline)
                }
            }
            .scaleEffect(1.06)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: vm.minDurationMinutes)
            HStack {
                Stepper(value: $vm.bufferMinutes, in: 0...240, step: 5) {
                    Text("Intervalo entre reservas: \(vm.bufferMinutes) min").font(.subheadline)
                }
            }
            .scaleEffect(1.06)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: vm.bufferMinutes)
        }
    }
}

// MARK: - Subviews utilitárias

private struct PriceInputField: View {
    let label: String
    @Binding var text: String
    var focus: FocusState<CoHosterSpaceManagementView.Field?>.Binding? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.primary)
            HStack {
                TextField("R$ 0,00", text: $text)
                    .keyboardType(.numberPad)
                    .modifier(ApplyFocusModifier(focus: focus, for: label))
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemGray6))
            )
        }
        .padding(.vertical, 4)
    }
}

private struct ApplyFocusModifier: ViewModifier {
    let focus: FocusState<CoHosterSpaceManagementView.Field?>.Binding?
    let target: CoHosterSpaceManagementView.Field

    init(focus: FocusState<CoHosterSpaceManagementView.Field?>.Binding?, for label: String) {
        self.focus = focus
        if label == "Preço por hora" {
            self.target = CoHosterSpaceManagementView.Field.priceHour
        } else {
            self.target = CoHosterSpaceManagementView.Field.priceDay
        }
    }

    func body(content: Content) -> some View {
        if let focus = focus {
            content.focused(focus, equals: target)
        } else {
            content
        }
    }
}

private struct SelectableTag: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(isSelected ? Color.black : Color(.systemGray5))
                )
                .foregroundColor(isSelected ? .white : .black)
        }
        .buttonStyle(.plain)
    }
}

private struct WeekdaySelector: View {
    @Binding var selected: Set<Int>
    private let weekdays: [(label: String, index: Int)] = [
        ("Seg", 2), ("Ter", 3), ("Qua", 4), ("Qui", 5),
        ("Sex", 6), ("Sáb", 7), ("Dom", 1)
    ]
    private let columns: [GridItem] = [
        GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dias da semana")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
                ForEach(weekdays, id: \.index) { day in
                    let isOn = selected.contains(day.index)
                    SelectableTag(title: day.label, isSelected: isOn) {
                        if isOn {
                            selected.remove(day.index)
                        } else {
                            selected.insert(day.index)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private struct ThumbnailView: View {
    let url: URL
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty: ProgressView()
            case .success(let image): image.resizable().scaledToFill()
            case .failure: Image(systemName: "photo").font(.title)
            @unknown default: EmptyView()
            }
        }
    }
}

