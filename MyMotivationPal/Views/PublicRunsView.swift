import SwiftUI

struct PublicRunsView: View {
    @EnvironmentObject var supabaseRealtimeService: SupabaseRealtimeService
    @State private var selectedRunID: UUID?
    @State private var currentUserName: String = "Unknown User" // Default value
    
    var body: some View {
        NavigationView {
            List(supabaseRealtimeService.activeRuns) { run in
                NavigationLink(destination: RunDetailView(runID: run.id, currentUser: currentUserName), tag: run.id, selection: $selectedRunID) {
                    VStack(alignment: .leading) {
                        Text("Run ID: \(run.id.uuidString.prefix(8))...")
                        Text("Started: \(run.start_time)")
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Public Runs")
            .onAppear {
                fetchCurrentUserName() // Fetch the user's name when the view appears
                supabaseRealtimeService.loadActiveRuns()
            }
        }
    }
    
    private func fetchCurrentUserName() {
        Task {
            do {
                //print("Fetching current user...")
                let user = try await supabase.auth.user()
                //print("User fetched: \(user)")

                let response = try await supabase
                    .from("profiles")
                    .select("full_name")
                    .eq("id", value: user.id)
                    .single()
                    .execute()

                //print("Profile response: \(String(data: response.data, encoding: .utf8) ?? "No readable data")")

                if let profile = try? JSONDecoder().decode([String: String].self, from: response.data),
                   let name = profile["full_name"] {
                    DispatchQueue.main.async {
                        self.currentUserName = name
                    }
                    //print("User name fetched: \(name)")
                } else {
                    //print("Failed to decode user's full_name from profile response.")
                }
            } catch {
                //print("Error fetching user or profile: \(error)")
            }
        }
    }

}
