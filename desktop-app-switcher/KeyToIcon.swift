import AppKit

func iconForKeyCode(_ keyCode: Int) -> String {
    switch keyCode {
    // Letter keys
    case 0: return "A"
    case 1: return "S"
    case 2: return "D"
    case 3: return "F"
    case 4: return "H"
    case 5: return "G"
    case 6: return "Z"
    case 7: return "X"
    case 8: return "C"
    case 9: return "V"
    case 11: return "B"
    case 12: return "Q"
    case 13: return "W"
    case 14: return "E"
    case 15: return "R"
    case 16: return "Y"
    case 17: return "T"
    case 31: return "O"
    case 32: return "U"
    case 34: return "I"
    case 35: return "P"
    case 37: return "L"
    case 38: return "J"
    case 40: return "K"
    case 45: return "N"
    case 46: return "M"
    
    // Number keys (top row)
    case 18: return "1"
    case 19: return "2"
    case 20: return "3"
    case 21: return "4"
    case 22: return "5"
    case 23: return "6"
    case 24: return "7"   // Number 7, top row
    case 25: return "8"
    case 26: return "9"
    case 28: return "0"
    
    // Function keys F1-F19
    case 122: return "F1"
    case 120: return "F2"
    case 99:  return "F3"
    case 118: return "F4"
    case 96:  return "F5"
    case 97:  return "F6"
    case 98:  return "F7"
    case 100: return "F8"
    case 101: return "F9"
    case 109: return "F10"
    case 103: return "F11"
    case 111: return "F12"
    case 105: return "F13"
    case 107: return "F14"
    case 113: return "F15"
    case 106: return "F16"
    case 64:  return "F17"
    case 79:  return "F18"
    case 80:  return "F19"
    
    // Arrow keys
    case 123: return "←"
    case 124: return "→"
    case 125: return "↓"
    case 126: return "↑"
    
    // Common keys
    case 36: return "↩"  // Return
    case 48: return "⇥"  // Tab
    case 49: return "␣"  // Space
    case 51: return "⌫"  // Delete (Backspace)
    case 53: return "⎋"  // Escape
    
    // Punctuation and symbols
    case 27: return "-"   // Minus
    case 29: return "="   // Equals, top row
    case 33: return "["   // Open bracket
    case 30: return "]"   // Close bracket
    case 39: return ";"   // Semicolon
    case 41: return "'"   // Quote
    case 43: return "\\"  // Backslash
    case 44: return ","   // Comma
    case 47: return "."   // Period
    case 42: return "/"   // Slash
    case 50: return "`"   // Grave accent (backtick)
    
    // Keypad keys
    case 82: return "0"      // Keypad 0
    case 83: return "1"      // Keypad 1
    case 84: return "2"      // Keypad 2
    case 85: return "3"      // Keypad 3
    case 86: return "4"      // Keypad 4
    case 87: return "5"      // Keypad 5
    case 88: return "6"      // Keypad 6
    case 89: return "7"      // Keypad 7
    case 91: return "8"      // Keypad 8
    case 92: return "9"      // Keypad 9
    case 65: return "*"      // Keypad multiply
    case 67: return "+"      // Keypad plus
    case 78: return "-"      // Keypad minus
    case 75: return "/"      // Keypad divide
    case 81: return "."      // Keypad decimal
    case 71: return "Clear"  // Keypad clear (rare)
    case 117: return "⌦"    // Forward delete (also keypad Del)
    
    // Other special keys
    case 114: return "Help"
    case 115: return "Home"
    case 116: return "PageUp"
    case 119: return "End"
    case 121: return "PageDown"
    
    default:
        return "?"
    }
}

func iconForModifierFlags(_ flags: CGEventFlags) -> String {
    var result = ""
    
    if flags.contains(.maskControl) {
        result += "⌃"
    }
    if flags.contains(.maskAlternate) {
        result += "⌥"
    }
    if flags.contains(.maskShift) {
        result += "⇧"
    }
    if flags.contains(.maskCommand) {
        result += "⌘"
    }
    
    return result
}
