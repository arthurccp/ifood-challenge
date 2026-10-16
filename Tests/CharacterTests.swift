import XCTest
@testable import ifood_challenge

final class CharacterTests: XCTestCase {
    @MainActor
    func testErrorMessagesAndRetry() async throws {
        let errors: [(Error, String)] = [
            (URLError(.notConnectedToInternet), AppStrings.Message.offline),
            (URLError(.networkConnectionLost), AppStrings.Message.offline),
            (URLError(.timedOut), AppStrings.Message.timeout),
            (URLError(.badServerResponse), AppStrings.Message.invalidResponse),
            (DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "invalid")), AppStrings.Message.invalidResponse),
            (NSError(domain: AppStrings.Identifier.characterErrorDomain, code: 503), AppStrings.Message.serverUnavailable),
            (NSError(domain: "unknown", code: 1), AppStrings.Message.loadFailure)
        ]
        for (error, expectedMessage) in errors {
            let service = TestCharacterService([.failure(error), .page(TestFixtures.page([1]))])
            let store = TestStateStore()
            let viewModel = CharacterListViewModel(service: service, store: store, debounceNanoseconds: 0)
            viewModel.start()
            try await waitUntil { if case .error = viewModel.state { return true }; return false }
            if case .error(let message) = viewModel.state { XCTAssertTrue(message == expectedMessage) }
            XCTAssertTrue(store.savedStates.isEmpty)
            viewModel.retry()
            viewModel.retry() // A second tap while loading must not issue another request.
            try await waitUntil { if case .success = viewModel.state { return true }; return false }
            XCTAssertTrue(viewModel.characters.first?.id == 1)
            XCTAssertTrue(store.savedStates.count == 1)
            viewModel.retry() // Successful results must not be reloaded by a stale tap.
            let requests = await service.requests
            XCTAssertTrue(requests.count == 2)
        }
    }

    @MainActor
    func testRetryPreservesQueryAndFilters() async throws {
        let filters = CharacterFilters(status: "alive", species: "Human", gender: nil)
        let service = TestCharacterService([.failure(URLError(.timedOut)), .page(TestFixtures.page([]))])
        let store = TestStateStore()
        let viewModel = CharacterListViewModel(service: service, store: store, debounceNanoseconds: 0)
        viewModel.search("Rick")
        viewModel.apply(filters)
        try await waitUntil { if case .error = viewModel.state { return true }; return false }
        viewModel.retry()
        try await waitUntil { if case .empty = viewModel.state { return true }; return false }
        let requests = await service.requests
        XCTAssertTrue(requests.count == 2)
        XCTAssertTrue(requests.allSatisfy { $0.name == "Rick" && $0.filters == filters })
        XCTAssertTrue(store.savedStates.count == 1 && store.savedStates[0].query == "Rick" && store.savedStates[0].filters == filters)
    }

    @MainActor
    func testNewQueryDiscardsCancelledResponse() async throws {
        let racingService = TestCharacterService([.failure(URLError(.timedOut)), .suspended, .page(TestFixtures.page([1]))])
        let racingStore = TestStateStore()
        let racingViewModel = CharacterListViewModel(service: racingService, store: racingStore, debounceNanoseconds: 0)
        racingViewModel.search("old")
        try await waitUntil { if case .error = racingViewModel.state { return true }; return false }
        racingViewModel.retry()
        try await waitUntil { await racingService.requests.count == 2 }
        racingViewModel.search("new")
        try await waitUntil { if case .success = racingViewModel.state { return true }; return false }
        await racingService.resume(with: TestFixtures.page([]))
        for _ in 0..<100 { await Task.yield() }
        XCTAssertTrue(racingViewModel.query == "new" && racingViewModel.characters.count == 1)
        XCTAssertTrue(racingStore.savedStates.count == 1 && racingStore.savedStates[0].query == "new")
    }


    let secondURL = URL(string: "https://rickandmortyapi.com/api/character/?page=2")!
    @MainActor func testPageFailureAndRetry() async throws {
        let first = TestFixtures.page([1, 2], next: secondURL)
        let last = TestFixtures.page([2, 3]) // Overlap must not duplicate a character.
        let service = TestCharacterService([.page(first), .failure(URLError(.timedOut)), .page(last)])
        let store = TestStateStore()
        let vm = CharacterListViewModel(service: service, store: store)
        vm.start()
        try await waitUntil { vm.characters.count == 2 }
        let originalID = try XCTUnwrap(store.state).id
        vm.loadNextPage()
        vm.loadNextPage()
        try await waitUntil { vm.nextPageError != nil }
        XCTAssertTrue(vm.characters.map(\.id) == [1, 2] && !vm.isLoadingNextPage)
        XCTAssertTrue(store.savedStates.count == 1)
        vm.loadNextPage() // Failure requires an explicit retry.
        let failedRequests = await service.requests
        XCTAssertTrue(failedRequests.count == 2)
        vm.retry()
        vm.retry()
        try await waitUntil { vm.characters.count == 3 }
        XCTAssertTrue(vm.characters.map(\.id) == [1, 2, 3])
        XCTAssertTrue(vm.nextPageError == nil && !vm.isLoadingNextPage)
        XCTAssertTrue(store.state?.id == originalID && store.state?.nextPage == nil)
        vm.loadNextPage()
        let requests = await service.requests
        XCTAssertTrue(requests.count == 3 && requests[0].nextPage == nil && requests[1].nextPage == secondURL && requests[2].nextPage == secondURL)
    }

    @MainActor func testRestoresNextPageAndFilters() async throws {
        let first = TestFixtures.page([1, 2], next: secondURL)
        let last = TestFixtures.page([2, 3])
        let restoredStore = TestStateStore()
        restoredStore.state = CharacterListState(characters: first.results, query: "Rick", filters: .init(status: "alive"), nextPage: secondURL)
        let restoredService = TestCharacterService([.page(last)])
        let restored = CharacterListViewModel(service: restoredService, store: restoredStore)
        restored.start()
        restored.loadNextPage()
        try await waitUntil { restored.characters.count == 3 }
        let restoredRequests = await restoredService.requests
        XCTAssertTrue(restoredRequests.count == 1 && restoredRequests[0].name == "Rick" && restoredRequests[0].filters.status == "alive" && restoredRequests[0].nextPage == secondURL)
    }

    @MainActor func testFilterChangeDiscardsPendingPage() async throws {
        let first = TestFixtures.page([1, 2], next: secondURL)
        let last = TestFixtures.page([2, 3])
        let racing = TestCharacterService([.page(first), .suspended, .page(TestFixtures.page([9]))])
        let racingStore = TestStateStore()
        let racingVM = CharacterListViewModel(service: racing, store: racingStore, debounceNanoseconds: 0)
        racingVM.start()
        try await waitUntil { racingVM.characters.count == 2 }
        racingVM.loadNextPage()
        try await waitUntil { await racing.requests.count == 2 }
        racingVM.apply(.init(status: "dead"))
        try await waitUntil { racingVM.characters.first?.id == 9 }
        await racing.resume(with: last)
        for _ in 0..<100 { await Task.yield() }
        XCTAssertTrue(racingVM.characters.map(\.id) == [9] && racingStore.state?.filters.status == "dead")
        let raceRequests = await racing.requests
        XCTAssertTrue(raceRequests[2].nextPage == nil)
    }

    @MainActor func testPersistenceAndLegacyInvalidation() async throws {
        let first = TestFixtures.page([1, 2], next: secondURL)
        let suite = "pagination-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let realStore = CharacterListStateStore(defaults: defaults)
        let state = CharacterListState(characters: first.results, query: "", filters: .init(), nextPage: secondURL)
        realStore.save(state)
        realStore.savePosition(.init(stateID: state.id, characterID: 1, offset: 20))
        realStore.save(CharacterListState(characters: [TestFixtures.character(1), TestFixtures.character(2), TestFixtures.character(3)], query: "", filters: .init(), id: state.id))
        let restoredState = try XCTUnwrap(realStore.load())
        XCTAssertEqual(realStore.position(for: restoredState)?.offset, 20)
        realStore.save(CharacterListState(characters: first.results, query: "new", filters: .init()))
        XCTAssertTrue(defaults.data(forKey: AppStrings.Cache.listPosition) == nil)
        var legacy = try JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as! [String: Any]
        legacy["version"] = 1
        legacy.removeValue(forKey: "nextPage")
        defaults.set(try JSONSerialization.data(withJSONObject: legacy), forKey: AppStrings.Cache.listState)
        XCTAssertTrue(realStore.load() == nil)
    }

    @MainActor func testServicePaginationCacheAndHTTPErrors() async throws {
        let first = TestFixtures.page([1, 2], next: secondURL)
        let last = TestFixtures.page([2, 3])
        let suite = "pagination-service-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        PageURLProtocol.requests = []
        defer { PageURLProtocol.handler = nil; PageURLProtocol.requests = [] }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [PageURLProtocol.self]
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let cache = CodableStore<CharacterPage>(defaults: defaults, key: AppStrings.Cache.response)
        defaults.set(Data("{\"results\":[]}".utf8), forKey: AppStrings.Cache.response)
        let api = CharacterService(cache: cache, session: session)
        PageURLProtocol.handler = { request in
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            let data = try JSONEncoder().encode(components.queryItems?.contains(where: { $0.name == "page" }) == true ? last : first)
            return (200, data)
        }
        let initial = try await api.fetchPage(name: "", filters: .init(), nextPage: nil)
        XCTAssertTrue(initial.info.next == secondURL && PageURLProtocol.requests.count == 1)
        _ = try await api.fetchPage(name: "", filters: .init(), nextPage: nil)
        XCTAssertTrue(PageURLProtocol.requests.count == 1)
        _ = try await api.fetchPage(name: "", filters: .init(), nextPage: secondURL)
        XCTAssertTrue(PageURLProtocol.requests.count == 2)
        let cached = try cache.load()
        XCTAssertTrue(cached?.results.map(\.id) == [1, 2] && cached?.info.next == secondURL)
        _ = try await api.fetchPage(name: "Rick", filters: .init(status: "alive"), nextPage: nil)
        let query = URLComponents(url: PageURLProtocol.requests.last!.url!, resolvingAgainstBaseURL: false)!.queryItems!
        XCTAssertTrue(query.contains(URLQueryItem(name: "name", value: "Rick")) && query.contains(URLQueryItem(name: "status", value: "alive")))
        PageURLProtocol.handler = { _ in (404, Data()) }
        let empty = try await api.fetchPage(name: "none", filters: .init(), nextPage: nil)
        XCTAssertTrue(empty.results.isEmpty && empty.info.next == nil)
        do {
            _ = try await api.fetchPage(name: "Rick", filters: .init(), nextPage: secondURL)
            XCTFail("Next-page 404 must be an error")
        } catch { XCTAssertTrue((error as NSError).code == 404) }
        let count = PageURLProtocol.requests.count
        do {
            _ = try await api.fetchPage(name: "", filters: .init(), nextPage: URL(string: "https://example.com/api/character/?page=2"))
            XCTFail("Foreign URL must be rejected")
        } catch { XCTAssertTrue((error as? URLError)?.code == .badURL) }
        XCTAssertTrue(PageURLProtocol.requests.count == count)
    }
}

// Auxiliares compartilhados pelos oito testes.
private final class TestStateStore: CharacterListStateStoring {
    var state: CharacterListState?
    private(set) var savedStates: [CharacterListState] = []

    func load() -> CharacterListState? { state }
    func save(_ state: CharacterListState) {
        self.state = state
        savedStates.append(state)
    }
    func position(for state: CharacterListState) -> CharacterListPosition? { nil }
    func savePosition(_ position: CharacterListPosition) {}
}

private actor TestCharacterService: CharacterServing {
    enum Outcome {
        case page(CharacterPage)
        case failure(Error)
        case suspended
    }

    private var outcomes: [Outcome]
    private var continuation: CheckedContinuation<CharacterPage, Error>?
    private(set) var requests: [(name: String, filters: CharacterFilters, nextPage: URL?)] = []

    init(_ outcomes: [Outcome]) { self.outcomes = outcomes }

    func fetchPage(name: String, filters: CharacterFilters, nextPage: URL?) async throws -> CharacterPage {
        requests.append((name, filters, nextPage))
        guard !outcomes.isEmpty else {
            XCTFail("Unexpected request")
            throw URLError(.badServerResponse)
        }
        switch outcomes.removeFirst() {
        case .page(let page): return page
        case .failure(let error): throw error
        case .suspended:
            return try await withCheckedThrowingContinuation { continuation = $0 }
        }
    }

    func resume(with page: CharacterPage) {
        continuation?.resume(returning: page)
        continuation = nil
    }
}

private enum TestWaitError: Error { case timeout }

@MainActor
private func waitUntil(file: StaticString = #filePath, line: UInt = #line,
               _ condition: @MainActor () async -> Bool) async throws {
    let deadline = Date().addingTimeInterval(5)
    while !(await condition()) {
        if Date() >= deadline {
            XCTFail("Timed out waiting for state", file: file, line: line)
            throw TestWaitError.timeout
        }
        await Task.yield()
    }
}

private enum TestFixtures {
    static func character(_ id: Int) -> ifood_challenge.Result {
        ifood_challenge.Result(id: id, name: "Rick", status: "Alive", species: "Human", gender: "Male",
                               image: "", type: "", url: "", created: "",
                               origin: .init(name: "Earth", url: ""),
                               location: .init(name: "Earth", url: ""), episode: [])
    }

    static func page(_ ids: [Int], next: URL? = nil) -> CharacterPage {
        CharacterPage(results: ids.map(character), info: .init(next: next))
    }
}

private final class PageURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, Data))!
    static var requests: [URLRequest] = []
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            Self.requests.append(request)
            let (status, data) = try Self.handler(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}

