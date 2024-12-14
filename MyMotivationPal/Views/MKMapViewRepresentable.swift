import SwiftUI
import MapKit

struct RunningMapView: UIViewRepresentable {
    @Binding var routeCoordinates: [CLLocationCoordinate2D]

    let mapView = MKMapView()

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Update the polyline if routeCoordinates changed
        uiView.removeOverlays(uiView.overlays)

        guard routeCoordinates.count > 1 else { return }
        let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
        uiView.addOverlay(polyline)

        // Adjust the map region if needed
        if let lastCoord = routeCoordinates.last {
            let region = MKCoordinateRegion(center: lastCoord, latitudinalMeters: 500, longitudinalMeters: 500)
            uiView.setRegion(region, animated: true)
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
