import UIKit

extension UIColor {
    // Convenience initializer for creating UIColor from hexadecimal color codes.
    convenience init(hex: String) {
        // Remove leading and trailing whitespace and newline characters.
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        // Remove the '#' character if it exists.
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        // Scan the hexadecimal string and convert it to an unsigned 64-bit integer.
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        // Extract red, green, and blue components from the hexadecimal value.
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        // Initialize the UIColor instance using the extracted color components.
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
}



