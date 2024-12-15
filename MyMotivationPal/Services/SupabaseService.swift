import Supabase
import Combine
import Foundation

class SupabaseRealtimeService: ObservableObject {
    @Published var activeRuns: [Run] = []
    @Published var selectedRunMessages: [RunMessage] = []

    private var dbChangesChannel: RealtimeChannelV2?
    private var dbChangesTask: Task<Void, Never>?

    private var runsTasks: [Task<Void, Never>] = []
    private var messagesTasks: [Task<Void, Never>] = []
    
    init() {
        Task {
            await subscribeToDatabaseChanges()
        }
    }
    
    func loadActiveRuns() {
           print("Loading active runs...")
           Task {
               do {
                   let response = try await supabase
                       .from("runs")
                       .select()
                       //.eq("is_active", value: true) // Uncomment if needed
                       .execute()

                   // Decode directly from response.data
                   do {
                       let decoder = JSONDecoder()
                       let runs = try decoder.decode([Run].self, from: response.data)
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

       // Subscribe to both runs and run_messages via a single channel
       private func subscribeToDatabaseChanges() async {
           print("Subscribing to database changes channel...")
           do {
               let channel = supabase.realtimeV2.channel("db-changes")
               dbChangesChannel = channel

               // Listen for inserts and updates on the runs table
               let runsInsertions = channel.postgresChange(
                   InsertAction.self,
                   schema: "public",
                   table: "runs"
               )

               let runsUpdates = channel.postgresChange(
                   UpdateAction.self,
                   schema: "public",
                   table: "runs"
               )

               // Listen for inserts on the run_messages table
               let messagesInsertions = channel.postgresChange(
                   InsertAction.self,
                   schema: "public",
                   table: "run_messages"
               )

               // Subscribe to the channel after setting up the listeners
               await channel.subscribe()
               print("Subscribed to database changes channel successfully.")

               // Handle all changes in a single task
               dbChangesTask = Task {
                   do {
                       // Handle run inserts
                       for await insertion in runsInsertions {
                           await handleRunInsert(insertion: insertion)
                       }

                       // Handle run updates
                       for await update in runsUpdates {
                           await handleRunUpdate(update: update)
                       }

                       // Handle message inserts
                       for await insertion in messagesInsertions {
                           await handleMessageInsert(insertion: insertion)
                       }
                   } catch {
                       print("Error handling database changes: \(error)")
                   }
               }

           } catch {
               print("Error subscribing to database changes channel: \(error)")
           }
       }

       private func handleRunInsert(insertion: InsertAction) async {
           print("New run inserted!")
           do {
               let decoder = JSONDecoder()

               let newRun = try insertion.decodeRecord(as: Run.self, decoder: decoder)
               DispatchQueue.main.async {
                   self.activeRuns.append(newRun)
               }
               print("New run added: \(newRun)")
           } catch {
               print("Error decoding inserted run: \(error)")
           }
       }

       private func handleRunUpdate(update: UpdateAction) async {
           print("Run updated!")
           do {
               let decoder = JSONDecoder()

               let updatedRun = try update.decodeRecord(as: Run.self, decoder: decoder)
               DispatchQueue.main.async {
                   if let index = self.activeRuns.firstIndex(where: { $0.id == updatedRun.id }) {
                       self.activeRuns[index] = updatedRun
                   } else {
                       self.activeRuns.append(updatedRun)
                   }
               }
               print("Run updated: \(updatedRun)")
           } catch {
               print("Error decoding updated run: \(error)")
           }
       }

       private func handleMessageInsert(insertion: InsertAction) async {
           print("New message inserted!")
           do {
               let decoder = JSONDecoder()

               let newMessage = try insertion.decodeRecord(as: RunMessage.self, decoder: decoder)
               DispatchQueue.main.async {
                   self.selectedRunMessages.append(newMessage)
               }
               print("New message added: \(newMessage)")
           } catch {
               print("Error decoding inserted message: \(error)")
           }
       }

       // Subscribe to run updates for a specific run
       func subscribeToRunUpdates(runID: UUID, onUpdate: @escaping (Run) -> Void) async {
           print("Subscribing to run updates for runID: \(runID)")

           // No need for a separate channel; handle via the single channel
           // Instead, use the existing runsUpdates listener to filter by runID

           // To implement callbacks for specific runID, consider using Combine publishers
           // or other state management techniques to notify interested views.

           // For simplicity, we'll handle it within handleRunUpdate

           // This method can be used to perform additional actions when a specific run is updated
           // For now, no additional implementation is needed since handleRunUpdate already updates activeRuns

           // If you need to perform actions beyond updating activeRuns, consider implementing delegates or notifications
       }

       // Subscribe to messages for a specific run
       func subscribeToMessages(forRunID runID: UUID) async {
           print("SubscribeToMessages is now handled via the single channel.")
           // No separate subscription needed since all messages are handled via the single channel
           // If you need to perform additional actions when a specific run's messages are updated, implement them here
       }

       // Load initial messages from the database
       private func loadMessages(forRunID runID: UUID) {
           print("Loading messages for runID: \(runID)")
           Task {
               do {
                   let response = try await supabase
                       .from("run_messages")
                       .select("id,run_id,sender,message,timestamp")
                       .eq("run_id", value: runID)
                       .order("timestamp", ascending: true)
                       .execute()

                   let decoder = JSONDecoder()
                   print("Raw response: \(String(data: response.data, encoding: .utf8) ?? "No readable data")")

                   // Decode response into an array of RunMessage
                   let messages = try decoder.decode([RunMessage].self, from: response.data)

                   DispatchQueue.main.async {
                       self.selectedRunMessages = messages
                   }

                   print("Messages loaded: \(messages)")
               } catch {
                   print("Error loading messages: \(error)")
               }
           }
       }

       // Send a new message to the run
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

                   print("Message sent successfully.")
               } catch {
                   print("Error sending message: \(error)")
               }
           }
       }
   }
