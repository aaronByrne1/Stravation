import SwiftUI
import MapKit

struct RunDetailView: View {
    let runID: UUID
    let currentUser: String
    @EnvironmentObject var realtimeService: SupabaseRealtimeService

    @State private var runRoute: [CLLocationCoordinate2D] = []
    @State private var messageText: String = ""
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        latitudinalMeters: 500,
        longitudinalMeters: 500
    )
    @State private var isLoading = true

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading run details...")
                    .padding()
            } else {
                RunningMapView(routeCoordinates: $runRoute, focusOnUserLocation: false)
                    .frame(height: 300)

                List(realtimeService.selectedRunMessages) { msg in
                    VStack(alignment: .leading) {
                        Text(msg.sender)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(msg.message)
                    }
                }

                HStack {
                    TextField("Send a message...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Send") {
                        guard !messageText.isEmpty else { return }
                        realtimeService.sendMessage(toRun: runID, sender: currentUser, message: messageText)
                        messageText = ""
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding()
            }
        }
        .onAppear {
            loadInitialData()
        }
        .navigationTitle("Run Details")
    }

    private func loadInitialData() {
        Task {
            isLoading = true
            await loadRunRoute()
            await loadMessages()
            isLoading = false
        }
    }

    private func loadRunRoute() async {
        do {
            let response = try await supabase
                .from("runs")
                .select("id,user_id,start_time,route,is_active")
                .eq("id", value: runID)
                .single()
                .execute()

            let decoder = JSONDecoder()
            let run = try decoder.decode(Run.self, from: response.data)
            let coords = run.route.map { CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) }

            DispatchQueue.main.async {
                self.runRoute = coords
                if let first = coords.first {
                    region.center = first
                }
            }
            print("Run route loaded successfully.")
        } catch {
            print("Error loading run route: \(error)")
        }
    }

    private func loadMessages() async {
        do {
            let response = try await supabase
                .from("run_messages")
                .select("id,run_id,sender,message,timestamp")
                .eq("run_id", value: runID)
                .order("timestamp", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            let messages = try decoder.decode([RunMessage].self, from: response.data)

            DispatchQueue.main.async {
                self.realtimeService.selectedRunMessages = messages
            }
            print("Messages loaded successfully.")
        } catch {
            print("Error loading messages: \(error)")
        }
    }
}
