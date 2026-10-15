import Foundation

protocol CharacterListStateStoring {
    // Recupera o estado salvo
    func load() -> CharacterListState?
    // Salva a consulta concluída
    func save(_ state: CharacterListState)
    // Recupera uma posição válida vinculada ao estado informado.
    func position(for state: CharacterListState) -> CharacterListPosition?
    // Salva a posição da rolagem
    func savePosition(_ position: CharacterListPosition)
}

struct CharacterListStateStore: CharacterListStateStoring {
    private let stateStore: CodableStore<CharacterListState>
    private let positionStore: CodableStore<CharacterListPosition>

    init(defaults: UserDefaults = .standard) {
        stateStore = CodableStore(defaults: defaults, key: AppStrings.Cache.listState)
        positionStore = CodableStore(defaults: defaults, key: AppStrings.Cache.listPosition)
    }

    // Recupera o estado salvo e descarta dados inválidos ou incompatíveis.
    func load() -> CharacterListState? {
        do {
            guard let state = try stateStore.load() else { return nil }
            guard state.version == 2 else {
                stateStore.remove()
                positionStore.remove()
                return nil
            }
            return state
        } catch {
            stateStore.remove()
            positionStore.remove()
            return nil
        }
    }

    func save(_ state: CharacterListState) {
        let previousID = (try? stateStore.load())?.id
        guard stateStore.save(state) else { return }
        // Acrescentar páginas mantém a identidade da consulta e a posição salva.
        if previousID != state.id { positionStore.remove() }
    }

    func position(for state: CharacterListState) -> CharacterListPosition? {
        guard let position = try? positionStore.load(),
              position.stateID == state.id, position.offset.isFinite,
              state.characters.contains(where: { $0.id == position.characterID }) else { return nil }
        return position
    }

    func savePosition(_ position: CharacterListPosition) {
        guard position.offset.isFinite else { return }
        positionStore.save(position)
    }
}
