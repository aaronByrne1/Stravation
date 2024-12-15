import Foundation
import CoreLocation

class RunCoordinator: ObservableObject {
    private(set) var currentRunID: UUID?

    func startRun(runID: UUID) {
        currentRunID = runID
    }

    func stopRun() {
        currentRunID = nil
    }

    func updateRouteInSupabase(coordinates: [CLLocationCoordinate2D]) async {
          guard let runID = currentRunID else { return }

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
}
