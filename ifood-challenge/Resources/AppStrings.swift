import Foundation

// Catálogo central de textos e valores fixos. Os valores da API e do cache são contratos.
enum AppStrings {
    enum Cache {
        static let response = "characters.response.v1"
        static let listState = "characters.listState.v1"
        static let listPosition = "characters.listPosition.v1"
        static let imageDirectory = "CharacterImages"
        static let hexByteFormat = "%02x"
    }

    enum API {
        static let https = "https"
        static let http = "http"
        static let host = "rickandmortyapi.com"
        static let charactersPath = "/api/character/"
        static let name = "name"
        static let status = "status"
        static let species = "species"
        static let gender = "gender"
        static let alive = "alive"
        static let dead = "dead"
        static let unknown = "unknown"
    }

    enum Text {
        static let characters = "Personagens"
        static let filters = "Filtros"
        static let searchPlaceholder = "Pesquisar personagens..."
        static let emptyResults = "Nenhum personagem encontrado."
        static let openDetails = "Abre os detalhes do personagem"
        static let back = "Voltar"
        static let closeFilters = "Fechar filtros"
        static let applyFilters = "Aplicar filtros"
        static let clearFilters = "Limpar filtros"
        static let id = "ID"
        static let status = "Status"
        static let species = "Espécie"
        static let type = "Tipo"
        static let gender = "Gênero"
        static let origin = "Origem"
        static let location = "Localização"
        static let unspecified = "Não informado"
        static let unknownPlace = "Desconhecida"
        static let any = "Qualquer"
        static let retry = "Tentar novamente"
    }

    enum Symbol {
        static let portrait = "person.crop.square"
        static let next = "chevron.right"
        static let back = "chevron.left"
        static let filters = "slider.horizontal.3"
        static let close = "xmark"
        static let id = "number"
        static let status = "circle.fill"
        static let species = "person.2"
        static let type = "fossil.shell"
        static let gender = "person"
        static let origin = "globe.americas"
        static let location = "mappin.and.ellipse"
    }

    enum Identifier {
        static let characterCell = "CharacterCell"
        static let sceneConfiguration = "Default Configuration"
        static let characterErrorDomain = "CharacterService"
        static let imageErrorDomain = "CharacterImages"
    }

    enum Diagnostic {
        static let characterInitializer = "Use init(character:)"
        static let filtersInitializer = "Use init(filters:)"
        static let cellInitializer = "Use init(style:reuseIdentifier:)"
    }

    enum Message {
        static let offline = "Não foi possível conectar. Verifique sua conexão e tente novamente."
        static let timeout = "A solicitação demorou mais que o esperado. Tente novamente."
        static let serverUnavailable = "O servidor não conseguiu atender à solicitação. Tente novamente em instantes."
        static let invalidResponse = "Não foi possível interpretar a resposta do servidor. Tente novamente."
        static let loadFailure = "Não foi possível carregar os personagens. Tente novamente."
        static func characterHTTPError(_ code: Int) -> String {
            "Não foi possível carregar os personagens (HTTP \(code))."
        }
        static func httpError(_ code: Int) -> String { "HTTP \(code)" }
        static func portrait(_ name: String) -> String { "Foto de \(name)" }
        static func detail(title: String, value: String) -> String { "\(title): \(value)" }
    }

    enum Filters {
        static func title(for group: CharacterFilterGroup) -> String {
            switch group {
            case .status: return AppStrings.Text.status
            case .species: return AppStrings.Text.species
            case .gender: return AppStrings.Text.gender
            }
        }

        static func options(for group: CharacterFilterGroup) -> [CharacterFilterOption] {
            let values: [(String, String)]
            switch group {
            case .status:
                values = [("Vivo", AppStrings.API.alive), ("Morto", AppStrings.API.dead), ("Desconhecido", AppStrings.API.unknown)]
            case .species:
                values = [
                    ("Humano", "Human"), ("Alienígena", "Alien"), ("Humanoide", "Humanoid"),
                    ("Animal", "Animal"), ("Robô", "Robot"), ("Criatura mitológica", "Mythological Creature"),
                    ("Poopybutthole", "Poopybutthole"), ("Cronenberg", "Cronenberg"),
                    ("Doença", "Disease"), (AppStrings.Text.unknownPlace, AppStrings.API.unknown)
                ]
            case .gender:
                values = [("Feminino", "female"), ("Masculino", "male"),
                          ("Sem gênero", "genderless"), ("Desconhecido", AppStrings.API.unknown)]
            }
            return [CharacterFilterOption(title: AppStrings.Text.any, value: nil)] + values.map {
                CharacterFilterOption(title: $0.0, value: $0.1)
            }
        }
    }
}
