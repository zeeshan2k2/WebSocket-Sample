import UIKit

class WebSocketListenerVC: UIViewController {

    @IBOutlet weak var connectBtn: UIButton!
    @IBOutlet weak var disconnectBtn: UIButton!
    @IBOutlet weak var statusTxtView: UITextView!
    @IBOutlet weak var socketConnectionStatusLbl: UILabel!

    private let webSocketManager = WebSocketManager(url: URL(string: "wss://stream.binance.com:9443/ws/btcusdt@trade")!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupWebSocketCallbacks()
    }

    // Setup UI Elements
    func setupUI() {
        connectBtn.tintColor = UIColor(hex: "65C466")
        disconnectBtn.tintColor = UIColor(hex: "FF634F")
        
        statusTxtView.layer.cornerRadius = 15
        statusTxtView.isEditable = false // Prevent user from editing logs
        statusTxtView.text = "WebSocket Logs:\n"
        
        socketConnectionStatusLbl.text = "❌"
    }

    // Connect WebSocket
    @IBAction func connectionBtnClicked(_ sender: Any) {
        webSocketManager.connect()
    }

    // Disconnect WebSocket
    @IBAction func disconnectBtnClicked(_ sender: Any) {
        webSocketManager.disconnect()
    }

    private func setupWebSocketCallbacks() {
        webSocketManager.onStateChange = { [weak self] state in
            self?.handleStateChange(state)
        }

        webSocketManager.onMessage = { [weak self] message in
            self?.appendLog("📩 Price Update: \(message)")
        }

        webSocketManager.onError = { [weak self] message in
            self?.appendLog("🚨 WebSocket Error: \(message)")
        }
    }

    private func handleStateChange(_ state: WebSocketState) {
        switch state {
        case .disconnected:
            appendLog("❌ WebSocket Disconnected")
            socketConnectionStatusLbl.text = "❌"

        case .connecting:
            appendLog("🔄 Connecting to WebSocket...")
            socketConnectionStatusLbl.text = "Connecting"

        case .connected:
            appendLog("✅ WebSocket Connected")
            socketConnectionStatusLbl.text = "✅"

        case .disconnecting:
            appendLog("❌ Disconnecting WebSocket...")
            socketConnectionStatusLbl.text = "Disconnecting"

        case .failed:
            socketConnectionStatusLbl.text = "Status: Error"
        }
    }

    // Append Logs to UITextView Dynamically
    func appendLog(_ log: String) {
        let timestamp = getCurrentTimestamp()
        let logEntry = "[\(timestamp)] \(log)"
        statusTxtView.text.append("\n\(logEntry)")

        // Auto-scroll to bottom
        let range = NSRange(location: statusTxtView.text.count - 1, length: 1)
        statusTxtView.scrollRangeToVisible(range)
    }

    // Get Current Timestamp for Logs
    func getCurrentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}
