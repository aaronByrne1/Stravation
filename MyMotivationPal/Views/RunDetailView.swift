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

    var body: some View {
        VStack {
            // Map
            RunningMapView(routeCoordinates: $runRoute, focusOnUserLocation: false)
                .frame(height: 300) // Adjust as needed

            // Messages List
            List(realtimeService.selectedRunMessages) { msg in
                VStack(alignment: .leading) {
                    Text(msg.sender)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(msg.message)
                }
            }

            // Send Message Field
            HStack {
                TextField("Send a message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Send") {
                    guard !messageText.isEmpty else { return }
                    realtimeService.sendMessage(toRun: runID, sender: currentUser, message: messageText)
                    messageText = ""
                }
            }
            .padding()
        }
        .onAppear {
            loadInitialData()
        }
        .navigationTitle("Run Details")
    }

    func loadInitialData() {
        // Load initial route
        loadRunRoute()

        // Load initial messages
        loadMessages()

        // Subscribe to realtime updates
        Task {
            await realtimeService.subscribeToRunUpdates(runID: runID) { updatedRun in
                let coords = updatedRun.route.map {
                    CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1])
                }
                DispatchQueue.main.async {
                    self.runRoute = coords
                    if let first = coords.first {
                        region.center = first
                    }
                }
                print("Run route updated in realtime!")
            }

            // No need to subscribe to messages separately; all messages are handled via the single channel
            await realtimeService.subscribeToMessages(forRunID: runID)
        }
    }

    func loadRunRoute() {
        Task {
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
                print("Run route loaded: \(coords)")
            } catch {
                print("Error loading run route: \(error)")
            }
        }
    }

    func loadMessages() {
        Task {
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
                print("Messages loaded: \(messages)")
            } catch {
                print("Error loading messages: \(error)")
            }
        }
    }
}
