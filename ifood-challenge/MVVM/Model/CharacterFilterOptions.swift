import Foundation

struct CharacterFilterOption {
    let title: String
    let value: String?
}

enum CharacterFilterGroup: CaseIterable {
    case status, species, gender

    var title: String { AppStrings.Filters.title(for: self) }

    var keyPath: WritableKeyPath<CharacterFilters, String?> {
        switch self {
        case .status: return \.status
        case .species: return \.species
        case .gender: return \.gender
        }
    }

    var options: [CharacterFilterOption] { AppStrings.Filters.options(for: self) }
}
