enum CustomErrors: String, Error {
    case DataError = "Data type error. The provided data does not match the expected format or type."
    case NetworkError = "Network connection error. Please check your connection and try again."
    case DecoderError = "Unable to interpret the received network packet. The data format may be corrupted or unsupported."
    case InvalidAddress = "Invalid IP address. Please enter a valid format (e.g., 192.168.1.1)."
}
