import SwiftUI

struct HeartRateView: View {
    @ObservedObject var viewModel: HeartRateViewModel
    var onDisconnect: () -> Void

    var body: some View {
        VStack {
            Text("Current HR: \(viewModel.heartRateData.currentHR)")
            Text("Max HR: \(viewModel.heartRateData.maxHR)")
            Text("Average HR: \(Int(viewModel.heartRateData.averageHR))")
                .padding()

            Button("Disconnect") {
                // This will call the closure provided by the parent,
                // which should handle resetting the view model and
                // showing the device selection view again.
                onDisconnect()
            }
            .padding()
            .foregroundColor(.red)
        }
        .navigationTitle("Heart Rate")
        .navigationBarTitleDisplayMode(.inline)
    }
}
