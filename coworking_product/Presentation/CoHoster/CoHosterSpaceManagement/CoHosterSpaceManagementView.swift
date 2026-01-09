// Presentation/CoHosterSpaceManagement/Views/CoHosterSpaceManagementView.swift
import SwiftUI
import PhotosUI

struct CoHosterSpaceManagementView: View {
    @StateObject private var vm: CoHosterSpaceManagementViewModel
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case title, priceHour, priceDay, description, rules
        case companyName, email, ddd, phone
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
            contactSection
            photosSection
            facilitiesSection
            availabilitySection
            rulesSection
        }
        .navigationTitle("Gerenciar espaço")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Salvar") { Task { await vm.saveAll() } }
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
            VStack(alignment: .leading, spacing: 10) {
                Text("Nome do espaço")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("Título", text: $vm.title)
                    .focused($focusedField, equals: CoHosterSpaceManagementView.Field.title)
            }
            .padding(.vertical, 4)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Capacidade")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(vm.capacity)")
                        .font(.title3) // A bit larger for emphasis since it's on its own line
                        .foregroundStyle(.primary)
                        .fontWeight(.semibold)
                }
                Spacer()
                Stepper("", value: $vm.capacity, in: 1...10000)
                    .labelsHidden()
                    .scaleEffect(1.2) // Make buttons larger
            }
            .onChange(of: vm.capacity) { _ in
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
            }
            Toggle(isOn: $vm.isFullDay) {
                Text("Habilitar dia inteiro")
                    .foregroundStyle(.secondary)
            }
            .tint(.black)
            .padding(.vertical, 4)

            HStack(alignment: .top, spacing: 12) {
                if !vm.isFullDay {
                    PriceInputField(label: "Preço por hora", text: $vm.pricePerHourBRL, target: .priceHour, focus: $focusedField)
                }
                PriceInputField(label: "Preço por dia", text: $vm.pricePerDayBRL, target: .priceDay, focus: $focusedField)
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Descrição")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ZStack(alignment: .topLeading) {
                    if vm.descriptionText.isEmpty {
                        Text("Escreva a descrição do espaço aqui...")
                            .foregroundStyle(.secondary)
                            .padding(.top, 12) // Adjusted for padding(8) in editor
                            .padding(.leading, 8)
                    }
                    TextEditor(text: $vm.descriptionText)
                        .scrollContentBackground(.hidden) // Needed for background to show
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .focused($focusedField, equals: CoHosterSpaceManagementView.Field.description)
                }
            }
        }
    }

    private var contactSection: some View {
        Section(header: Text("Contato")) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Razão Social")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("Ex: Minha Empresa LTDA", text: $vm.companyName)
                    .focused($focusedField, equals: .companyName)
            }
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 10) {
                Text("E-mail")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("Ex: contato@exemplo.com", text: $vm.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .focused($focusedField, equals: .email)
            }
            .padding(.vertical, 4)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("DDD")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField("11", text: $vm.ddd)
                        .keyboardType(.numberPad)
                        .frame(width: 50)
                        .focused($focusedField, equals: .ddd)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Telefone")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField("99999-9999", text: $vm.phoneNumber)
                        .keyboardType(.phonePad)
                        .focused($focusedField, equals: .phone)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var photosSection: some View {
        PhotosSectionView(
            pickedItems: $vm.pickedItems,
            photoURLs: $vm.photoURLs,
            isUploading: vm.isUploading,
            onDelete: vm.confirmDeletePhoto
        )
    }

    private var facilitiesSection: some View {
        FacilitiesSectionView(categories: vm.categories, selectedFacilities: $vm.selectedFacilities)
    }

    private var availabilitySection: some View {
            Section(header: Text("Disponibilidade")) {
                WeekdaySelector(selected: $vm.selectedWeekdays)



                if !vm.isFullDay {
                    HStack {
                        Text("Horário de início")
                            .foregroundStyle(.secondary)
                        Spacer()
                        DatePicker("", selection: $vm.startTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    HStack {
                        Text("Horário de fim")
                            .foregroundStyle(.secondary)
                        Spacer()
                        DatePicker("", selection: $vm.endTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                }
            }
    }

    private var rulesSection: some View {
        Section(header: Text("Regras de reserva")) {
            if !vm.isFullDay {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Duração mínima")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatDuration(vm.minDurationMinutes))
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fontWeight(.semibold)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(vm.minDurationMinutes) },
                            set: { vm.minDurationMinutes = Int($0) }
                        ),
                        in: 60...1440,
                        step: 60
                    )
                    .tint(.black)
                    .onChange(of: vm.minDurationMinutes) { _ in
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                    }
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Intervalo entre reservas")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatDuration(vm.bufferMinutes))
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fontWeight(.semibold)
                    }
                    // Escala personalizada: 0, 15, 30, 60, 120, 180, ... 720
                    let bufferValues: [Int] = [0, 15, 30] + Array(stride(from: 60, through: 720, by: 60))
                    Slider(
                        value: Binding(
                            get: {
                                // Encontrar o índice mais próximo do valor atual
                                let val = vm.bufferMinutes
                                if let idx = bufferValues.firstIndex(where: { $0 >= val }) {
                                    return Double(idx)
                                }
                                return Double(bufferValues.count - 1)
                            },
                            set: {
                                // Definir o valor baseado no índice do slider
                                let idx = Int($0)
                                if idx >= 0 && idx < bufferValues.count {
                                    vm.bufferMinutes = bufferValues[idx]
                                }
                            }
                        ),
                        in: 0...Double(bufferValues.count - 1),
                        step: 1
                    )
                    .tint(.black)
                    .onChange(of: vm.bufferMinutes) { _ in
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                    }
                }
                .padding(.vertical, 4)
            }

            // Rules Text
            VStack(alignment: .leading, spacing: 10) {
                Text("Regras do espaço")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                ZStack(alignment: .topLeading) {
                    if vm.rules.isEmpty {
                        Text("Escreva as regras do espaço aqui...")
                            .foregroundStyle(.secondary)
                            .padding(.top, 12)
                            .padding(.leading, 8)
                    }
                    TextEditor(text: $vm.rules)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .focused($focusedField, equals: CoHosterSpaceManagementView.Field.rules)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // Helper para formatar minutos em horas/minutos
    private func formatDuration(_ minutes: Int) -> String {
        if minutes == 0 { return "0 min" }
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return m > 0 ? "\(h) h \(m) min" : "\(h) h"
        } else {
            return "\(m) min"
        }
    }
    }
