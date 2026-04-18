import Foundation
import XCTest
@testable import FloatingChatCore

final class OpenAIServiceTests: XCTestCase {
    override func tearDown() {
        URLProtocolStubStorage.shared.reset()
    }

    func testSendParsesSuccessfulResponse() async throws {
        URLProtocolStubStorage.shared.setHandler { request in
            XCTAssertEqual(request.url, AppConfiguration.chatCompletionsURL)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer sk-test")
            return (
                HTTPURLResponse(url: AppConfiguration.chatCompletionsURL, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                Data("{\"choices\":[{\"message\":{\"content\":\" Hola \"}}]}".utf8)
            )
        }

        let reply = try await OpenAIService.send(
            messages: [ChatMessage(role: "user", content: "Hola")],
            apiKey: " sk-test ",
            model: AppConfiguration.defaultModel,
            session: makeStubSession()
        )

        XCTAssertEqual(reply, "Hola")
    }

    func testSendPropagatesAPIErrorMessage() async {
        URLProtocolStubStorage.shared.setHandler { _ in
            (
                HTTPURLResponse(url: AppConfiguration.chatCompletionsURL, statusCode: 401, httpVersion: nil, headerFields: nil)!,
                Data("{\"error\":{\"message\":\"invalid api key\",\"type\":\"invalid_request_error\"}}".utf8)
            )
        }

        do {
            _ = try await OpenAIService.send(
                messages: [ChatMessage(role: "user", content: "Hola")],
                apiKey: "sk-test",
                model: AppConfiguration.defaultModel,
                session: makeStubSession()
            )
            XCTFail("Se esperaba error")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Error 401: invalid api key [invalid_request_error]")
        }
    }

    func testSendMapsTransportErrors() async {
        URLProtocolStubStorage.shared.setError(URLError(.notConnectedToInternet))

        do {
            _ = try await OpenAIService.send(
                messages: [ChatMessage(role: "user", content: "Hola")],
                apiKey: "sk-test",
                model: AppConfiguration.defaultModel,
                session: makeStubSession()
            )
            XCTFail("Se esperaba error")
        } catch {
            XCTAssertEqual(error.localizedDescription, "No hay conexión a Internet.")
        }
    }

    private func makeStubSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }
}

private final class URLProtocolStub: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        switch URLProtocolStubStorage.shared.outcome() {
        case .success(let handler):
            do {
                let (response, data) = try handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        case .missing:
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
        }
    }

    override func stopLoading() {
    }
}

private final class URLProtocolStubStorage: @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    enum Outcome {
        case success(Handler)
        case failure(Error)
        case missing
    }

    static let shared = URLProtocolStubStorage()

    private let lock = NSLock()
    private var handler: Handler?
    private var error: Error?

    func setHandler(_ handler: @escaping Handler) {
        lock.lock()
        self.handler = handler
        error = nil
        lock.unlock()
    }

    func setError(_ error: Error) {
        lock.lock()
        self.error = error
        handler = nil
        lock.unlock()
    }

    func reset() {
        lock.lock()
        handler = nil
        error = nil
        lock.unlock()
    }

    func outcome() -> Outcome {
        lock.lock()
        defer { lock.unlock() }

        if let error {
            return .failure(error)
        }

        if let handler {
            return .success(handler)
        }

        return .missing
    }
}