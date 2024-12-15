import SwiftUI

struct PublicRunsView: View {
    @EnvironmentObject var realtimeService: SupabaseRealtimeService
    @State private var selectedRunID: UUID?

    var body: some View {
        NavigationView {
            List(realtimeService.activeRuns) { run in
                NavigationLink(destination: RunDetailView(runID: run.id), tag: run.id, selection: $selectedRunID) {
                    VStack(alignment: .leading) {
                        Text("Run ID: \(run.id.uuidString.prefix(8))...")
                        Text("Started: \(run.start_time)")
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Public Runs")
            .onAppear {
                realtimeService.loadActiveRuns()
            }
        }
    }
}
