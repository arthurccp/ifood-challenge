import Foundation

@MainActor
final class CharacterListViewModel {
    enum State {
        case initial
        case loading
        case success
        case empty
        case error(String)
    }

    private(set) var characters: [Result] = []
    private(set) var query = String()
    private(set) var filters = CharacterFilters()
    private(set) var state: State = .initial
    private(set) var listID = UUID()
    private(set) var isLoadingNextPage = false
    private(set) var nextPageError: String?
    private var nextPage: URL?
    private var loadedPageURLs: Set<URL> = []
    var onChange: (() -> Void)?

    private let service: any CharacterServing
    private let store: any CharacterListStateStoring
    private let debounceNanoseconds: UInt64
    private var task: Task<Void, Never>?
    private var requestID = UUID()
    private var completedState: CharacterListState?
    private var restoredPosition: CharacterListPosition?

    // Recebe os serviços de consulta, persistência e o intervalo de debounce.
    init(service: any CharacterServing = CharacterService(),
         store: any CharacterListStateStoring = CharacterListStateStore(),
         debounceNanoseconds: UInt64 = 350_000_000) {
        self.service = service
        self.store = store
        self.debounceNanoseconds = debounceNanoseconds
    }

    // Cancela a consulta pendente ao liberar o ViewModel.
    deinit { task?.cancel() }

    // Restaura a última consulta salva ou inicia o carregamento inicial.
    func start() {
        guard case .initial = state else { return }
        if let saved = store.load() {
            characters = saved.characters
            query = saved.query
            filters = saved.filters
            nextPage = saved.nextPage
            completedState = saved
            restoredPosition = store.position(for: saved)
            state = characters.isEmpty ? .empty : .success
            onChange?()
        } else {
            reload()
        }
    }

    // Normaliza o nome e agenda uma busca quando o texto muda.
    func search(_ text: String) {
        let name = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name != query else { return }
        query = name
        reload(debounce: true)
    }

    // Atualiza os filtros aplicados e recarrega os resultados.
    func apply(_ filters: CharacterFilters) {
        guard filters != self.filters else { return }
        self.filters = filters
        reload()
    }

    // Repete apenas consultas que falharam, mantendo pesquisa e filtros atuais.
    func retry() {
        if nextPageError != nil {
            loadNextPage(retrying: true)
        } else if case .error = state {
            reload()
        }
    }

    private func errorMessage(for error: Error) -> String {
        if error is DecodingError { return AppStrings.Message.invalidResponse }
        if let error = error as? URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost,
                 .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return AppStrings.Message.offline
            case .timedOut:
                return AppStrings.Message.timeout
            case .badServerResponse, .cannotDecodeContentData, .cannotParseResponse:
                return AppStrings.Message.invalidResponse
            default:
                return AppStrings.Message.loadFailure
            }
        }
        let failure = error as NSError
        if failure.domain == AppStrings.Identifier.characterErrorDomain {
            return AppStrings.Message.serverUnavailable
        }
        return AppStrings.Message.loadFailure
    }

    // Entrega a posição restaurada uma única vez.
    func takeRestoredPosition() -> CharacterListPosition? {
        defer { restoredPosition = nil }
        return restoredPosition
    }

    // Persiste a rolagem somente quando ela pertence aos resultados concluídos.
    func savePosition(characterID: Int, offset: Double) {
        guard let saved = completedState, saved.characters.contains(where: { $0.id == characterID }),
              offset.isFinite else { return }
        store.savePosition(CharacterListPosition(stateID: saved.id, characterID: characterID, offset: offset))
    }

    // A rolagem não repete automaticamente uma página que falhou.
    func loadNextPage() {
        loadNextPage(retrying: false)
    }

    private func loadNextPage(retrying: Bool) {
        guard case .success = state, !isLoadingNextPage,
              nextPageError == nil || retrying, let url = nextPage else { return }
        isLoadingNextPage = true
        nextPageError = nil
        fetch(nextPage: url)
    }

    private func reload(debounce: Bool = false) {
        task?.cancel()
        requestID = UUID()
        listID = UUID()
        completedState = nil
        restoredPosition = nil
        nextPage = nil
        loadedPageURLs = []
        nextPageError = nil
        isLoadingNextPage = false
        characters = []
        state = .loading
        fetch(nextPage: nil, delay: debounce ? debounceNanoseconds : 0)
    }

    private func fetch(nextPage pageURL: URL?, delay: UInt64 = 0) {
        let currentID = requestID
        let name = query
        let filters = filters
        onChange?()
        task = Task { [weak self, service] in
            do {
                if delay > 0 { try await Task.sleep(nanoseconds: delay) }
                try Task.checkCancellation()
                let page = try await service.fetchPage(name: name, filters: filters, nextPage: pageURL)
                try Task.checkCancellation()
                guard let self, self.requestID == currentID else { return }
                if let pageURL { self.loadedPageURLs.insert(pageURL) }
                var ids = Set(self.characters.map(\.id))
                self.characters.append(contentsOf: page.results.filter { ids.insert($0.id).inserted })
                self.nextPage = page.info.next.flatMap { self.loadedPageURLs.contains($0) ? nil : $0 }
                self.isLoadingNextPage = false
                let saved = CharacterListState(characters: self.characters, query: name, filters: filters,
                                               nextPage: self.nextPage, id: self.completedState?.id ?? UUID())
                self.completedState = saved
                self.store.save(saved)
                self.state = self.characters.isEmpty ? .empty : .success
                self.onChange?()
            } catch {
                guard !Task.isCancelled, let self, self.requestID == currentID else { return }
                self.isLoadingNextPage = false
                if pageURL != nil {
                    self.nextPageError = self.errorMessage(for: error)
                } else {
                    self.state = .error(self.errorMessage(for: error))
                }
                self.onChange?()
            }
        }
    }
}
