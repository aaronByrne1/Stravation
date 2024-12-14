import Foundation
import Combine

class HeartRateViewModel: ObservableObject {
    @Published var heartRateData = HeartRateData(currentHR: 0, maxHR: 0, averageHR: 0.0)
    
    private var allHeartRates: [Int] = []
    private var runStartIndex: Int?
    private var cancellables = Set<AnyCancellable>()
    
    init(bleManager: BLEManager) {
        bleManager.heartRatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newHR in
                self?.updateHeartRate(newHR: newHR)
            }
            .store(in: &cancellables)
    }
    
    func startRun() {
        // Mark the point in time we started the run
        runStartIndex = allHeartRates.count
    }
    
    private func updateHeartRate(newHR: Int) {
        allHeartRates.append(newHR)
        heartRateData.currentHR = newHR
        if newHR > heartRateData.maxHR {
            heartRateData.maxHR = newHR
        }
        
        // If run has started, only average from runStartIndex
        let hrSlice: Array<Int>
        if let startIndex = runStartIndex, startIndex < allHeartRates.count {
            hrSlice = Array(allHeartRates[startIndex...])
        } else {
            hrSlice = allHeartRates
        }
        
        heartRateData.averageHR = hrSlice.isEmpty ? 0.0 : Double(hrSlice.reduce(0, +)) / Double(hrSlice.count)
    }
}

