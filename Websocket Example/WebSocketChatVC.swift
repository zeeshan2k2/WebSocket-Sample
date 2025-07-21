import UIKit
import Starscream

class WebSocketChatVC: UIViewController, WebSocketDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var connectBtn: UIButton!
    @IBOutlet weak var disconnectBtn: UIButton!
    @IBOutlet weak var statusTxtView: UITextView!
    @IBOutlet weak var socketConnectionStatusLbl: UILabel!
    @IBOutlet weak var messageTxtField: UITextField!
    @IBOutlet weak var sendMsgBtn: UIButton!
    
    var socket: WebSocket!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        // WebSocket setup
        var request = URLRequest(url: URL(string: "wss://echo.websocket.org")!)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.delegate = self  // Set delegate
    }
    
    func setupUI() {
        connectBtn.tintColor = UIColor(hex: "65C466")
        disconnectBtn.tintColor = UIColor(hex: "FF634F")
        
        statusTxtView.layer.cornerRadius = 15
        statusTxtView.isEditable = false // Prevent user from editing logs
        statusTxtView.text = "WebSocket Logs:\n"
        
        messageTxtField.delegate = self
        
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
    
    // Connect Button Action
    @IBAction func connectBtnClicked(_ sender: Any) {
        appendLog("Connecting to WebSocket...")
        socket.connect()
    }
    
    // Disconnect Button Action
    @IBAction func disconnectBtnClicked(_ sender: Any) {
        appendLog("Disconnecting WebSocket...")
        socket.disconnect()
        sendMsgBtn.isEnabled = false // Disable send button when disconnected
    }
    
    // TextField Editing Started
    @IBAction func messageTxtFieldClicked(_ sender: Any) {
        sendMsgBtn.isEnabled = true // Enable send button when user types
    }
    
    // Send Button Clicked
    @IBAction func sendBtnClicked(_ sender: Any) {
        guard let message = messageTxtField.text, !message.isEmpty else {
            appendLog("Message field is empty.")
            return
        }
        
        appendLog("Sending: \(message)")
        socket.write(string: message) // Send message to WebSocket
        messageTxtField.text = "" // Clear input field
    }
    
    @IBAction func nextScreenBtnClicked(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil) // Replace "Main" with your actual storyboard name
        if let nextVC = storyboard.instantiateViewController(withIdentifier: "WebSocketListenerVC") as? WebSocketListenerVC {
            navigationController?.pushViewController(nextVC, animated: true)
        }
    }

    // MARK: - WebSocketDelegate Methods
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        DispatchQueue.main.async {
            switch event {
            case .connected(_):
                self.appendLog("WebSocket Connected")
                self.sendMsgBtn.isEnabled = true // Enable send button after connection
                self.socketConnectionStatusLbl.text = "✅"
                
            case .disconnected(let reason, let code):
                self.appendLog("WebSocket Disconnected: \(reason) (Code: \(code))")
                self.sendMsgBtn.isEnabled = false // Disable send button when disconnected
                self.socketConnectionStatusLbl.text = "❌"
                
            case .text(let message):
                self.appendLog("Message Received: \(message)")

            case .cancelled:
                self.appendLog("WebSocket Connection Cancelled")
                self.sendMsgBtn.isEnabled = false
                self.socketConnectionStatusLbl.text = "Disconnected"

            case .error(let error):
                self.appendLog("WebSocket Error: \(String(describing: error))")

            default:
                self.appendLog("WebSocket Event Occurred.")
            }
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

