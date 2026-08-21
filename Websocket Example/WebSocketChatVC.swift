import UIKit

class WebSocketChatVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var connectBtn: UIButton!
    @IBOutlet weak var disconnectBtn: UIButton!
    @IBOutlet weak var statusTxtView: UITextView!
    @IBOutlet weak var socketConnectionStatusLbl: UILabel!
    @IBOutlet weak var messageTxtField: UITextField!
    @IBOutlet weak var sendMsgBtn: UIButton!
    
    private let webSocketManager = WebSocketManager(url: URL(string: "wss://echo.websocket.org")!)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupWebSocketCallbacks()
    }
    
    func setupUI() {
        connectBtn.tintColor = UIColor(hex: "65C466")
        disconnectBtn.tintColor = UIColor(hex: "FF634F")
        
        statusTxtView.layer.cornerRadius = 15
        statusTxtView.isEditable = false // Prevent user from editing logs
        statusTxtView.text = "WebSocket Logs:\n"
        
        messageTxtField.delegate = self
        sendMsgBtn.isEnabled = false
        
        addDoneButtonToKeyboard() // Add Done button to keyboard
    }
    
    // Add Done Button to Keyboard
    func addDoneButtonToKeyboard() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonTapped))
        
        toolbar.setItems([flexibleSpace, doneButton], animated: false)
        messageTxtField.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonTapped() {
        messageTxtField.resignFirstResponder() // Dismiss keyboard
    }

    private func setupWebSocketCallbacks() {
        webSocketManager.onStateChange = { [weak self] state in
            self?.handleStateChange(state)
        }

        webSocketManager.onMessage = { [weak self] message in
            self?.appendLog("Message Received: \(message)")
        }

        webSocketManager.onError = { [weak self] message in
            self?.appendLog("WebSocket Error: \(message)")
        }
    }
    
    // Connect Button Action
    @IBAction func connectBtnClicked(_ sender: Any) {
        webSocketManager.connect()
    }
    
    // Disconnect Button Action
    @IBAction func disconnectBtnClicked(_ sender: Any) {
        webSocketManager.disconnect()
    }
    
    // TextField Editing Started
    @IBAction func messageTxtFieldClicked(_ sender: Any) {
        if case .connected = webSocketManager.state {
            sendMsgBtn.isEnabled = true
        }
    }
    
    // Send Button Clicked
    @IBAction func sendBtnClicked(_ sender: Any) {
        guard let message = messageTxtField.text, !message.isEmpty else {
            appendLog("Message field is empty.")
            return
        }
        
        appendLog("Sending: \(message)")
        webSocketManager.send(message)
        messageTxtField.text = "" // Clear input field
    }
    
    @IBAction func nextScreenBtnClicked(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil) // Replace "Main" with your actual storyboard name
        if let nextVC = storyboard.instantiateViewController(withIdentifier: "WebSocketListenerVC") as? WebSocketListenerVC {
            navigationController?.pushViewController(nextVC, animated: true)
        }
    }

    private func handleStateChange(_ state: WebSocketState) {
        switch state {
        case .disconnected:
            appendLog("WebSocket Disconnected")
            sendMsgBtn.isEnabled = false
            socketConnectionStatusLbl.text = "❌"

        case .connecting:
            appendLog("Connecting to WebSocket...")
            sendMsgBtn.isEnabled = false
            socketConnectionStatusLbl.text = "Connecting"

        case .connected:
            appendLog("WebSocket Connected")
            sendMsgBtn.isEnabled = true
            socketConnectionStatusLbl.text = "✅"

        case .disconnecting:
            appendLog("Disconnecting WebSocket...")
            sendMsgBtn.isEnabled = false
            socketConnectionStatusLbl.text = "Disconnecting"

        case .failed:
            sendMsgBtn.isEnabled = false
            socketConnectionStatusLbl.text = "Disconnected"
        }
    }
    
    // Append logs to the UITextView dynamically with timestamp
    func appendLog(_ log: String) {
        let timestamp = getCurrentTimestamp()
        let logEntry = "[\(timestamp)] \(log)"
        statusTxtView.text.append("\n\(logEntry)")
        
        // Auto-scroll to bottom
        let range = NSRange(location: statusTxtView.text.count - 1, length: 1)
        statusTxtView.scrollRangeToVisible(range)
    }
    
    // Get current timestamp for logs
    func getCurrentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    // Dismiss Keyboard when Return Key is Pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
