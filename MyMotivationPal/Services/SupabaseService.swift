import Supabase
import Combine
import Foundation
import Realtime
class SupabaseRealtimeService: ObservableObject {
    @Published var activeRuns: [Run] = []
    @Published var selectedRunMessages: [RunMessage] = []

    private var dbChangesChannel: RealtimeChannelV2?
    private var dbChangesTask: Task<Void, Never>?

    init() {
        Task {
            await subscribeToDatabaseChanges()
            loadActiveRuns()
        }
    }

    func loadActiveRuns() {
        Task {
            do {
                let response = try await supabase
                    .from("runs")
                    .select("*")
//                    .eq("is_active", value: true) // Ensure active runs are fetched
                    .execute()

                let decoder = JSONDecoder()
                let runs = try decoder.decode([Run].self, from: response.data)
                DispatchQueue.main.async {
                    self.activeRuns = runs
                }
            } catch {
                print("Error loading active runs: \(error)")
            }
        }
    }

    private func subscribeToDatabaseChanges() async {
        guard dbChangesChannel == nil else { return } // Avoid re-subscribing

        do {
            let channel = supabase.channel("public:all") // Channel for public schema
            dbChangesChannel = channel

            // Listen for changes on `runs` table
            let runsListener = channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "runs"
            )
            
            let runsUpdates = channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "runs"
            )

            // Listen for changes on `run_messages` table
            let messagesListener = channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "run_messages"
            )

            // Subscribe to the channel
            await channel.subscribe()

            // Handle database changes
            dbChangesTask = Task {
                do {
                    for await insertion in runsListener {
                        await handleRunInsert(insertion: insertion)
                    }

                    for await update in runsUpdates {
                        await handleRunUpdate(update: update)
                    }

                    for await message in messagesListener {
                        print("message received")
                        await handleMessageInsert(insertion: message)
                    }
                } catch {
                    print("Error handling realtime database changes: \(error)")
                }
            }
        } catch {
            print("Error subscribing to database changes: \(error)")
        }
    }

    private func handleRunInsert(insertion: InsertAction) async {
        do {
            let decoder = JSONDecoder()
            let newRun = try insertion.decodeRecord(as: Run.self, decoder: decoder)
            DispatchQueue.main.async {
                self.activeRuns.append(newRun)
            }
        } catch {
            print("Error decoding inserted run: \(error)")
        }
    }

    private func handleRunUpdate(update: UpdateAction) async {
        do {
            let decoder = JSONDecoder()
            let updatedRun = try update.decodeRecord(as: Run.self, decoder: decoder)
            DispatchQueue.main.async {
                if let index = self.activeRuns.firstIndex(where: { $0.id == updatedRun.id }) {
                    self.activeRuns[index] = updatedRun
                }
            }
        } catch {
            print("Error decoding updated run: \(error)")
        }
    }

    private func handleMessageInsert(insertion: InsertAction) async {
        do {
            let decoder = JSONDecoder()
            let newMessage = try insertion.decodeRecord(as: RunMessage.self, decoder: decoder)
            DispatchQueue.main.async {
                self.selectedRunMessages.append(newMessage)
            }
        } catch {
            print("Error decoding inserted message: \(error)")
        }
    }
    
    func sendMessage(toRun runID: UUID, sender: String, message: String) {
        Task {
            do {
                let newMessage = [
                    "run_id": runID.uuidString,
                    "sender": sender,
                    "message": message,
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
                try await supabase
                    .from("run_messages")
                    .insert(newMessage)
                    .execute()
                print("Message sent successfully.")
            } catch {
                print("Error sending message: \(error)")
            }
        }
    }

}
