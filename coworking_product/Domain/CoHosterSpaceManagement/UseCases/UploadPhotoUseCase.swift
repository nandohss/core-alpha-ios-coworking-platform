// Domain/CoHosterSpaceManagement/UseCases/UploadPhotoUseCase.swift
// Protocolo do caso de uso: Upload de foto do espaço

import Foundation

public protocol UploadPhotoUseCase {
    func execute(data: Data, filename: String, spaceId: String) async throws -> URL
}
