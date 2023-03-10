//
//  WidgetTimelineProvider.swift
//  WidgetTests
//
//  Created by Sanjay Reck Mode on 2022-10-16.
//

import Foundation
import WidgetKit

struct WidgetTimelineProvider: IntentTimelineProvider {
    let sunsetTime = UserDefaults(suiteName: "group.ShahLabs.WidgetTests")!.object(forKey: "sunsetTime")
    let sunriseTime = UserDefaults(suiteName: "group.ShahLabs.WidgetTests")!.object(forKey: "sunriseTime")

    let sunsetDegrees = UserDefaults(suiteName: "group.ShahLabs.WidgetTests")!.object(forKey: "sunsetDegrees")
    let sunriseDegrees = UserDefaults(suiteName: "group.ShahLabs.WidgetTests")!.object(forKey: "sunriseDegrees")
    let currentPositionDegrees = UserDefaults(suiteName: "group.ShahLabs.WidgetTests")!.object(forKey: "currentPositionDegrees")


    
    func placeholder(in context: Context) -> SunlightTimelineEntry {
        SunlightTimelineEntry(date: Date(), sunsetTime: "Placeholder time", sunriseTime: "Sunrise am", currentSunPosition: 0.25, sunriseDegrees: 0, sunsetDegrees: 0.5, configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SunlightTimelineEntry) -> ()) {
        
        if let sunsetTime = sunsetTime as? String, let sunriseTime = sunriseTime as? String, let sunsetDegrees = sunsetDegrees as? CGFloat, let sunriseDegrees = sunriseDegrees as? CGFloat, let currentPositionDegrees = currentPositionDegrees as? CGFloat {
            let entry = SunlightTimelineEntry(date: Date(), sunsetTime: sunsetTime, sunriseTime: sunriseTime, currentSunPosition: currentPositionDegrees, sunriseDegrees: sunriseDegrees, sunsetDegrees: sunsetDegrees, configuration: configuration)
            completion(entry)
        }
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<SunlightTimelineEntry>) -> ()) {
//        var entries: [SunlightTimelineEntry] = []

        let isoDate = sunsetTime

        let dateFormatter = ISO8601DateFormatter()
//        let date = dateFormatter.date(from:isoDate)!
//        let minutesToSunset = Date().timeIntervalSince(date).formatted()
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        
        let date = Date()
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 1, to: date)!
        
        if let sunsetTime = sunsetTime as? String, let sunriseTime = sunriseTime as? String, let sunsetDegrees = sunsetDegrees as? CGFloat, let sunriseDegrees = sunriseDegrees as? CGFloat, let currentPositionDegrees = currentPositionDegrees as? CGFloat {
            
            let entry = SunlightTimelineEntry(date: date, sunsetTime: sunsetTime, sunriseTime: sunriseTime, currentSunPosition: currentPositionDegrees, sunriseDegrees: sunriseDegrees, sunsetDegrees: sunsetDegrees, configuration: configuration)
            
            let timeline = Timeline(
                entries:[entry],
                policy: .after(nextUpdateDate)
            )
            
            completion(timeline)
        }
    }
}
