import SwiftUI
import CoreLocation

struct MotivatorView: View {
    @EnvironmentObject var bleManager: BLEManager
    @EnvironmentObject var heartRateViewModel: HeartRateViewModel
    @StateObject var runViewModel = RunViewModel()
    @StateObject private var runCoordinator = RunCoordinator()
    private let openAIService = OpenAIService()
    private let elevenLabsService = ElevenLabsService()
    private let audioPlayer = AudioPlayer()

    @State private var selectedDeviceIndex: Int? = nil
    @State private var desiredDistance = ""
    @State private var desiredPace = ""
    @State private var motivationalScript = "Your motivator will start speaking soon!"
    @State private var isRunStarted = false
    @State private var previousScript = ""
    @State private var runTimer: Timer?
    @State private var elapsedTime: TimeInterval = 0.0

    // New: Store the current run's UUID
    @State private var currentRunID: UUID?

    var body: some View {
        NavigationView {
            ZStack {
                // The map in the background
                RunningMapView(routeCoordinates: $runViewModel.routeCoordinates, focusOnUserLocation: true)
                    .edgesIgnoringSafeArea(.all)
                
                // Overlay UI elements
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("HR: \(heartRateViewModel.heartRateData.currentHR) bpm")
                                .bold()
                            Text("Distance: \(String(format: "%.2f", runViewModel.currentDistance)) km")
                            Text("Pace: \(String(format: "%.2f", runViewModel.currentPace)) min/km")
                            Text("Time: \(formattedTime(elapsedTime))")
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                        
                        Spacer()
                    }
                    Spacer()
                    
                    if selectedDeviceIndex == nil {
                        deviceSelectionView
                    } else if !isRunStarted {
                        preRunSetupView
                    } else {
                        postRunView
                    }
                }
                .padding()
            }
            .navigationTitle("Motivator")
            .onChange(of: selectedDeviceIndex) { newValue in
                if let index = newValue {
                    let device = bleManager.discoveredDevices[index]
                    bleManager.selectDevice(device)
                }
            }
            .onAppear {
                runViewModel.requestLocationAuthorization()
            }
        }
    }
    
    var deviceSelectionView: some View {
        VStack(spacing: 20) {
            if bleManager.discoveredDevices.isEmpty {
                Text("Scanning for HR devices...")
                ProgressView()
            } else {
                Picker("Select HR Device", selection: $selectedDeviceIndex) {
                    ForEach(0..<bleManager.discoveredDevices.count, id: \.self) { index in
                        Text(bleManager.discoveredDevices[index].name).tag(Optional(index))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Text("Select a device to connect and view your heart rate.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(8)
    }
    
    var preRunSetupView: some View {
        VStack(spacing: 20) {
            Button(action: {
                bleManager.disconnect()
                selectedDeviceIndex = nil
            }) {
                Text("Disconnect")
                    .bold()
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            TextField("Desired Distance (km)", text: $desiredDistance)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding(.horizontal)
            
            TextField("Desired Pace (min/km)", text: $desiredPace)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding(.horizontal)
            
            Text("We'll use these to motivate you if you're not hitting your target pace!")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 20)
            
            Button(action: beginRun) {
                Text("Begin Run")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(8)
    }
    
    var postRunView: some View {
        VStack(spacing: 20) {
            Text("Motivational Script:")
                .font(.headline)
            Text(motivationalScript)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(8)
            
            Button(action: {
                bleManager.disconnect()
                selectedDeviceIndex = nil
                runViewModel.stopRun()
                isRunStarted = false
                audioPlayer.stop()
                runTimer?.invalidate()
                runTimer = nil
                // Optionally set is_active to false in Supabase if needed
                if let runID = currentRunID {
                    Task {
                        do {
                            try await supabase
                                .from("runs")
                                .update(["is_active": false])
                                .eq("id", value: runID.uuidString)
                                .execute()
                        } catch {
                            print("Error updating run to inactive: \(error)")
                        }
                    }
                }
            }) {
                Text("Stop & Disconnect")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(8)
    }

    func beginRun() {
        guard let _ = Double(desiredDistance), let _ = Double(desiredPace) else { return }
        
        Task {
            do {
                let now = ISO8601DateFormatter().string(from: Date())
                let user = try await supabase.auth.user()
                
                let newRun = NewRun(
                    user_id: user.id,
                    start_time: now,
                    route: [],
                    is_active: true
                )
                
                let response = try await supabase
                    .from("runs")
                    .insert(newRun)
                    .select()
                    .single()
                    .execute()
                
                // Decode response and set currentRunID
                do {
                    let run = try JSONDecoder().decode(Run.self, from: response.data)
                    runCoordinator.startRun(runID: run.id)
                    currentRunID=run.id
                    print("New run created with id: \(run.id)")
                } catch {
                    print("Decoding Error: \(error)")
                }
                
                // Bind route updates to RunCoordinator
                runViewModel.routeUpdateHandler = { coordinates in
                    Task {
                        await runCoordinator.updateRouteInSupabase(coordinates: coordinates)
                    }
                }
                
                // Start the run locally
                isRunStarted = true
                heartRateViewModel.startRun()
                runViewModel.startRun()
                
                // Start a timer for elapsed time
                runTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    if runViewModel.runStarted, let start = runViewModel.runStartTime {
                        elapsedTime = Date().timeIntervalSince(start)
                    }
                }
                
                fetchMotivationalScript()
                
                // Fetch script every 30 seconds
                Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
                    if self.isRunStarted {
                        self.fetchMotivationalScript()
                    }
                }
                
            } catch {
                print("Error inserting run: \(error)")
            }
        }
    }

    @MainActor
    func updateRouteInSupabase(coordinates: [CLLocationCoordinate2D]) async {
        guard let runID = currentRunID else { return }

        // Convert CLLocationCoordinate2D to [[Double]] format
        let routeArray = coordinates.map { [$0.latitude, $0.longitude] }

        do {
            try await supabase
                .from("runs")
                .update(["route": routeArray])
                .eq("id", value: runID.uuidString)
                .execute()

            print("Route updated in Supabase with \(routeArray.count) points.")
        } catch {
            print("Error updating route: \(error)")
        }
    }



    func fetchMotivationalScript() {
        guard let runID = currentRunID else {
            print("No run ID yet. Cannot fetch messages.")
            return // No run ID yet
        }

        Task {
            do {
                let response = try await supabase
                    .from("run_messages")
                    .select("message")
                    .eq("run_id", value: runID.uuidString)
                    .order("timestamp", ascending: false)
                    .limit(5)
                    .execute()

                // Debugging the raw response
                print("Raw response: \(String(data: response.data, encoding: .utf8) ?? "No readable data")")

                var recentMessages = ""
                if let msgs = try? JSONDecoder().decode([[String: String]].self, from: response.data) {
                    let messageTexts = msgs.compactMap { $0["message"] }
                    if messageTexts.isEmpty {
                        print("No recent messages found for run ID: \(runID)")
                        recentMessages = "No messages yet."
                    } else {
                        recentMessages = messageTexts.joined(separator: "\n")
                        print("Recent messages: \(messageTexts)")
                    }
                } else {
                    print("Failed to decode messages from response.")
                    recentMessages = "No messages yet."
                }

                openAIService.generateMotivationalScript(
                    distance: desiredDistance,
                    desiredPace: desiredPace,
                    currentPace: runViewModel.currentPace,
                    heartRate: heartRateViewModel.heartRateData.currentHR,
                    tone: "funny and harsh",
                    previousScript: previousScript,
                    additionalInput: "Recent audience messages: \n\(recentMessages)\n"
                ) { script in
                    DispatchQueue.main.async {
                        if let script = script {
                            self.previousScript = self.motivationalScript
                            self.motivationalScript = script
                            //self.speakScript(script)
                        } else {
                            self.motivationalScript = "No script generated. Keep going!"
                        }
                    }
                }
            } catch {
                print("Error fetching recent messages: \(error)")
            }
        }
    }


    func speakScript(_ script: String) {
        elevenLabsService.generateSpeech(script: script) { audioData in
            guard let audioData = audioData else {
                print("Failed to get audio from Eleven Labs")
                return
            }
            DispatchQueue.main.async {
                self.audioPlayer.playAudioData(audioData)
            }
        }
    }

    func formattedTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
