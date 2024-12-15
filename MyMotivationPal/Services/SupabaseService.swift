import Supabase
import Combine
import Foundation

class SupabaseRealtimeService: ObservableObject {
    @Published var activeRuns: [Run] = []
    @Published var selectedRunMessages: [RunMessage] = []

    private var runsChannel: RealtimeChannelV2?
    private var messagesChannel: RealtimeChannelV2?
    private var runChannel: RealtimeChannelV2?

    private var runsTasks: [Task<Void, Never>] = []
    private var messagesTasks: [Task<Void, Never>] = []
    
    init() {
        Task {
            await subscribeToRuns()
        }
    }
    
    func loadActiveRuns() {
        print("Loading active runs...")
        Task {
            do {
                let response = try await supabase
                    .from("runs")
                    .select()
//                    .eq("is_active", value: true)
                    .execute()
                
                // Decode directly from response.data
                do {
                    let runs = try JSONDecoder().decode([Run].self, from: response.data)
                    DispatchQueue.main.async {
                        self.activeRuns = runs
                    }
                    print("Active runs loaded!")
                    print("Active runs: \(activeRuns)")
                } catch {
                    print("Decoding Error: \(error)")
                }
            } catch {
                print("Error loading active runs: \(error)")
            }
        }
    }

    func subscribeToRunUpdates(runID: UUID, onUpdate: @escaping (Run) -> Void) async {
            // Unsubscribe previous if any
            await runChannel?.unsubscribe()

            // Create a channel specific to this run (you can name it as you wish, it's just an identifier)
            runChannel = await supabase.realtimeV2.channel("public:runs:\(runID)")

            // Listen for updates on the `runs` table
            // NOTE: Ensure that your Realtime configuration on Supabase allows you to filter by eq on id
            let updateTask = Task {
                for await update in runChannel!.postgresChange(UpdateAction.self, schema: "public", table: "runs") {
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        let updatedRun = try update.decodeRecord(as: Run.self, decoder: decoder)
                        
                        // Only apply update if it matches the runID we care about
                        if updatedRun.id == runID {
                            onUpdate(updatedRun)
                        }
                    } catch {
                        print("Error decoding updated run: \(error)")
                    }
                }
            }

            // Subscribe after setting up the listener
            await runChannel?.subscribe()
        }
    
    // Subscribe to runs using Realtime V2
    private func subscribeToRuns() async {
        print("Subscribing to runs channel...")
        do {
            let channel = await supabase.realtimeV2.channel("public:runs")
            runsChannel = channel
            await channel.subscribe()

            // Listen for inserts
            let insertTask = Task {
                for await insertion in channel.postgresChange(InsertAction.self, schema: "public", table: "runs") {
                    await handleRunInsert(insertion: insertion)
                }
            }
            runsTasks.append(insertTask)

            // Listen for updates
            let updateTask = Task {
                for await update in channel.postgresChange(UpdateAction.self, schema:" public", table: "runs") {
                    await handleRunUpdate(update: update)
                }
            }
            runsTasks.append(updateTask)
            
        } catch {
            print("Error subscribing to runs channel: \(error)")
        }
    }

    private func handleRunInsert(insertion: InsertAction) async {
        print("New run inserted!")
        do {
            let decoder = JSONDecoder()
                   decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let newRun = try insertion.decodeRecord(as: Run.self, decoder: decoder)
            DispatchQueue.main.async {
                self.activeRuns.append(newRun)
            }
        } catch {
            print("Error decoding inserted run: \(error)")
        }
    }

    private func handleRunUpdate(update: UpdateAction) async {
        print("Run updated!")
        do {
            let decoder = JSONDecoder()
                   decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let updatedRun = try update.decodeRecord(as: Run.self, decoder: decoder)
            DispatchQueue.main.async {
                if let index = self.activeRuns.firstIndex(where: { $0.id == updatedRun.id }) {
                    self.activeRuns[index] = updatedRun
                } else {
                    self.activeRuns.append(updatedRun)
                }
            }
        } catch {
            print("Error decoding updated run: \(error)")
        }
    }

    func subscribeToMessages(forRunID runID: UUID) {
        print("Subscribing to messages channel...")
        Task {
            await subscribeToMessagesChannel(runID: runID)
        }
    }

    private func subscribeToMessagesChannel(runID: UUID) async {
        print("Subscribing to messages channel... 2")
        // Unsubscribe previous channel if any
        await messagesChannel?.unsubscribe()
        messagesTasks.forEach { $0.cancel() }
        messagesTasks.removeAll()

        do {
            let channel = await supabase.realtimeV2.channel("public:run_messages:\(runID)")
            messagesChannel = channel
            await channel.subscribe()

            // Listen for message inserts
            let insertTask = Task {
                for await insertion in channel.postgresChange(InsertAction.self, schema:"public", table: "run_messages") {
                    await handleMessageInsert(insertion: insertion)
                }
            }
            messagesTasks.append(insertTask)

            loadMessages(forRunID: runID)
        } catch {
            print("Error subscribing to messages channel: \(error)")
        }
    }

    private func handleMessageInsert(insertion: InsertAction) async {
        print("New message inserted!")
        do {
            let decoder = JSONDecoder()
                   decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let newMessage = try insertion.decodeRecord(as: RunMessage.self, decoder: decoder)
            DispatchQueue.main.async {
                self.selectedRunMessages.append(newMessage)
            }
        } catch {
            print("Error decoding inserted message: \(error)")
        }
    }

    private func loadMessages(forRunID runID: UUID) {
        print("Loading messages...")
        Task {
            do {
                let response = try await supabase
                    .from("run_messages")
                    .select()
                    .eq("run_id", value: runID)
                    .order("timestamp", ascending: true)
                    .execute()
                
                if let messages = response.value as? [RunMessage] {
                    DispatchQueue.main.async {
                        self.selectedRunMessages = messages
                    }
                }
            } catch {
                print("Error loading messages: \(error)")
            }
        }
    }

    func sendMessage(toRun runID: UUID, sender: String, message: String) {
        print("Sending message...")
        Task {
            do {
                let newMessage = ["run_id": runID.uuidString,
                                  "sender": sender,
                                  "message": message,
                                  "timestamp": ISO8601DateFormatter().string(from: Date())] as [String: String]

                try await supabase
                    .from("run_messages")
                    .insert(newMessage)
                    .execute()
            } catch {
                print("Error sending message: \(error)")
            }
        }
    }
}
