//
//  LocationResolver.swift
//  Broche
//
//  Created by Jacob Johnson on 5/16/25.
//

import Foundation
import CoreLocation


struct LocationResolver {
    static let countryToContinent: [String: String] = [
        "AF": "Asia", "AX": "Europe", "AL": "Europe", "DZ": "Africa", "AS": "Oceania",
        "AD": "Europe", "AO": "Africa", "AI": "North America", "AQ": "Antarctica",
        "AG": "North America", "AR": "South America", "AM": "Asia", "AW": "North America",
        "AU": "Oceania", "AT": "Europe", "AZ": "Asia", "BS": "North America", "BH": "Asia",
        "BD": "Asia", "BB": "North America", "BY": "Europe", "BE": "Europe", "BZ": "North America",
        "BJ": "Africa", "BM": "North America", "BT": "Asia", "BO": "South America",
        "BQ": "North America", "BA": "Europe", "BW": "Africa", "BV": "Antarctica",
        "BR": "South America", "IO": "Asia", "BN": "Asia", "BG": "Europe", "BF": "Africa",
        "BI": "Africa", "CV": "Africa", "KH": "Asia", "CM": "Africa", "CA": "North America",
        "KY": "North America", "CF": "Africa", "TD": "Africa", "CL": "South America",
        "CN": "Asia", "CX": "Asia", "CC": "Asia", "CO": "South America", "KM": "Africa",
        "CG": "Africa", "CD": "Africa", "CK": "Oceania", "CR": "North America", "CI": "Africa",
        "HR": "Europe", "CU": "North America", "CW": "North America", "CY": "Asia",
        "CZ": "Europe", "DK": "Europe", "DJ": "Africa", "DM": "North America", "DO": "North America",
        "EC": "South America", "EG": "Africa", "SV": "North America", "GQ": "Africa",
        "ER": "Africa", "EE": "Europe", "ET": "Africa", "FK": "South America", "FO": "Europe",
        "FJ": "Oceania", "FI": "Europe", "FR": "Europe", "GF": "South America", "PF": "Oceania",
        "TF": "Antarctica", "GA": "Africa", "GM": "Africa", "GE": "Asia", "DE": "Europe",
        "GH": "Africa", "GI": "Europe", "GR": "Europe", "GL": "North America", "GD": "North America",
        "GP": "North America", "GU": "Oceania", "GT": "North America", "GG": "Europe",
        "GN": "Africa", "GW": "Africa", "GY": "South America", "HT": "North America",
        "HM": "Antarctica", "VA": "Europe", "HN": "North America", "HK": "Asia", "HU": "Europe",
        "IS": "Europe", "IN": "Asia", "ID": "Asia", "IR": "Asia", "IQ": "Asia", "IE": "Europe",
        "IM": "Europe", "IL": "Asia", "IT": "Europe", "JM": "North America", "JP": "Asia",
        "JE": "Europe", "JO": "Asia", "KZ": "Asia", "KE": "Africa", "KI": "Oceania",
        "KP": "Asia", "KR": "Asia", "KW": "Asia", "KG": "Asia", "LA": "Asia", "LV": "Europe",
        "LB": "Asia", "LS": "Africa", "LR": "Africa", "LY": "Africa", "LI": "Europe",
        "LT": "Europe", "LU": "Europe", "MO": "Asia", "MG": "Africa", "MW": "Africa",
        "MY": "Asia", "MV": "Asia", "ML": "Africa", "MT": "Europe", "MH": "Oceania",
        "MQ": "North America", "MR": "Africa", "MU": "Africa", "YT": "Africa", "MX": "North America",
        "FM": "Oceania", "MD": "Europe", "MC": "Europe", "MN": "Asia", "ME": "Europe",
        "MS": "North America", "MA": "Africa", "MZ": "Africa", "MM": "Asia", "NA": "Africa",
        "NR": "Oceania", "NP": "Asia", "NL": "Europe", "NC": "Oceania", "NZ": "Oceania",
        "NI": "North America", "NE": "Africa", "NG": "Africa", "NU": "Oceania", "NF": "Oceania",
        "MK": "Europe", "MP": "Oceania", "NO": "Europe", "OM": "Asia", "PK": "Asia",
        "PW": "Oceania", "PS": "Asia", "PA": "North America", "PG": "Oceania", "PY": "South America",
        "PE": "South America", "PH": "Asia", "PN": "Oceania", "PL": "Europe", "PT": "Europe",
        "PR": "North America", "QA": "Asia", "RE": "Africa", "RO": "Europe", "RU": "Europe",
        "RW": "Africa", "BL": "North America", "SH": "Africa", "KN": "North America",
        "LC": "North America", "MF": "North America", "PM": "North America", "VC": "North America",
        "WS": "Oceania", "SM": "Europe", "ST": "Africa", "SA": "Asia", "SN": "Africa",
        "RS": "Europe", "SC": "Africa", "SL": "Africa", "SG": "Asia", "SX": "North America",
        "SK": "Europe", "SI": "Europe", "SB": "Oceania", "SO": "Africa", "ZA": "Africa",
        "GS": "Antarctica", "SS": "Africa", "ES": "Europe", "LK": "Asia", "SD": "Africa",
        "SR": "South America", "SJ": "Europe", "SZ": "Africa", "SE": "Europe", "CH": "Europe",
        "SY": "Asia", "TW": "Asia", "TJ": "Asia", "TZ": "Africa", "TH": "Asia", "TL": "Asia",
        "TG": "Africa", "TK": "Oceania", "TO": "Oceania", "TT": "North America", "TN": "Africa",
        "TR": "Asia", "TM": "Asia", "TC": "North America", "TV": "Oceania", "UG": "Africa",
        "UA": "Europe", "AE": "Asia", "GB": "Europe", "US": "North America", "UM": "Oceania",
        "UY": "South America", "UZ": "Asia", "VU": "Oceania", "VE": "South America", "VN": "Asia",
        "VG": "North America", "VI": "North America", "WF": "Oceania", "EH": "Africa",
        "YE": "Asia", "ZM": "Africa", "ZW": "Africa"
    ]
    
    static func resolve(latitude: Double, longitude: Double) async throws -> ResolvedRegion {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        
        guard let placemark = placemarks.first else {
            return ResolvedRegion(state: nil, country: nil, countryCode: nil, continent: nil)
        }
        
        let state = placemark.administrativeArea
        let country = placemark.country
        let countryCode = placemark.isoCountryCode
        let continent = countryCode.flatMap { countryToContinent[$0] }
        
        return ResolvedRegion(state: state, country: country, countryCode: countryCode, continent: continent)
    }
}

struct ResolvedRegion {
    let state: String?
    let country: String?
    let countryCode: String?
    let continent: String?
}

enum RegionGeography {
    static let usStateCentroids: [String: CLLocationCoordinate2D] = [
        "al": .init(latitude: 32.806671, longitude: -86.791130),
        "ak": .init(latitude: 61.370716, longitude: -152.404419),
        "az": .init(latitude: 33.729759, longitude: -111.431221),
        "ar": .init(latitude: 34.969704, longitude: -92.373123),
        "ca": .init(latitude: 36.116203, longitude: -119.681564),
        "co": .init(latitude: 39.059811, longitude: -105.311104),
        "ct": .init(latitude: 41.597782, longitude: -72.755371),
        "de": .init(latitude: 39.318523, longitude: -75.507141),
        "fl": .init(latitude: 27.766279, longitude: -81.686783),
        "ga": .init(latitude: 33.040619, longitude: -83.643074),
        "hi": .init(latitude: 21.094318, longitude: -157.498337),
        "id": .init(latitude: 44.240459, longitude: -114.478828),
        "il": .init(latitude: 40.349457, longitude: -88.986137),
        "in": .init(latitude: 39.849426, longitude: -86.258278),
        "ia": .init(latitude: 42.011539, longitude: -93.210526),
        "ks": .init(latitude: 38.526600, longitude: -96.726486),
        "ky": .init(latitude: 37.668140, longitude: -84.670067),
        "la": .init(latitude: 31.169546, longitude: -91.867805),
        "me": .init(latitude: 44.693947, longitude: -69.381927),
        "md": .init(latitude: 39.063946, longitude: -76.802101),
        "ma": .init(latitude: 42.230171, longitude: -71.530106),
        "mi": .init(latitude: 43.326618, longitude: -84.536095),
        "mn": .init(latitude: 45.694454, longitude: -93.900192),
        "ms": .init(latitude: 32.741646, longitude: -89.678696),
        "mo": .init(latitude: 38.456085, longitude: -92.288368),
        "mt": .init(latitude: 46.921925, longitude: -110.454353),
        "ne": .init(latitude: 41.125370, longitude: -98.268082),
        "nv": .init(latitude: 38.313515, longitude: -117.055374),
        "nh": .init(latitude: 43.452492, longitude: -71.563896),
        "nj": .init(latitude: 40.298904, longitude: -74.521011),
        "nm": .init(latitude: 34.840515, longitude: -106.248482),
        "ny": .init(latitude: 42.165726, longitude: -74.948051),
        "nc": .init(latitude: 35.630066, longitude: -79.806419),
        "nd": .init(latitude: 47.528912, longitude: -99.784012),
        "oh": .init(latitude: 40.388783, longitude: -82.764915),
        "ok": .init(latitude: 35.565342, longitude: -96.928917),
        "or": .init(latitude: 44.572021, longitude: -122.070938),
        "pa": .init(latitude: 40.590752, longitude: -77.209755),
        "ri": .init(latitude: 41.680893, longitude: -71.511780),
        "sc": .init(latitude: 33.856892, longitude: -80.945007),
        "sd": .init(latitude: 44.299782, longitude: -99.438828),
        "tn": .init(latitude: 35.747845, longitude: -86.692345),
        "tx": .init(latitude: 31.054487, longitude: -97.563461),
        "ut": .init(latitude: 40.150032, longitude: -111.862434),
        "vt": .init(latitude: 44.045876, longitude: -72.710686),
        "va": .init(latitude: 37.769337, longitude: -78.169968),
        "wa": .init(latitude: 47.400902, longitude: -121.490494),
        "wv": .init(latitude: 38.491226, longitude: -80.954453),
        "wi": .init(latitude: 44.268543, longitude: -89.616508),
        "wy": .init(latitude: 42.755966, longitude: -107.302490)
    ]

    static let continentCenters: [String: CLLocationCoordinate2D] = [
        "north america": .init(latitude: 54.5, longitude: -105.0),
        "south america": .init(latitude: -8.8, longitude: -63.5),
        "europe": .init(latitude: 54.5, longitude: 15.2),
        "asia": .init(latitude: 34.0, longitude: 100.6),
        "oceania": .init(latitude: -25.0, longitude: 140.0),
        "africa": .init(latitude: 2.0, longitude: 21.8),
        "antarctica": .init(latitude: -82.0, longitude: 135.0)
    ]

    static func geocodeCountryCenter(_ name: String) async -> CLLocationCoordinate2D? {
        do {
            let placemarks = try await CLGeocoder().geocodeAddressString(name)
            return placemarks.first?.location?.coordinate
        } catch {
            print("DEBUG: Failed to geocode country center for \(name): \(error.localizedDescription)")
            return nil
        }
    }
}
