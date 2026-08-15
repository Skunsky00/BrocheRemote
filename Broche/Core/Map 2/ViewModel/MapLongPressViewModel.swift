//
//  MapLongPressViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 11/14/25.
//


import SwiftUI
import MapKit

//struct MapLongPressView<Content: View>: UIViewRepresentable {
//    @Binding var cameraPosition: MapCameraPosition
//    let onLongPress: (CLLocationCoordinate2D) -> Void
//    let content: Content
//
//    init(
//        cameraPosition: Binding<MapCameraPosition>,
//        onLongPress: @escaping (CLLocationCoordinate2D) -> Void,  // ← Fixed typo
//        @ViewBuilder content: () -> Content
//    ) {
//        self._cameraPosition = cameraPosition
//        self.onLongPress = onLongPress
//        self.content = content()
//    }
//
//    func makeUIView(context: Context) -> MKMapView {
//        let mapView = MKMapView()
//        mapView.showsUserLocation = true
//        mapView.delegate = context.coordinator
//
//        let longPress = UILongPressGestureRecognizer(
//            target: context.coordinator,
//            action: #selector(Coordinator.handleLongPress(_:))
//        )
//        longPress.minimumPressDuration = 0.6
//        mapView.addGestureRecognizer(longPress)
//
//        return mapView
//    }
//
//    func updateUIView(_ uiView: MKMapView, context: Context) {
//        context.coordinator.updateCamera(to: cameraPosition, in: uiView)
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(parent: self)
//    }
//
//    class Coordinator: NSObject, MKMapViewDelegate {
//        // ← REMOVE `weak` — struct cannot be weak
//        let parent: MapLongPressView
//        private var lastRegion: MKCoordinateRegion?
//
//        init(parent: MapLongPressView) {
//            self.parent = parent
//        }
//
//        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
//            guard gesture.state == .began else { return }
//            let mapView = gesture.view as! MKMapView
//            let point = gesture.location(in: mapView)
//            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
//            parent.onLongPress(coordinate)
//        }
//
//        func updateCamera(to position: MapCameraPosition, in mapView: MKMapView) {
//            let region = position.regionValue
//            if let region = region {
//                let shouldUpdate = lastRegion?.center.latitude != region.center.latitude ||
//                                  lastRegion?.center.longitude != region.center.longitude ||
//                                  lastRegion?.span.latitudeDelta != region.span.latitudeDelta ||
//                                  lastRegion?.span.longitudeDelta != region.span.longitudeDelta
//
//                if shouldUpdate {
//                    mapView.setRegion(region, animated: true)
//                    lastRegion = region
//                }
//            }
//        }
//
//        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//            let region = mapView.region
//            parent.cameraPosition = .region(region)  // ← Direct access, no weak
//        }
//    }
//}
//
//// MARK: - Safe Region Access (NO PATTERN MATCHING)
//extension MapCameraPosition {
//    var regionValue: MKCoordinateRegion? {
//        let mirror = Mirror(reflecting: self)
//        for child in mirror.children {
//            if let region = child.value as? MKCoordinateRegion {
//                return region
//            }
//        }
//        return nil
//    }
//}
