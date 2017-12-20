//
//  InterfaceController.swift
//  AWAREWatch Extension
//
//  Created by Yuuki Nishiyama on 2017/12/13.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion
import HealthKit
import UIKit
import UserNotifications


class InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate{
    
    @IBOutlet var stateControlBtn: WKInterfaceSwitch!
    
    let motionManager = CMMotionManager()
    let healthStore = HKHealthStore()
    let interfaceDevice = WKInterfaceDevice()
    let awareFM = AWAREFileManager()
    
    var motionTimer: Timer!
    var session: HKWorkoutSession!
    var isRunning: Bool!
    var dutyTimer: Timer!
    var hz:Double!
    var waitSec:Double!
    var runSec:Double!
    var bcTimer: Timer!
    var bcInterval:Double!
    
    // var localFileURL:NSURL!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        isRunning = false
        hz = 1.0/50.0
        waitSec = 30
        runSec = 5
        bcInterval = 1

        // Save to sharedContainer
        ////////// write //////////
        self.awareFM.showData()
        
        //////////////////////
        
        // https://developer.apple.com/documentation/watchkit/wkinterfacedevice
        self.interfaceDevice.isBatteryMonitoringEnabled = true //UIDeviceBatteryStateDidChangeNotification
        // NotificationCenter.default.addObserver(self, selector: "batteryStateDidChange:", name:Battery, object: nil)
        
        self.bcTimer = Timer.scheduledTimer(timeInterval: bcInterval,
                                              target: self,
                                              selector: #selector(checkBatteryState),
                                              userInfo: nil,
                                              repeats: true)
        // self.sendNotification()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer vis
        super.didDeactivate()
    }
    
    @objc func checkBatteryState(){
        
        let batteryLevel = self.interfaceDevice.batteryLevel
        // print("Battery Level: \(batteryLevel)%")
        switch self.interfaceDevice.batteryState {
            case WKInterfaceDeviceBatteryState.charging:
                print("Battery Level: \(batteryLevel) -> charging")
            case WKInterfaceDeviceBatteryState.full:
                print("Battery Level: \(batteryLevel) -> full")
            case WKInterfaceDeviceBatteryState.unplugged:
                print("Battery Level: \(batteryLevel) -> unplugged")
            case WKInterfaceDeviceBatteryState.unknown:
                print("Battery Level: \(batteryLevel) -> unknown")
            default:
                print("Battery Level: \(batteryLevel) -> default")
        }
        
    }
    
    @IBAction func pushedLocalNotificationButton() {
        sendNotification()
    }
    
    ///////////////////////
    
    @IBAction func changedSwitchButton(_ value: Bool) {
        print("changed button")
        if value {
            startWorkoutSession()
            startDutyCycle()
        } else {
            stopDutyCycle()
            stopWorkoutSession()
        }
    }
    
    
    /////////////////////////
    func startDutyCycle(){
        if dutyTimer == nil {
            print("start")
            doDutyCycle()
        }
    }
    
    @objc func doDutyCycle(){
        if isRunning{
            print("wait")
            stopDeviceMotion()
            self.dutyTimer = Timer.scheduledTimer(timeInterval: waitSec,
                                             target: self,
                                             selector:#selector(doDutyCycle),
                                             userInfo: nil,
                                             repeats: false)
            // self.dutyTimer.fire()
            isRunning = false
            awareFM.closeFile()
        }else{
            print("resume")
            awareFM.openFile()
            startDeviceMotion()
            self.dutyTimer = Timer.scheduledTimer(timeInterval: runSec,
                                             target: self,
                                             selector:#selector(doDutyCycle),
                                             userInfo: nil,
                                             repeats: false)
            // self.dutyTimer.fire()
            isRunning = true
        }
        
    }
    
    func stopDutyCycle(){
        if dutyTimer != nil {
            dutyTimer.invalidate()
            dutyTimer = nil
            print("end")
        }
    }
    
    
    ///////////////////////
    func startWorkoutSession(){
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .unknown
        
        do{
            self.session = try HKWorkoutSession(configuration: configuration)
            session.delegate = self
            self.healthStore.start(session)
        }
        catch let error as NSError{
            fatalError("*** Unable to create the workout session: \(error.localizedDescription) ***")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("session changed");
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("error")
    }
    
    func sendNotification (){
        // UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        // UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: "AWARE", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey:  "Please select what are you doing?", arguments: nil)
        content.sound = UNNotificationSound.default()

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: String(NSDate().timeIntervalSince1970), content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.add(request) { (error : Error?) in
            if error != nil {
                print("\(error.debugDescription)")
            }
        }
        print("set a notification")
    }
    
    func startDeviceMotion() {
        if motionManager.isDeviceMotionAvailable {
            self.motionManager.deviceMotionUpdateInterval = hz
            self.motionManager.startDeviceMotionUpdates()
            
            DispatchQueue.main.async {
                self.sendNotification()
            }

            // Configure a timer to fetch the accelerometer data.
            self.motionTimer = Timer(fire: Date(), interval: hz,
                               repeats: true, block: { (timer) in
                                // Get the gyro data.
                                if let data = self.motionManager.deviceMotion {
                                    // acc
                                    let timestamp = NSDate().timeIntervalSince1970*1000
                                    let accx = data.userAcceleration.x
                                    let accy = data.userAcceleration.y
                                    let accz = data.userAcceleration.z
                                    // grav
                                    // let gravx = data.gravity.x
                                    // let gravy = data.gravity.y
                                    // let gravz = data.gravity.z
                                    // gyro
                                    // let gyrox = data.rotationRate.x
                                    // let gyroy = data.rotationRate.y
                                    // let gyroz = data.rotationRate.z
                                    // mag
//                                    let magx = data.magneticField.field.x
//                                    let magy = data.magneticField.field.y
//                                    let magz = data.magneticField.field.z
//                                    let magQuality = data.magneticField.accuracy
                                    // heading
                                    // let heading = data.heading
                                    //
                                    let gyror = data.attitude.roll
                                    let gyrop = data.attitude.pitch
                                    let gyroy = data.attitude.yaw
                                    print("\(timestamp), \(accx), \(accy), \(accz)")
                                    self.awareFM.writeData(data: "\(timestamp), \(accx), \(accy), \(accz), \(gyror), \(gyrop), \(gyroy)")
                                }
            })
            
            // Add the timer to the current run loop.
            RunLoop.current.add(self.motionTimer!, forMode: .defaultRunLoopMode)
        }
    }
    
    ////////////////////
    func stopWorkoutSession(){
        healthStore.end(self.session)
    }
    
    @objc func stopDeviceMotion(){
        if motionManager.isDeviceMotionAvailable {
            motionManager.stopDeviceMotionUpdates()
            self.motionTimer.invalidate()
        }
    }
}


