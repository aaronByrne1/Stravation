import Foundation
import CoreBluetooth
import Combine

class BLEManager: NSObject, ObservableObject {
    // Publishers
    @Published var discoveredDevices: [DiscoveredDevice] = []
    let heartRatePublisher = PassthroughSubject<Int, Never>()
    
    private let heartRateServiceCBUUID = CBUUID(string: "180D")
    private let heartRateMeasurementCBUUID = CBUUID(string: "2A37")

    private var centralManager: CBCentralManager!
    private var selectedPeripheral: CBPeripheral?

    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        discoveredDevices = []
        centralManager.scanForPeripherals(withServices: [heartRateServiceCBUUID], options: nil)
    }

    func stopScanning() {
        centralManager.stopScan()
    }

    // Call this when the user selects a device from the list
    func selectDevice(_ device: DiscoveredDevice) {
        stopScanning()
        self.selectedPeripheral = device.peripheral
        self.selectedPeripheral?.delegate = self
        centralManager.connect(device.peripheral, options: nil)
    }
    
    func disconnect() {
        if let peripheral = selectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
            selectedPeripheral = nil
        }
    }


    private func updateHeartRate(from characteristic: CBCharacteristic) {
        guard let characteristicData = characteristic.value else { return }
        let byteArray = [UInt8](characteristicData)

        let is16Bit = (byteArray[0] & 0x01) != 0
        let hr: Int
        if is16Bit {
            hr = Int(byteArray[1]) | (Int(byteArray[2]) << 8)
        } else {
            hr = Int(byteArray[1])
        }

        heartRatePublisher.send(hr)
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            // Once powered on, start scanning.
            startScanning()
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        
        // Check if we already have this peripheral in our list
        if !discoveredDevices.contains(where: { $0.peripheral == peripheral }) {
            let deviceName = peripheral.name ?? "Unknown HR Device"
            let device = DiscoveredDevice(peripheral: peripheral, name: deviceName)
            DispatchQueue.main.async {
                self.discoveredDevices.append(device)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([heartRateServiceCBUUID])
    }
}

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == heartRateServiceCBUUID {
                peripheral.discoverCharacteristics([heartRateMeasurementCBUUID], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == heartRateMeasurementCBUUID {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if characteristic.uuid == heartRateMeasurementCBUUID {
            updateHeartRate(from: characteristic)
        }
    }
}
