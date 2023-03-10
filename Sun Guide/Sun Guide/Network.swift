//
//  Network.swift
//  WidgetTests
//
//  Created by Sanjay Reck Mode on 2022-10-12.
//

import Foundation


import SwiftUI
import WidgetKit
import CoreLocation

class Network: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var sunTimes: SunTimes? = nil
    @Published var localizedSunTimes: LocalizedSunTimes? =  nil
    
    @Published var location: CLLocation?
    @Published var city: String?

    private let locationManager = CLLocationManager()
    let geoCoder = CLGeocoder()

    var currentLong: Double = 36.81
    var currentLat: Double = -1.286
    
    let dateFormatter = ISO8601DateFormatter()
    
    let formatter = DateComponentsFormatter()

    override init() {
        super.init()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func getTimes() {
        guard let location = location else { return }
        guard let url = URL(string: "https://api.sunrise-sunset.org/json?lat=\(location.coordinate.latitude)&lng=\(location.coordinate.longitude)&date=today&formatted=0") else { fatalError()}
        
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Request error:", error)
                return
            }
            
            guard let response = response as? HTTPURLResponse else { return }
            
            if response.statusCode == 200 {
                guard let data = data else { return }
            
                DispatchQueue.main.async {
                    do {
                        let decodedObj = try JSONDecoder().decode(SunriseSunsetAPI.self, from: data)
                        self.sunTimes = decodedObj.results
                        self.localizedSunTimes = LocalizedSunTimes(sunrise: "X", sunset: "X", midday: "X", dayLength: "X")
                        
                        self.dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
                        
                        if let sunsetTime = self.dateFormatter.date(from: decodedObj.results.sunset) {
                            self.dateFormatter.timeZone = TimeZone.current
                        
                            self.localizedSunTimes?.sunset = self.dateFormatter.string(from: sunsetTime)
                        }
                        
                        if let sunriseTime = self.dateFormatter.date(from: decodedObj.results.sunrise) {
                            self.dateFormatter.timeZone = TimeZone.current
                        
                            self.localizedSunTimes?.sunrise = self.dateFormatter.string(from: sunriseTime)
                        }
                        
                        if let middayTime = self.dateFormatter.date(from: decodedObj.results.solar_noon) {
                            self.dateFormatter.timeZone = TimeZone.current
                            
                            self.localizedSunTimes?.midday = self.dateFormatter.string(from: middayTime)
                        }
                        
                        self.formatter.allowedUnits = [.hour, .minute, .second]
                        self.formatter.unitsStyle = .abbreviated
                        
                        if let formattedString = self.formatter.string(from: TimeInterval(decodedObj.results.day_length)) {
                            self.localizedSunTimes?.dayLength = formattedString
                        }
                        
                        // Write to UserDefaults to share with Widget Extension
                        UserDefaults(suiteName: "group.ShahLabs.WidgetTests")!
                            .set(self.localizedSunTimes?.sunset, forKey: "sunsetTime")
                        
                        UserDefaults(suiteName: "group.ShahLabs.WidgetTests")!
                            .set(self.localizedSunTimes?.sunrise, forKey: "sunriseTime")
                        
                        
                        // Calculate decimal based on SunsetTime - SunriseTime and Date()
                        
                        self.dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
                        
                        if let sunriseInCurrentTimeZone = self.dateFormatter.date(from: decodedObj.results.sunrise) {
//                            formatter.dateFormat = "yyyy/MM/dd HH:mm"
//                            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss 'UTC'"


                            guard let date = self.dateFormatter.date(from: Date().ISO8601Format()) else {
                                return
                            }

                            let formatter = DateFormatter()
                            formatter.timeZone = TimeZone.current
                            formatter.dateFormat = "yyyy"
                            let year = formatter.string(from: date)

                            formatter.dateFormat = "MM"
                            let month = formatter.string(from: date)
                            formatter.dateFormat = "dd"
                            let day = formatter.string(from: date)
                            
                            let timeZone = TimeZone.current.abbreviation()
//                            self.dateFormatter.timeZone = TimeZone(abbreviation: timeZone!)
                            
                            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss 'UTC'"


                            if let currentTime = formatter.date(from: "\(year)-\(month)-\(day) 06:00:00 UTC") {
                                
                                let secondsPassedSince6 = Date().timeIntervalSince(currentTime)
                                
                                let currentSunPosition = secondsPassedSince6.interpolated(from: 0...86400, to: 0...1)
                                
                                UserDefaults(suiteName: "group.ShahLabs.WidgetTests")!
                                    .set(currentSunPosition, forKey: "currentPositionDegrees")
                            }

                            
                        }
                        
                        
//                        let currentSunPosition = 0.25

                        
                        // Calculate decimal based on SunsetTime - SunriseTime / 24 hours

                        let sunriseDegrees = 0
                        UserDefaults(suiteName: "group.ShahLabs.WidgetTests")!
                            .set(sunriseDegrees, forKey: "sunriseDegrees")
                        
                        let sunsetDegrees = 0.5
                        UserDefaults(suiteName: "group.ShahLabs.WidgetTests")!
                            .set(sunsetDegrees, forKey: "sunsetDegrees")
                        
                        WidgetCenter.shared.reloadAllTimelines()
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            }
        }
        
        dataTask.resume()
    }
    
    
    
    func getCurrentCity() {
        if let location = location {
            geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, _) -> Void in
                placemarks?.forEach { (placemark) in
                    if let locality = placemark.locality {
                        self.city = locality
                    }
                }
            })
        } else {
            self.city = "Unknown location"
        }
    }
    
    


    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else { return }
            DispatchQueue.main.async {
                self.location = location
                self.getCurrentCity()
                self.getTimes()
                
            }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .notDetermined:
            print("notDetermined")
            manager.requestWhenInUseAuthorization()
        case .restricted:
            print("restricted")
            // Inform user about the restriction
            break
        case
                .denied:
            print("denied")
            // The user denied the use of location services for the app or they are disabled globally in Settings.
            // Direct them to re-enable this.
            break
        case
                .authorizedAlways, .authorizedWhenInUse:
            print("authorized")
            manager.requestLocation()
        }
    }
}


extension FloatingPoint {
  /// Allows mapping between reverse ranges, which are illegal to construct (e.g. `10..<0`).
  func interpolated(
    fromLowerBound: Self,
    fromUpperBound: Self,
    toLowerBound: Self,
    toUpperBound: Self) -> Self
  {
    let positionInRange = (self - fromLowerBound) / (fromUpperBound - fromLowerBound)
    return (positionInRange * (toUpperBound - toLowerBound)) + toLowerBound
  }

  func interpolated(from: ClosedRange<Self>, to: ClosedRange<Self>) -> Self {
    interpolated(
      fromLowerBound: from.lowerBound,
      fromUpperBound: from.upperBound,
      toLowerBound: to.lowerBound,
      toUpperBound: to.upperBound)
  }
}
