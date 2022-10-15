import gpiod


public func sayHello() -> String {
    return "Hellow World"
}

/**
 Defines the GPIOChip 
 */
public enum GPIOChip: String {
    case gpiochip0 = "gpiochip0"
    case gpiochip1 = "gpiochip1"
    case gpiochip2 = "gpiochip2"
    case gpiochip3 = "gpiochip3"
}

/**
 Board Types currently supported
 */
public enum Board {
    case beagleboneai64
    case beaglebonblack
}

/**
 Direction that pin can be configured for
 */
public enum DigitalGPIODirection: String {
    case IN="in"
    case OUT="out"
}

/**
 The value of the digitial GPIO pins
 */
public enum DigitalGPIOValue: UInt32 {
    case HIGH=1
    case LOW=0
}


/**
 Defines a type to be used when defining the pins.  
 the first value is the line number and the second value is the GPIO Chip
 This information for the HeaderPin will come from the board definition
 */
typealias HeaderPin = (line: UInt32, chip: GPIOChip)

/**
 Protocol that all types designed to access the GPIO pins should conform too
 */
public protocol GPIO {
    mutating func initPin(pinId: String, board: Board) -> Bool
    func isPinActive() -> Bool
}

public extension GPIO {
    func getHeaderPin(_ id: String, board: Board) -> HeaderPin? {
        switch board {
            case .beagleboneai64: 
                return BBAI64DigitalGPIOPins[id]
            case .beaglebonblack:
                return BBBDigitalGPIOPins[id]
        }
    }
}


/**
 The structure used to control the GPIO pins
*/
public struct DigitalGPIO: GPIO {
    private var chipToUse: GPIOChip?
    private var lineNumber: UInt32?
    private var direction: DigitalGPIODirection?
    private var chipHandle: OpaquePointer?
    private var pinHandle: OpaquePointer?

    public init?(pinId: String, board: Board, direction: DigitalGPIODirection) {
        guard initPin(pinId: pinId, board: board) else {
            return nil
        }
        self.direction = direction
        switch direction {
            case .IN:
                gpiod_line_request_input(pinHandle, "pin")
            case .OUT:
                gpiod_line_request_output(pinHandle, "pin", 0)
        }
    }

    public mutating func initPin(pinId: String, board: Board) -> Bool {
        if let headerPin = getHeaderPin(pinId, board: board) {
            chipToUse = headerPin.chip
            lineNumber = headerPin.line
            if let chipHandle = gpiod_chip_open_by_name(headerPin.chip.rawValue) {
                self.chipHandle = chipHandle
                if let pinHandle = gpiod_chip_get_line(chipHandle, headerPin.line) {
                    self.pinHandle = pinHandle
                    return true
                }
            }
        }
        return false
    }

    public func isPinActive() -> Bool {
        guard let _ = chipToUse, let _ = chipHandle else {
            return false
        }
        return true
    }

    public func getValue() -> DigitalGPIOValue? {
        let value = gpiod_line_get_value(pinHandle)
        switch value {
            case 0:
                return .LOW
            case 1:
                return .HIGH
            default:
                return nil
        }
    }

    public func setValue(value: DigitalGPIOValue) -> Bool {
        guard direction == .OUT else {
            return false
        }
        let retVal = gpiod_line_set_value(pinHandle, Int32(value.rawValue))
        if retVal >= 0 {
            return true
        } else {
            return false
        }
    }

    public func release() {
        gpiod_line_release(pinHandle)
        gpiod_chip_close(chipHandle)
    }
}
