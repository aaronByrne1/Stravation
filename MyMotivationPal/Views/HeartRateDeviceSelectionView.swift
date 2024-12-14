import SwiftUI

struct HeartRateDeviceSelectionView: View {
    @ObservedObject var bleManager: BLEManager
    var onDeviceSelected: ((DiscoveredDevice) -> Void)? // Callback after selection

    var body: some View {
        NavigationView {
            List(bleManager.discoveredDevices) { device in
                Button(action: {
                    onDeviceSelected?(device)
                }) {
                    Text(device.name)
                }
            }
            .navigationTitle("Select a HR Device")
        }
    }
}
