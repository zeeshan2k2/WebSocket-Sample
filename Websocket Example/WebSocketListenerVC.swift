import UIKit
import Starscream

class WebSocketListenerVC: UIViewController, WebSocketDelegate {

    @IBOutlet weak var connectBtn: UIButton!
    @IBOutlet weak var disconnectBtn: UIButton!
    @IBOutlet weak var statusTxtView: UITextView!
    @IBOutlet weak var socketConnectionStatusLbl: UILabel!

    var socket: WebSocket!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebSocket()
        setupUI()
    }

    // Setup WebSocket Connection to CoinCap API
    func setupWebSocket() {
        let urlString = "wss://stream.binance.com:9443/ws/btcusdt@trade" // Live crypto price stream
        guard let url = URL(string: urlString) else {
            print("❌ Invalid WebSocket URL")
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.delegate = self
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
        appendLog("🔄 Connecting to WebSocket...")
        socket.connect()
    }

    // Disconnect WebSocket
    @IBAction func disconnectBtnClicked(_ sender: Any) {
        appendLog("❌ Disconnecting WebSocket...")
        socket.disconnect()
    }

    // Handle WebSocket Events
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        DispatchQueue.main.async {
            switch event {
            case .connected(_):
                self.appendLog("✅ WebSocket Connected")
                self.socketConnectionStatusLbl.text = "✅"

            case .disconnected(let reason, let code):
                self.appendLog("❌ WebSocket Disconnected: \(reason) (Code: \(code))")
                self.socketConnectionStatusLbl.text = "❌"

            case .text(let message):
                self.appendLog("📩 Price Update: \(message)")

            case .cancelled:
                self.appendLog("⚠️ WebSocket Connection Cancelled")
                self.socketConnectionStatusLbl.text = "❌"

            case .error(let error):
                self.appendLog("🚨 WebSocket Error: \(String(describing: error))")
                self.socketConnectionStatusLbl.text = "Status: Error"

            default:
                break
            }
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

