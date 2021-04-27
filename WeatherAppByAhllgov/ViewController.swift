//
//  ViewController.swift
//  WeatherAppByAhllgov
//
//  Created by Магомед Ахильгов on 19.04.2021.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, WeatherGetterDelegate, UITextFieldDelegate {
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var getCityWeatherButton: UIButton!{
        didSet{
            getCityWeatherButton.layer.cornerRadius = 5
            getCityWeatherButton.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var getLocationWeatherButton: UIButton!
    
    @IBOutlet weak var uiImageView: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var weatherLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var cloudCoverLabel: UILabel!
    @IBOutlet weak var windLabel: UILabel!
    @IBOutlet weak var rainLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    
    let locationManager = CLLocationManager()
    var weather: WeatherGetter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        assignbackground()
        
        weather = WeatherGetter(delegate: self)
        //Инициализируем  UI
        cityLabel.text = "simple weather"
        weatherLabel.text = ""
        temperatureLabel.text = ""
        cloudCoverLabel.text = ""
        windLabel.text = ""
        rainLabel.text = ""
        humidityLabel.text = ""
        cityTextField.text = ""
        cityTextField.delegate = self
        cityTextField.enablesReturnKeyAutomatically = true
        getCityWeatherButton.isEnabled = false
        getLocation()
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func assignbackground(){
            let background = UIImage(named: "backgroundForWeather")

            var imageView : UIImageView!
            imageView = UIImageView(frame: self.view.bounds)
            imageView.contentMode =  UIView.ContentMode.scaleAspectFill
            imageView.clipsToBounds = true
            imageView.image = background
            imageView.center = self.view.center
            self.view.addSubview(imageView)
            self.view.sendSubviewToBack(imageView)
    }
    
    func getWeatherImage(){
        //URL containing the image
        let URL_IMAGE = URL(string: "https://openweathermap.org/img/wn/10n@2x.png")
        let session = URLSession(configuration: .default)
        //creating a dataTask
        let getImageFromUrl = session.dataTask(with: URL_IMAGE!) { (data, response, error) in
            //if there is any error
            if let e = error {
                //displaying the message
                print("Error Occurred: \(e)")
            } else {
                //in case of now error, checking wheather the response is nil or not
                if (response as? HTTPURLResponse) != nil {
                    //checking if the response contains an image
                    if let imageData = data {
                        //getting the image
                        let image = UIImage(data: imageData)
                        //displaying the image
                        self.uiImageView.image = image
                    } else {
                        print("Image file is currupted")
                    }
                } else {
                    print("No response from server")
                }
            }
        }
        //starting the download task
        getImageFromUrl.resume()
    }
    
    
    // MARK: - Button events
    // ---------------------
    
    @IBAction func getWeatherForCityButtonTapped(sender: UIButton) {
        guard let text = cityTextField.text, !text.trimmed.isEmpty else {
            return
        }
        setWeatherButtonStates(state: false)
        weather.getWeatherByCity(city: cityTextField.text!.urlEncoded)
    }
    
    @IBAction func getWeatherLocationButtonTapped(_ sender: Any) {
        setWeatherButtonStates(state: false)
        getLocation()
    }
    
    
    func setWeatherButtonStates(state: Bool) {
        getLocationWeatherButton.isEnabled = state
        getCityWeatherButton.isEnabled = state
    }
    
    
    
    // MARK: - WeatherGetterDelegate methods
    // -----------------------------------
    
    func didGetWeather(weather: Weather) {
        // This method is called asynchronously, which means it won't execute in the main queue.
        // ALl UI code needs to execute in the main queue, which is why we're wrapping the code
        // that updates all the labels in a dispatch_async() call.
        let imageUrlString = "https://openweathermap.org/img/wn/\(weather.weatherIconID)@2x.png"
        guard let imageUrl:URL = URL(string: imageUrlString) else {
            return
        }
        DispatchQueue.main.async {
            self.cityLabel.text = weather.city
            self.weatherLabel.text = weather.weatherDescription
            self.temperatureLabel.text = "\(Int(round(weather.tempCelsius)))°"
            self.cloudCoverLabel.text = "\(weather.cloudCover)%"
            self.windLabel.text = "\(weather.windSpeed) м/с"
            self.uiImageView.loadImge(withUrl: imageUrl)
            
            if let rain = weather.rainfallInLast3Hours {
                self.rainLabel.text = "\(rain) мм"
            }
            else {
                self.rainLabel.text = "Нет"
            }
            
            self.humidityLabel.text = "\(weather.humidity)%"
            self.getLocationWeatherButton.isEnabled = true
            self.getCityWeatherButton.isEnabled = self.cityTextField.text!.count > 0
        }
    }
    
    
    
    func didNotGetWeather(error: NSError) {
        print("didNotGetWeather error: \(error)")
        setWeatherButtonStates(state: true)
    }
    //MARK: - CLLocationManagerDelegate and related methods
    
    func getLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            showSimpleAlert(
                title: "Please turn on location services",
                message: "This app needs location services in order to report the weather " +
                    "for your current location.\n" +
                    "Go to Settings → Privacy → Location Services and turn location services on."
            )
            getLocationWeatherButton.isEnabled = true
            return
        }
        
        let authStatus = CLLocationManager.authorizationStatus()
        guard authStatus == .authorizedWhenInUse else {
            switch authStatus {
            case .denied, .restricted:
                let alert = UIAlertController(
                    title: "Location services for this app are disabled",
                    message: "In order to get your current location, please open Settings for this app, choose \"Location\"  and set \"Allow location access\" to \"While Using the App\".",
                    preferredStyle: .alert
                )
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let openSettingsAction = UIAlertAction(title: "Open Settings", style: .default) {
                    action in
                    if let url = NSURL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.canOpenURL(url as URL)
                    }
                }
                alert.addAction(cancelAction)
                alert.addAction(openSettingsAction)
                present(alert, animated: true, completion: nil)
                getLocationWeatherButton.isEnabled = true
                return
                
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
                
            default:
                print("Oops! Shouldn't have come this far.")
            }
            
            return
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.requestLocation()
    }
    
    // MARK: - UITextFieldDelegate and related methods
    // -----------------------------------------------
    
    // Enable the "Get weather for the city above" button
    // if the city text field contains any text,
    // disable it otherwise.
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(
            in: range,
            with: string)
        getCityWeatherButton.isEnabled = prospectiveText.count > 0
        print("Count: \(prospectiveText.count)")
        return true
    }
    
    // Pressing the clear button on the text field (the x-in-a-circle button
    // on the right side of the field)
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        // Even though pressing the clear button clears the text field,
        // this line is necessary. I'll explain in a later blog post.
        textField.text = ""
        
        getCityWeatherButton.isEnabled = false
        return true
    }
    
    // Pressing the return button on the keyboard should be like
    // pressing the "Get weather for the city above" button.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        getWeatherForCityButtonTapped(sender: getCityWeatherButton)
        return true
    }
    
    // Tapping on the view should dismiss the keyboard.
    func touchbegans(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.view.endEditing(true)
    }
    
    
    // MARK: - Utility methods
    // -----------------------
    
    func showSimpleAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(
            title: "OK",
            style:  .default,
            handler: nil
        )
        alert.addAction(okAction)
        present(
            alert,
            animated: true,
            completion: nil
        )
    }
}


extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        weather.getWeatherByCoordinates(
            latitude: newLocation.coordinate.latitude,
            longitude: newLocation.coordinate.longitude
        )
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.showSimpleAlert(
                title: "Can't determine your location",
                message: "The GPS and other location services aren't responding."
            )
        }
        print("locationManager didFailWithError: \(error.localizedDescription)")
    }
}


extension String {
    
    // A handy method for %-encoding strings containing spaces and other
    // characters that need to be converted for use in URLs.
    var urlEncoded: String {
        return self.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlUserAllowed)!
    }
    var trimmed: String {
        return self.trimmingCharacters(in: NSCharacterSet.whitespaces)
    }
}

extension UIImageView {
    
    func loadImge(withUrl url: URL) {
        
        DispatchQueue.global().async { [weak self] in
            if let imageData = try? Data(contentsOf: url) {
                if let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}
