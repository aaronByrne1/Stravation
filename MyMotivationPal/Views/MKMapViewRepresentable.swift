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
        // Remove existing overlays
        uiView.removeOverlays(uiView.overlays)

        guard routeCoordinates.count > 1 else { return }
        let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
        uiView.addOverlay(polyline)

        if !focusOnUserLocation {
            // Adjust the map region to fit the entire route
            var mapRect = MKMapRect.null
            for coord in routeCoordinates {
                let point = MKMapPoint(coord)
                mapRect = mapRect.union(MKMapRect(x: point.x, y: point.y, width: 0, height: 0))
            }

            let edgePadding = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
            uiView.setVisibleMapRect(mapRect, edgePadding: edgePadding, animated: true)
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
