import Foundation
import CoreBluetooth

struct DiscoveredDevice: Identifiable {
    let id = UUID()
    let peripheral: CBPeripheral
    let name: String
}
