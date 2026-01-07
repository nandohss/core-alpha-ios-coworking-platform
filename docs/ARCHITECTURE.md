# Proposta de Organização de Pastas (Clean Architecture)

Esta proposta reorganiza o projeto iOS para aproximá-lo de uma arquitetura limpa, facilitando evolução e testes. Ela não altera código existente, mas serve como guia para futuras migrações.

## Visão Geral

Estruture o app em camadas independentes, separando regras de negócio de detalhes de implementação:

- **Domain**: regras de negócio puras, modelos imutáveis e contratos.
- **Data**: implementações de repositórios, mapeamentos de DTOs e fontes externas (API, cache, persistência).
- **Presentation**: telas SwiftUI, view models, validações de formulário e composição de dependências.
- **Shared/Core**: utilidades e componentes transversais (ex.: loading, validações, extensões).

## Estrutura sugerida

```
coworking_product/
  Domain/
    Entities/
      Reservation.swift
      CoworkingSpace.swift
      UserProfile.swift
    UseCases/
      ReserveSpaceUseCase.swift
      ListSpacesUseCase.swift
      ManageSpacesUseCase.swift
    Repositories/
      SpacesRepository.swift
      ReservationsRepository.swift
      AuthRepository.swift

  Data/
    DTOs/
      ReservationDTO.swift
      SpaceDTO.swift
      UserDTO.swift
    Sources/
      Remote/
        AmplifyAPIService.swift
        AuthService.swift
      Local/
        CacheStore.swift
    Mappers/
      ReservationMapper.swift
      SpaceMapper.swift
    Repositories/
      SpacesRepositoryImpl.swift
      ReservationsRepositoryImpl.swift
      AuthRepositoryImpl.swift

  Presentation/
    Screens/
      Home/
        HomeView.swift
        HomeViewModel.swift
      Reservation/
        ReservaView.swift
        ReservaViewModel.swift
        ReservationSummaryView.swift
      SpacesManagement/
        MySpacesView.swift
        AddOrEditSpaceFormView.swift
    Components/
      Cards/
        CoworkingCardView.swift
      Forms/
        ComponentsFormModular.swift
        Validators.swift
      Feedback/
        LoadingOverlayView.swift
        NotificationView.swift
    Routing/
      AppRouter.swift
      DeepLinks.swift
    DI/
      AppContainer.swift

  Shared/
    Constants/
      FormsConstants.swift
    Helpers/
      DateFormatting.swift
      PriceFormatting.swift
    Extensions/
      Color+Palette.swift
      Date+Formatting.swift
    Resources/
      Assets.xcassets
      Localization/
        Localizable.strings
```

## Princípios de dependência

- **Presentation** depende apenas de `Domain` (contratos + use cases) e de utilidades em `Shared`.
- **Data** depende de `Domain` para conhecer contratos e modelos, nunca o inverso.
- **Domain** não importa módulos externos. Models e use cases devem ser puros.

## Migração gradual sugerida

1. **Mapear modelos**: criar entidades em `Domain/Entities` a partir de `Coworking.swift`, `ReservationModel.swift` etc.; mover validações genéricas para `Shared`.
2. **Criar contratos**: definir protocolos de repositório em `Domain/Repositories` a partir de `APIService.swift` e necessidades das telas.
3. **Extrair use cases**: encapsular cenários como reserva, listagem e gestão de espaços em `UseCases` consumindo os repositórios.
4. **Isolar dados**: mover integrações Amplify para `Data/Sources/Remote` e mapear DTOs → entidades em `Mappers`.
5. **Apresentação**: reorganizar as telas atuais em subpastas de recursos (Home, Reservation, SpacesManagement), adotando view models por feature.
6. **Composição**: adicionar um contêiner de dependências (`AppContainer`) para injetar implementações de repositórios e use cases nas view models.

## Boas práticas adicionais

- **Nomenclatura**: use sufixos `View`, `ViewModel`, `UseCase`, `Repository` e `DTO` de forma consistente.
- **Testes**: priorize testes de use cases com repositórios fakes, e testes de mapeamento para DTOs.
- **Modularização futura**: considere targets separados (Domain, Data, Presentation) quando a árvore estiver estável para compilar mais rápido e aumentar o isolamento.
- **Recursos**: mantenha assets e strings em `Shared/Resources` com nomes de catálogo semânticos.

Siga essa organização de forma incremental para evitar regressões, migrando feature por feature.
