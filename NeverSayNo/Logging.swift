import Foundation

// Disable all print calls across the app by shadowing the global print function.
// This makes any existing print(...) a no-op at compile time.
func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {}


