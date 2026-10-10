//
//  ShareViewModel.swift
//  BrocheShare
//
//  Created by Jacob Johnson on 10/9/26.
//

// ShareViewModel.swift  (BrocheShare target ONLY)
import Foundation
import Combine
import CoreLocation
import MapKit
import FirebaseAuth
import FirebaseFirestore

struct FoundPlace {
    var name: String
    var subtitle: String
    var latitude: Double?
    var longitude: Double?
    var locationId: String?   // the pin the backend created or matched
    var result: String        // "created", "linkAdded", "alreadyLinked", "visited"
}

@MainActor
final class ShareViewModel: ObservableObject {

    enum Stage { case loading, working, found, searching, notFound, signedOut, done }

    @Published var stage: Stage = .loading
    @Published var place: FoundPlace?
    @Published var message: String = ""
    @Published var doneMessage: String = "Added to your map"
    @Published var query: String = ""
    @Published var results: [MKMapItem] = []
    @Published var busy: Bool = false

    private var url: URL?
    private var uid: String?
    private var sourceKey = "other"
    private var sourceName = "link"
    private var link: String?          // normalized reel link
    private var pendingRef: DocumentReference?
    private var listener: ListenerRegistration?
    private var timeoutTask: Task<Void, Never>?
    private let group = "5K8U9AH5WN.com.brochetravel.broche.shared"

    init() {}

    // MARK: - Text shown on the found card

    var foundNote: String? {
        switch place?.result {
        case "linkAdded": return "Already on your map. We added this reel to it."
        case "alreadyLinked": return "This reel is already saved on that pin."
        case "visited": return "You've already visited this place."
        default: return nil
        }
    }

    var confirmTitle: String {
        (place?.result ?? "created") == "created" ? "Looks good" : "Got it"
    }

    private func doneText() -> String {
        let name = place?.name ?? "this place"
        switch place?.result {
        case "linkAdded": return "Added this reel to \(name)"
        case "alreadyLinked": return "Already saved on your map"
        case "visited": return "You've already been to \(name)"
        default: return "Added to your map"
        }
    }

    // MARK: - Start

    /// Called once the shared link has been read
    func begin(url: URL?, caption: String?) async {
        self.url = url
        if let url { configureSource(for: url) }
        stage = .working

        guard let uid = await currentUid() else {
            stage = .signedOut
            return
        }
        self.uid = uid

        guard let url else {
            message = "Couldn't read the link that was shared."
            stage = .notFound
            return
        }

        let data: [String: Any] = [
            "sourceURL": url.absoluteString,
            "caption": caption ?? "",
            "source": sourceKey,
            "status": "processing",
            "createdAt": FieldValue.serverTimestamp()
        ]

        do {
            let ref = try await Firestore.firestore()
                .collection("users").document(uid)
                .collection("pendingPins").addDocument(data: data)
            pendingRef = ref
            listen(to: ref)
            startTimeout()
        } catch {
            message = error.localizedDescription
            stage = .notFound
        }
    }

    private func configureSource(for url: URL) {
        let host = url.host ?? ""
        sourceKey = host.contains("tiktok") ? "tiktok" : host.contains("instagram") ? "instagram" : "other"
        sourceName = sourceKey == "tiktok" ? "TikTok" : sourceKey == "instagram" ? "Instagram" : "link"
        link = normalizedLink(url)
    }

    // MARK: - Watching the Cloud Function

    private func listen(to ref: DocumentReference) {
        listener = ref.addSnapshotListener { [weak self] snap, _ in
            guard let data = snap?.data() else { return }
            Task { @MainActor in self?.handle(data) }
        }
    }

    private func handle(_ data: [String: Any]) {
        guard stage == .working else { return }
        switch data["status"] as? String {
        case "saved":
            let city = data["city"] as? String
            let country = data["country"] as? String
            if let normalized = data["linkUrl"] as? String { link = normalized }
            place = FoundPlace(
                name: data["placeName"] as? String ?? "This place",
                subtitle: [city, country].compactMap { $0 }.joined(separator: ", "),
                latitude: data["latitude"] as? Double,
                longitude: data["longitude"] as? Double,
                locationId: data["locationId"] as? String,
                result: data["result"] as? String ?? "created"
            )
            timeoutTask?.cancel()
            stage = .found
        case "failed":
            timeoutTask?.cancel()
            message = "Couldn't find the location in that post."
            stage = .notFound
        default:
            break
        }
    }

    private func startTimeout() {
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 25_000_000_000)
            guard let self, !Task.isCancelled else { return }
            if self.stage == .working {
                self.message = "This is taking longer than usual."
                self.stage = .notFound
            }
        }
    }

    // MARK: - User actions

    /// "Looks good" / "Got it"
    func confirm() {
        complete(doneText())
    }

    /// "Wrong place?"
    func startSearch() {
        message = "Search for the right place."
        stage = .searching
    }

    func search() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        MKLocalSearch(request: request).start { [weak self] response, _ in
            let items = response?.mapItems ?? []
            Task { @MainActor in self?.results = items }
        }
    }

    /// Picks a search result. Checks visited and future pins first so nothing is duplicated,
    /// and undoes whatever the backend did for the wrong guess.
    func choose(_ item: MKMapItem) async {
        guard let uid, !busy else { return }
        busy = true

        let fs = Firestore.firestore()
        let futureCol = fs.collection("futureLocations").document(uid).collection("user-locations")
        let visitedCol = fs.collection("locations").document(uid).collection("user-locations")

        let pm = item.placemark
        let target = CLLocation(latitude: pm.coordinate.latitude, longitude: pm.coordinate.longitude)
        let isBroad = pm.thoroughfare == nil && pm.subThoroughfare == nil && item.pointOfInterestCategory == nil
        let radius: CLLocationDistance = isBroad ? 1000 : 150
        let chosenName = item.name ?? pm.name ?? "this place"

        do {
            // 1) Already visited: don't create a future pin
            if let visited = await closest(in: visitedCol, to: target, within: radius) {
                await undoPrevious(in: futureCol)
                let name = (visited.data()["description"] as? String) ?? chosenName
                await markPending(placeName: name)
                complete("You've already been to \(name)")
                return
            }

            // 2) Already a future pin: add this reel to it
            if let existing = await closest(in: futureCol, to: target, within: radius) {
                if existing.documentID != place?.locationId {
                    await undoPrevious(in: futureCol)
                }
                try await addLinkIfNeeded(to: existing)
                let name = (existing.data()["description"] as? String) ?? chosenName
                await markPending(placeName: name)
                complete("Added this reel to \(name)")
                return
            }

            // 3) New pin
            await undoPrevious(in: futureCol)
            let isUS = pm.isoCountryCode == "US"
            let doc = futureCol.document()
            var data: [String: Any] = [
                "id": doc.documentID,
                "ownerUid": uid,
                "latitude": pm.coordinate.latitude,
                "longitude": pm.coordinate.longitude,
                "city": orNull(pm.locality),
                "description": chosenName,
                "date": NSNull(),
                "createdAt": FieldValue.serverTimestamp(),
                "state": isUS ? (pm.administrativeArea ?? "").lowercased() : NSNull(),
                "country": orNull(pm.country),
                "countryCode": orNull(pm.isoCountryCode),
                "continent": NSNull()
            ]
            if let link {
                data["link"] = link
                data["linkTitle"] = "From \(sourceName)"
                data["links"] = [linkDict(link)]
            }
            try await doc.setData(data)
            await markPending(placeName: chosenName)
            complete("Added to your map")
        } catch {
            message = error.localizedDescription
            busy = false
        }
    }

    func finish() {
        listener?.remove()
        listener = nil
        timeoutTask?.cancel()
    }

    private func complete(_ text: String) {
        finish()
        doneMessage = text
        stage = .done
    }

    // MARK: - Firestore helpers

    /// Closest existing pin within `radius` meters
    private func closest(in col: CollectionReference,
                         to target: CLLocation,
                         within radius: CLLocationDistance) async -> QueryDocumentSnapshot? {
        guard let snap = try? await col.getDocuments() else { return nil }
        var best: QueryDocumentSnapshot?
        var bestDist = CLLocationDistance.greatestFiniteMagnitude
        for d in snap.documents {
            let data = d.data()
            guard let lat = data["latitude"] as? Double,
                  let lng = data["longitude"] as? Double else { continue }
            let dist = target.distance(from: CLLocation(latitude: lat, longitude: lng))
            if dist <= radius && dist < bestDist {
                best = d
                bestDist = dist
            }
        }
        return best
    }

    private func linkDict(_ url: String) -> [String: Any] {
        [
            "url": url,
            "title": "From \(sourceName)",
            "source": sourceKey,
            "addedAt": Timestamp(date: Date())
        ]
    }

    private func addLinkIfNeeded(to existing: QueryDocumentSnapshot) async throws {
        guard let link else { return }
        let data = existing.data()
        let links = data["links"] as? [[String: Any]] ?? []
        let currentLink = data["link"] as? String
        let alreadyThere = links.contains { ($0["url"] as? String) == link }
            || (currentLink != nil && normalizedLink(currentLink ?? "") == link)
        guard !alreadyThere else { return }

        var updates: [String: Any] = ["links": FieldValue.arrayUnion([linkDict(link)])]
        if currentLink == nil || currentLink?.isEmpty == true {
            updates["link"] = link
            updates["linkTitle"] = "From \(sourceName)"
        }
        try await existing.reference.updateData(updates)
    }

    /// Undo whatever the backend did for the wrong guess
    private func undoPrevious(in col: CollectionReference) async {
        guard let old = place?.locationId else { return }
        switch place?.result {
        case "created":
            try? await col.document(old).delete()
        case "linkAdded":
            await removeLink(from: col.document(old))
        default:
            break
        }
    }

    private func removeLink(from ref: DocumentReference) async {
        guard let link,
              let snap = try? await ref.getDocument(),
              let data = snap.data() else { return }
        let remaining = (data["links"] as? [[String: Any]] ?? [])
            .filter { ($0["url"] as? String) != link }
        var updates: [String: Any] = ["links": remaining]
        if let current = data["link"] as? String, normalizedLink(current) == link {
            if let next = remaining.first?["url"] as? String {
                updates["link"] = next
            } else {
                updates["link"] = NSNull()
                updates["linkTitle"] = NSNull()
            }
        }
        try? await ref.updateData(updates)
    }

    private func markPending(placeName: String) async {
        try? await pendingRef?.updateData([
            "status": "saved",
            "placeName": placeName,
            "manuallyCorrected": true
        ])
    }

    // MARK: - Small helpers

    private func orNull(_ s: String?) -> Any {
        if let s { return s }
        return NSNull()
    }

    /// Strips tracking params so the same reel is never saved twice (mirrors the Cloud Function)
    private func normalizedLink(_ url: URL) -> String {
        let host = url.host ?? ""
        guard host.contains("tiktok") || host.contains("instagram"),
              var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }
        comps.query = nil
        comps.fragment = nil
        var s = comps.string ?? url.absoluteString
        while s.hasSuffix("/") { s.removeLast() }
        return s
    }

    private func normalizedLink(_ string: String) -> String {
        guard let url = URL(string: string) else { return string }
        return normalizedLink(url)
    }

    private func currentUid() async -> String? {
        if let user = Auth.auth().currentUser { return user.uid }
        do {
            if let stored = try Auth.auth().getStoredUser(forAccessGroup: group) {
                try await Auth.auth().updateCurrentUser(stored)
                return stored.uid
            }
        } catch {
            print("DEBUG [share]: getStoredUser failed: \(error)")
        }
        return nil
    }
}
