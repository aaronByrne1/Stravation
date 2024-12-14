import SwiftUI

@main
struct MyMotivationPalApp: App {
    @StateObject var bleManager = BLEManager()
    @StateObject var heartRateViewModel: HeartRateViewModel

    init() {
        let manager = BLEManager()
        _bleManager = StateObject(wrappedValue: manager)
        _heartRateViewModel = StateObject(wrappedValue: HeartRateViewModel(bleManager: manager))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(bleManager)
                .environmentObject(heartRateViewModel)
        }
    }
}


