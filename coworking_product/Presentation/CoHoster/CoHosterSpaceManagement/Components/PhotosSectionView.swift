import SwiftUI
import PhotosUI

struct PhotosSectionView: View {
    @Binding var pickedItems: [PhotosPickerItem]
    @Binding var photoURLs: [URL]
    let isUploading: Bool
    let onDelete: (URL) -> Void

    var body: some View {
        Section(header: Text("Fotos"), footer: Text("As fotos serão enviadas ao salvar.")) {
            if isUploading {
                ProgressView("Enviando fotos...")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Fotos já enviadas
                    ForEach(photoURLs, id: \.self) { url in
                        ZStack(alignment: .topTrailing) {
                            ThumbnailView(url: url)
                                .frame(width: 120, height: 90)
                                .clipped()
                                .cornerRadius(8)

                            Button(role: .destructive) {
                                onDelete(url)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .red)
                            }
                            .offset(x: 6, y: -6)
                            .tint(.red)
                        }
                    }

                    // Fotos recém-selecionadas
                    ForEach(Array(pickedItems.enumerated()), id: \.offset) { _, item in
                        PickedItemThumbnail(item: item)
                            .frame(width: 120, height: 90)
                            .clipped()
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 4)
            }

            PhotosPicker(selection: $pickedItems, maxSelectionCount: 6, matching: .images) {
                Label("Adicionar fotos", systemImage: "plus")
            }
            .tint(.black)
        }
    }
}

struct ThumbnailView: View {
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

struct PickedItemThumbnail: View {
    let item: PhotosPickerItem
    @State private var image: Image? = nil

    var body: some View {
        ZStack {
            if let image = image {
                image.resizable().scaledToFill()
            } else {
                ProgressView()
            }
        }
        .task(id: item) {
            if let data = try? await item.loadTransferable(type: Data.self),
               let ui = UIImage(data: data) {
                image = Image(uiImage: ui)
            }
        }
    }
}
