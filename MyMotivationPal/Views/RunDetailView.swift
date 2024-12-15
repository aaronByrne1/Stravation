import SwiftUI
import MapKit

struct RunDetailView: View {
    let runID: UUID
    @EnvironmentObject var realtimeService: SupabaseRealtimeService

    @State private var runRoute: [CLLocationCoordinate2D] = []
    @State private var messageText: String = ""
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                                   latitudinalMeters: 500,
                                                   longitudinalMeters: 500)

    var body: some View {
        VStack {
            // Map
            RunningMapView(routeCoordinates: Binding(get: {
                return runRoute
            }, set: { _ in }), focusOnUserLocation: false)

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
                    realtimeService.sendMessage(toRun: runID, sender: "Viewer", message: messageText)
                    messageText = ""
                }
            }
            .padding()
        }
        .onAppear {
            realtimeService.subscribeToMessages(forRunID: runID)
            loadRunRoute()

            Task {
                await realtimeService.subscribeToRunUpdates(runID: runID) { updatedRun in
                    // This closure is called whenever there's a new update for this run
                    let coords = updatedRun.route.map {
                        CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1])
                    }
                    DispatchQueue.main.async {
                        self.runRoute = coords
                        if let first = coords.first {
                            region.center = first
                        }
                    }
                }
            }
        }
        .navigationTitle("Run Details")
    }

    func loadRunRoute() {
        Task {
            do {
                let response = try await supabase
                    .from("runs")
                    .select() // Explicitly select fields
                    .eq("id", value: runID)
                    .single()
                    .execute()

                let decoder = JSONDecoder()
//                decoder.keyDecodingStrategy = .convertFromSnakeCase

                print("Raw response: \(String(data: response.data, encoding: .utf8) ?? "No readable data")")

                // Decode the response directly
                let run = try decoder.decode(Run.self, from: response.data)
                let coords = run.route.map { CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) }
                
                print(coords)

                DispatchQueue.main.async {
                    self.runRoute = coords
                    if let first = coords.first {
                        region.center = first
                    }
                }

                print(self.runRoute)
            } catch {
                print("Error loading run route: \(error)")
            }
        }
    }


}
