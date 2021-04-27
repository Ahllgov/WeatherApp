//
//  WeatherGetter.swift
//  WeatherAppByAhllgov
//
//  Created by Магомед Ахильгов on 19.04.2021.
//

import Foundation

protocol WeatherGetterDelegate {
    func didGetWeather(weather: Weather)
    func didNotGetWeather(error: NSError)
}

//MARK: - WeatherGetter

class WeatherGetter {
    
    private let openWeatherMapBaseURL = "https://api.openweathermap.org/data/2.5/weather"
    private let openWeatherMapAPIKey = "72c12f7b63b5d03c992a28779bc4d5c6"
    
    private var delegate: WeatherGetterDelegate
    
    // MARK: -
    
    init(delegate: WeatherGetterDelegate) {
        self.delegate = delegate
    }
    
    func getWeatherByCity(city: String) {
       let weatherRequestURL = NSURL(string: "\(openWeatherMapBaseURL)?APPID=\(openWeatherMapAPIKey)&q=\(city)&lang=ru")!
        getWeather(weatherRequestURL: weatherRequestURL)
     }
     
     func getWeatherByCoordinates(latitude latitude: Double, longitude: Double) {
       let weatherRequestURL = NSURL(string: "\(openWeatherMapBaseURL)?APPID=\(openWeatherMapAPIKey)&lat=\(latitude)&lon=\(longitude)")!
        getWeather(weatherRequestURL: weatherRequestURL)
     }
    private func getWeather(weatherRequestURL: NSURL) {
       
       // This is a pretty simple networking task, so the shared session will do.
        let session = URLSession.shared
       session.configuration.timeoutIntervalForRequest = 3
       
       // The data task retrieves the data.
        let dataTask = session.dataTask(with: weatherRequestURL as URL) {
                  (data, response, error) in
                        if let networkError = error {
           // Case 1: Error
           // An error occurred while trying to get data from the server.
                            self.delegate.didNotGetWeather(error: networkError as NSError)
         }
         else {
           // Case 2: Success
           // We got data from the server!
           do {
             // Try to convert that data into a Swift dictionary
            let weatherData = try JSONSerialization.jsonObject(
                with: data!,
                options: .mutableContainers) as! [String: AnyObject]
             
             // If we made it to this point, we've successfully converted the
             // JSON-formatted weather data into a Swift dictionary.
             // Let's now used that dictionary to initialize a Weather struct.
             let weather = Weather(weatherData: weatherData)
             
             // Now that we have the Weather struct, let's notify the view controller,
             // which will use it to display the weather to the user.
            self.delegate.didGetWeather(weather: weather)
           }
           catch let jsonError as NSError {
             // An error occurred while trying to convert the data into a Swift dictionary.
            self.delegate.didNotGetWeather(error: jsonError)
           }
         }
       }
       
       // The data task is set up...launch it!
       dataTask.resume()
     }
     
   }
