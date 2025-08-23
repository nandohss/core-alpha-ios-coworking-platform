import Foundation
import SwiftUI

struct FormsConstants {
    
    // MARK: - Enum de Categorias com ícone (para UI)
    enum CategoriaPrincipal: String, CaseIterable, Identifiable {
        case escritorio = "Escritório e Negócios"
        case beleza = "Beleza e Estética"
        case saude = "Saúde e Bem‑estar"
        case imagem = "Imagem e Produção"
        case educacao = "Educação e Artes"
        case eventos = "Eventos e Sociais"
        case moda = "Moda e Design"
        case tecnologia = "Tecnologia e Criatividade"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .escritorio: return "briefcase.fill"
            case .beleza: return "scissors"
            case .saude: return "cross.case.fill"
            case .imagem: return "camera.fill"
            case .educacao: return "book.closed.fill"
            case .eventos: return "calendar"
            case .moda: return "eyeglasses"
            case .tecnologia: return "desktopcomputer"
            }
        }
        
        var subcategorias: [String] {
            FormsConstants.categorias[self.rawValue] ?? []
        }
    }

    // MARK: - Subcategorias detalhadas
    static let categorias: [String: [String]] = [
        "Escritório e Negócios": ["Escritório privativo","Sala de reunião","Auditório","Coworking tradicional"],
        "Beleza e Estética": ["Sala de estética","Barbearia","Maquiagem","Massagem"],
        "Saúde e Bem‑estar": ["Psicologia","Fisioterapia","Consultório médico"],
        "Imagem e Produção": ["Estúdio de fotografia","Estúdio de vídeo","Podcast"],
        "Educação e Artes": ["Sala de aula","Sala de dança","Teatro"],
        "Eventos e Sociais": ["Sala para eventos","Rooftop","Espaço gourmet"],
        "Moda e Design": ["Ateliê","Showroom"],
        "Tecnologia e Criatividade": ["Espaço maker","Lab de inovação"]
    ]

    // MARK: - Facilidades gerais
    static let todasFacilidades: [String] = [
        "Wi‑Fi","Ar‑condicionado","Café","Lousa","Projetor","Impressora",
        "Estacionamento","Acessibilidade","Recepção","Armário","Água filtrada",
        "Sala de espera","Som ambiente","Monitor extra","Banheiro privativo"
    ]

    // MARK: - UFs do Brasil
    static let ufs = [
        "AC","AL","AP","AM","BA","CE","DF","ES","GO","MA","MT","MS","MG","PA",
        "PB","PR","PE","PI","RJ","RN","RS","RO","RR","SC","SP","SE","TO"
    ]
}
