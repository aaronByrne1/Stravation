import SwiftUI
import MapKit

struct RunningMapView: UIViewRepresentable {
    @Binding var routeCoordinates: [CLLocationCoordinate2D]
    var focusOnUserLocation: Bool

    let mapView = MKMapView()

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator

        if focusOnUserLocation {
            // Focus on the user's current location
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
        } else {
            // Focus on the runner's route coordinates
            mapView.showsUserLocation = false
            mapView.userTrackingMode = .none
        }

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)

        guard routeCoordinates.count > 1 else { return }
        let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
        uiView.addOverlay(polyline)

        if focusOnUserLocation {
            // If focusing on user's location, rely on user tracking mode
            // which is already set. We don't manually set region here.
        } else {
            // If focusing on runner’s coordinates, adjust the region to fit the route.
            if let lastCoord = routeCoordinates.last {
                let region = MKCoordinateRegion(center: lastCoord, latitudinalMeters: 500, longitudinalMeters: 500)
                uiView.setRegion(region, animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RunningMapView
        init(_ parent: RunningMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}
