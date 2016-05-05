//
//  LauncherViewController.swift
//  ExDisplay
//
//  Created by elsie on 16/4/20.
//  Copyright © 2016年 AppStudio. All rights reserved.
//

import Foundation
import UIKit
import ExAuto
import CoreLocation
import Alamofire
import Foundation
import MediaPlayer

class LauncherViewController: UIViewController,ExDisplayControlProtocol, CLLocationManagerDelegate,MusicPlayerDelegate {
    
    var secondScreenView : UIView?
    var defaultFocusView : UIView?
    
    var weatherView = WeatherView()
    var tempString: AnyObject!
    var weatherImgURL: AnyObject!
    var weatherString: AnyObject!
    var PMString: AnyObject!
    var carWashIndexZsString: AnyObject!
    var carWashIndexDesString: AnyObject!
    var activity: UIActivityIndicatorView!
    
    // 当前城市
    var currentCity: NSString!
    
    // 当前区
    var SubLocality: NSString!
    
    //保存获取到的本地位置
    var currentLocation: CLLocation!
    
    //用于定位服务管理类，它能够给我们提供位置信息和高度信息，也可以监控设备进入或离开某个区域，还可以获得设备的运行方向
    let locationManager: CLLocationManager = CLLocationManager()
    
    var isPlaying: Bool = false
    var musicPlayerView = MusicPlayerView()
    
    var musicPlayer: MusicPlayer!
    var musicPlayerModel: MusicPlayerModel!
    let musicListNameArray: NSMutableArray = NSMutableArray()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
        secondScreenView = self.view
        ExControlCenter.sharedInstance()!.displayControlDelegate = self
        ExControlCenter.sharedInstance()!.setFocusForView(defaultFocusView)
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func initView() {
        self.view = UIView(frame:CGRectZero)
        
        let backImg = UIImage(named: "homeLauncherBg")
        let backImgView = UIImageView(image: backImg)
        backImgView.frame = UIScreen.screens()[1].bounds
        self.view.addSubview(backImgView)
        
        weatherView = WeatherView.init(frame: CGRect(x: 1920 - 225, y: 100, width: 195, height: 295))
        self.view.addSubview(weatherView)
        
        self.activity = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        self.activity.center = CGPoint(x: 100, y: 130)
        self.activity.activityIndicatorViewStyle = .White
        weatherView.addSubview(self.activity)
        self.activity.startAnimating()
        
        initLocation()
        initMusiPlayer()
        initBaseView()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // 判断定位是否开启
        let status: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        if (CLAuthorizationStatus.Denied == status || CLAuthorizationStatus.Restricted == status) {
            let alert = UIAlertController(title: "提示", message: "请打开您的位置服务！", preferredStyle: .Alert)
            let cancleAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
            let okAction = UIAlertAction(title: "设置", style: .Default, handler: { (action) in
                // 跳转到设置（打开定位）
                let url: NSURL = NSURL(string: UIApplicationOpenSettingsURLString)!
                if UIApplication.sharedApplication().canOpenURL(url) {
                    UIApplication.sharedApplication().openURL(url)
                }
            })
            alert.addAction(cancleAction)
            alert.addAction(okAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    //MARK: - Private
    private func initMusiPlayer() {
        musicPlayerModel = MusicPlayerModel.init()
        musicPlayer = MusicPlayer.init()
        musicPlayer.delegate = self
        let mediaItemCollection = musicPlayerModel.musicMediaItemCollectionWithMediaGrouping(.Title)
        if mediaItemCollection.count > 0 {
            let songs = mediaItemCollection.items
            let playingItem = songs[0] as MPMediaItem
            musicPlayer.setMediaPlayerWithItemCollection(mediaItemCollection, nowPlayingItem: playingItem)
            
            for item in mediaItemCollection.items {
                let musicName = item.valueForProperty(MPMediaItemPropertyTitle)
                musicListNameArray.addObject(musicName!)
            }
        }
    }
    
    private func initBaseView() {
        
        // 初始化MusicPlayerView
        self.view.backgroundColor = UIColor.whiteColor()
        musicPlayerView = MusicPlayerView.init(frame: CGRect(x: 200, y: 1080 - 160, width: 1520, height: 60))
        self.view.addSubview(musicPlayerView)
        
        // 添加MusicPlayerView中控件点击事件
        musicPlayerView.playPauseButton.addTarget(self, action: #selector(handlePlayStatusButtonClick(_:)), forControlEvents: .TouchUpInside)
        musicPlayerView.playNextButton.addTarget(self, action: #selector(handlePlayStatusButtonClick(_:)), forControlEvents: .TouchUpInside)
        musicPlayerView.playPreviousButton.addTarget(self, action: #selector(handlePlayStatusButtonClick(_:)), forControlEvents: .TouchUpInside)
        musicPlayerView.playMenuButton.addTarget(self, action: #selector(handlePlayStatusButtonClick(_:)), forControlEvents: .TouchUpInside)
    }
    
    //MARK: - Public
    
    //MARK: - IBActions
    func handlePlayStatusButtonClick(sender: UIButton) -> Void {
        switch sender {
        case musicPlayerView.playPauseButton:
            if musicListNameArray.count == 0 {
                return
            } else{
                if isPlaying {
                    isPlaying = false
                    musicPlayer.musicPause()
                } else {
                    isPlaying = true
                    musicPlayer.musicPlay()
                }
            }
            break
        case musicPlayerView.playNextButton:
            musicPlayer.musicPlayNext()
            break
        case musicPlayerView.playPreviousButton:
            musicPlayer.musicPlayPrevious()
            break
        case musicPlayerView.playMenuButton:
            
            break
        default:
            break
        }
    }
    
    //MARK: - Protocol conformance
    
    //MARK: - MusicPlayerDelegate
    func musicPlayer(musicPlayer: MusicPlayer, updatePlaybackCurrentTime currentTime: NSTimeInterval, playbackDurationTime durationTime: NSTimeInterval) {
        musicPlayerView.playProgressBar.progress = Float(currentTime / durationTime)
    }
    
    func musicPlayer(musicPlayer: MusicPlayer, didChangeNowPlayingItem nowPlayingItem: MPMediaItem) {
        
    }
    
    func musicPlayer(musicPlayer: MusicPlayer, didChangePlaybackState playbackState: MPMusicPlaybackState) {
        switch playbackState {
        case .Stopped:
            
            break
        case .Playing:
            musicPlayerView.playPauseButton.setBackgroundImage(UIImage(named: "homeMusic-pause"), forState: .Normal)
            break
        case .SeekingForward:
            
            break
        case .SeekingBackward:
            
            break
        case .Paused:
            musicPlayerView.playPauseButton.setBackgroundImage(UIImage(named: "homeMusic-play"), forState: .Normal)
            break
        default:
            break
        }
    }
    
    func initLocation() {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        //设备使用电池供电时最高的精度
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        //精确到1000米,距离过滤器，定义了设备移动后获得位置信息的最小距离
        locationManager.distanceFilter = kCLLocationAccuracyKilometer
        locationManager.startUpdatingLocation()
    }
    
    //MARK: - Protocol conformance
    //MARK:- 实现CLLocationManagerDelegate协议
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        print(currentLocation.coordinate.longitude)
        print(currentLocation.coordinate.latitude)
        reverseGeocode()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print(error)
    }
    
    // 将经纬度转换为城市名
    func reverseGeocode() {
        let geocoder = CLGeocoder()
        var mark:CLPlacemark?
        
        // 逆地理转换(坐标 -> 地理)
        geocoder.reverseGeocodeLocation(currentLocation, completionHandler: { (placemarks, error) -> Void in
            if (error == nil) {// 转换成功
                let pm = placemarks! as [CLPlacemark]
                if (pm.count > 0) {
                    mark = placemarks![0]
                    let city: String = (mark!.addressDictionary! as NSDictionary).valueForKey("City") as! String
                    self.SubLocality = (mark!.addressDictionary! as NSDictionary).valueForKey("SubLocality") as! NSString
                    
                    // 去掉“市”字眼
                    self.currentCity = city.stringByReplacingOccurrencesOfString("市", withString: "")
                    
                    let location: String = (self.currentCity as String) + "，" + (self.SubLocality as String)
                    self.weatherView.locationLabel.text = location
                    
                    self.networkRequest()
                }
            } else {
                // 转换地理失败
                print("error is : " + "\(error)")
            }
        })
    }
    
    //MARK: - Private
    // Networking
    private func networkRequest() {
        
        let url = "http://api.map.baidu.com/telematics/v3/weather"
        
        request(.GET, url, parameters: ["location": self.currentCity, "output": "json", "ak": "A72e372de05e63c8740b2622d0ed8ab1"])
            .response { (request, response, data, error) in
                
                self.activity.stopAnimating()
                self.activity.hidden = true
                
                if (error == nil) {
                    let string = NSString(data: data!, encoding: NSUTF8StringEncoding) as! String
                    let returnData: NSData = string.dataUsingEncoding(NSUTF8StringEncoding)!
                    let jsonDict: AnyObject! = try? NSJSONSerialization.JSONObjectWithData(returnData, options: NSJSONReadingOptions.AllowFragments)
                    
                    self.tempString = (((jsonDict.objectForKey("results")?.objectAtIndex(0).objectForKey("weather_data")?.objectAtIndex(0).objectForKey("date")?.componentsSeparatedByString("："))! as NSArray).objectAtIndex(1).componentsSeparatedByString("℃") as NSArray).objectAtIndex(0) as! String + "°"
                    self.weatherImgURL = jsonDict.objectForKey("results")?.objectAtIndex(0).objectForKey("weather_data")?.objectAtIndex(0).objectForKey("dayPictureUrl")
                    self.weatherString = jsonDict.objectForKey("results")?.objectAtIndex(0).objectForKey("weather_data")?.objectAtIndex(0).objectForKey("weather")
                    self.PMString = jsonDict.objectForKey("results")?.objectAtIndex(0).objectForKey("pm25")
                    self.carWashIndexZsString = jsonDict.objectForKey("results")?.objectAtIndex(0).objectForKey("index")?.objectAtIndex(1).objectForKey("zs")
                    self.carWashIndexDesString = jsonDict.objectForKey("results")?.objectAtIndex(0).objectForKey("index")?.objectAtIndex(1).objectForKey("des")
                    
                    print("tempString is: " + String(self.tempString))
                    print("weatherImgURL is: " + String(self.weatherImgURL))
                    print("weatherString is: " + String(self.weatherString))
                    print("PMString is: " + String(self.PMString))
                    print("carWashIndexZsString is: " + String(self.carWashIndexZsString))
                    print("carWashIndexDesString is: " + String(self.carWashIndexDesString))
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.weatherView.tempLabel.text = self.tempString as? String
                        self.weatherView.weatherLabel.text = self.weatherString as? String
                        self.weatherView.PMNumLabel.text = self.PMString as? String
                        self.weatherView.carWashIndexZsLabel.text = self.carWashIndexZsString as? String
                        self.weatherView.carWashIndexDesLabel.text = self.carWashIndexDesString as? String
                        
                        let imageUrl: NSURL = NSURL(string: self.weatherImgURL as! String)!
                        let imageData: NSData = NSData(contentsOfURL: imageUrl)!
                        let image = UIImage(data: imageData, scale: 1.0)
                        self.weatherView.weatherImage.image = image
                    })
                } else {
                    print("error is: " + "\(error)")
                }
        }
    }
    

    //MARK: - ExDisplayControlProtocol
    func confirm(){
        
        let curView : UIView? = ExControlCenter.sharedInstance()!.focusView
        let viewTag : Int = curView!.tag
        switch viewTag {
        case 0:
            break
            
        default:
            break
            
        }
    }
    func back(){
        
    }
    func voiceChange(voiceAmountScale:Float){
        
    }
    func showMenu(){
        
    }
    func hideMenu(){
        
    }
    func showSiri(){
        
    }
    func hideSiri(){
        
    }
}