import SwiftUI

struct PublicRunsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Public Runs will appear here in real-time.")
                    .padding()
                
                Text("Users can see HR data, pace, and send messages.")
                    .padding()
            }
            .navigationTitle("Public Runs")
        }
    }
}
