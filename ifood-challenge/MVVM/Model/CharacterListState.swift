import Foundation

struct CharacterListState: Codable {
    let version: Int
    let id: UUID
    let characters: [Result]
    let query: String
    let filters: CharacterFilters
    let nextPage: URL?

    init(characters: [Result], query: String, filters: CharacterFilters, nextPage: URL? = nil, id: UUID = UUID()) {
        version = 2
        self.id = id
        self.characters = characters
        self.query = query
        self.filters = filters
        self.nextPage = nextPage
    }
}

struct CharacterListPosition: Codable {
    let stateID: UUID
    let characterID: Int
    let offset: Double
}
