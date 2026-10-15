import Foundation

struct CharacterFilters: Codable, Equatable {
    var status: String?
    var species: String?
    var gender: String?

    var isEmpty: Bool { status == nil && species == nil && gender == nil }

    var queryItems: [URLQueryItem] {
        [(AppStrings.API.status, status), (AppStrings.API.species, species), (AppStrings.API.gender, gender)].compactMap { name, value in
            value.map { URLQueryItem(name: name, value: $0) }
        }
    }
}
