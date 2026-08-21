
import Foundation

enum WebSocketState: Equatable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case failed(String)
}

final class WebSocketManager: NSObject, URLSessionWebSocketDelegate {

    var onStateChange: ((WebSocketState) -> Void)?
    var onMessage: ((String) -> Void)?
    var onError: ((String) -> Void)?

    private let url: URL
    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
    private var socket: URLSessionWebSocketTask?
    private(set) var state: WebSocketState = .disconnected {
        didSet {
            guard state != oldValue else { return }

            DispatchQueue.main.async {
                self.onStateChange?(self.state)
            }
        }
    }

    init(url: URL) {
        self.url = url
        super.init()
    }

    func connect() {
        switch state {
        case .connected, .connecting:
            return
        default:
            break
        }

        state = .connecting

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        socket = session.webSocketTask(with: request)
        socket?.resume()
        receive()
    }

    func disconnect() {
        switch state {
        case .disconnected, .disconnecting:
            return

        case .failed:
            socket = nil
            state = .disconnected
            return

        case .connecting, .connected:
            break
        }

        state = .disconnecting
        socket?.cancel(with: .normalClosure, reason: nil)
        socket = nil
        state = .disconnected
    }

    func send(_ text: String) {
        guard case .connected = state else {
            DispatchQueue.main.async {
                self.onError?("WebSocket is not connected.")
            }
            return
        }

        socket?.send(.string(text)) { [weak self] error in
            if let error {
                self?.emitError(error.localizedDescription)
            }
        }
    }

    private func receive() {
        socket?.receive { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(.string(let message)):
                DispatchQueue.main.async {
                    self.onMessage?(message)
                }
                self.receive()

            case .success(.data(let data)):
                DispatchQueue.main.async {
                    self.onMessage?("Received \(data.count) bytes")
                }
                self.receive()

            case .failure(let error):
                if self.state == .disconnecting || self.state == .disconnected {
                    return
                }
                self.emitError(error.localizedDescription)

            @unknown default:
                self.emitError("Unknown WebSocket message.")
            }
        }
    }

    private func emitError(_ message: String) {
        state = .failed(message)
        DispatchQueue.main.async {
            self.onError?(message)
        }
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        state = .connected
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        socket = nil
        state = .disconnected
    }
}
