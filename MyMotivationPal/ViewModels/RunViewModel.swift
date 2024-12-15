import Foundation
import Combine
import CoreLocation

class RunViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentDistance: Double = 0.0
    @Published var currentPace: Double = 0.0
    @Published var runStarted: Bool = false
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []

    private let locationManager = CLLocationManager()
    private var previousLocation: CLLocation?
    var runStartTime: Date?
    
    var routeUpdateHandler: (([CLLocationCoordinate2D]) -> Void)?


    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocationAuthorization() {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func startRun() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
                locationManager.authorizationStatus == .authorizedAlways else {
            requestLocationAuthorization()
            return
        }

        runStarted = true
        runStartTime = Date()
        currentDistance = 0.0
        currentPace = 0.0
        previousLocation = nil
        routeCoordinates = []
        locationManager.startUpdatingLocation()
    }

    func stopRun() {
        runStarted = false
        locationManager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Handle authorization changes if needed
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard runStarted, let location = locations.last else { return }

        // Only use high-accuracy updates
        if location.horizontalAccuracy < 0 || location.horizontalAccuracy > 20 {
            return
        }

        if let prev = previousLocation {
            let distanceIncrement = location.distance(from: prev)

            // Only count increments > 5m to avoid GPS jitter
            if distanceIncrement > 5 {
                currentDistance += distanceIncrement / 1000.0 // km
                previousLocation = location

                // Update pace
                if let start = runStartTime, currentDistance > 0 {
                    let elapsedTime = Date().timeIntervalSince(start) // seconds
                    let minutes = elapsedTime / 60.0
                    currentPace = minutes / currentDistance
                }

                // Append this coordinate to the route
                routeCoordinates.append(location.coordinate)
                
                routeUpdateHandler?(routeCoordinates)

            }
        } else {
            // First valid location
            previousLocation = location
            routeCoordinates.append(location.coordinate)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //print("Location error: \(error.localizedDescription)")
    }
}
