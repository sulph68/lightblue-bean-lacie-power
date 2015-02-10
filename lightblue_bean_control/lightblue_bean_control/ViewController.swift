//
//  ViewController.swift
//  lightblue_bean_control
//
//  Created by copper on 6/2/15.
//  Copyright (c) 2015 sulphate. All rights reserved.
//

import UIKit

class ViewController: UIViewController, PTDBeanManagerDelegate, PTDBeanDelegate {

    let beanManager = PTDBeanManager()
    var connectedBean: PTDBean?
    
    // Define the name of your LightBlue Bean
    let beanName = "RemoteBean"
    
    var statusTimer: NSTimer?
    
    @IBOutlet weak var statusDrawer: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var beanLabel: UILabel!
    @IBOutlet weak var batteryLevel: UILabel!
    
    @IBOutlet weak var ambientTemp: UILabel!
    @IBOutlet weak var lastDiscovered: UILabel!
    
    @IBOutlet weak var shortPress: UIButton!
    @IBOutlet weak var longPress: UIButton!
    @IBOutlet weak var flashPress: UIButton!
    
    
    let MAXVOLT: Float = 3.53
    let MINVOLT: Float = 1.95
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // init labels
        var newBounds = CGRect(x: 0, y: 40, width: UIScreen.mainScreen().bounds.size.width, height: 40)
        self.statusDrawer.bounds = newBounds
        self.statusDrawer.backgroundColor = UIColor.whiteColor()
        
        shortPress.enabled = false
        longPress.enabled = false
        flashPress.enabled = false
        
        beanManager.delegate = self;
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func beanManagerDidUpdateState(beanManager: PTDBeanManager!) {
        if (beanManager.state == BeanManagerState.PoweredOn) {
            var scanError: NSError?
            beanManager.startScanningForBeans_error(&scanError)
            blink(1, color: UIColor.yellowColor())
            if (scanError != nil) {
                printStatusLabel("Error starting scan")
            } else {
                printStatusLabel("Lightblue Bean scan started")
            }
        } else if (beanManager.state == BeanManagerState.PoweredOff) {
            printStatusLabel("Device Powered off")
        } else if (beanManager.state == BeanManagerState.Unauthorized) {
            printStatusLabel("Device Unauthorized")
        } else if (beanManager.state == BeanManagerState.Unknown) {
            printStatusLabel("Device state unknown")
        } else if (beanManager.state == BeanManagerState.Resetting) {
            printStatusLabel("Device Resetting")
        } else if (beanManager.state == BeanManagerState.Unsupported) {
            printStatusLabel("Device Unsupported")
        }
    }
    
    func BeanManager(beanManager: PTDBeanManager!, didDiscoverBean bean: PTDBean!, error: NSError!) {
        if (error == nil) {
            var connectError: NSError?
            NSLog("Found bean: \(bean.name)")
            // Connect only to defined bean
            if (bean.name == beanName) {
                NSLog("Bean Match: \(bean.name)")
                beanManager.connectToBean(bean, error: &connectError)
                if (connectError == nil) {
                    printStatusLabel("Connecting to Bean: \(bean.name)")
                }
            }
        }
    }
    
    func BeanManager(beanManager: PTDBeanManager!, didConnectToBean bean: PTDBean!, error: NSError!) {
        printStatusLabel("Connected to \(bean.name)")
        connectedBean = bean
        connectedBean!.delegate = self
        blink(1, color: UIColor.greenColor())
        populateInfo()
        shortPress.enabled = true
        longPress.enabled = true
        flashPress.enabled = true
    }
    
    func BeanManager(beanManager: PTDBeanManager!, didDisconnectBean bean: PTDBean!, error: NSError!) {
        printStatusLabel("Disconnected from Bean \(bean.name)")
        connectedBean = nil
        
        shortPress.enabled = false
        longPress.enabled = false
        flashPress.enabled = false
        
        var connectError: NSError?
        beanManager.connectToBean(bean, error: &connectError)
        if (connectError == nil) {
            printStatusLabel("Connecting to Bean: \(bean.name)")
        }
    }
    
    @IBAction func showBeanName(sender: AnyObject) {
        if (connectedBean != nil) {
            printStatusLabel(connectedBean!.name)
            populateInfo()
        } else {
            printStatusLabel("No connected Bean!")
            var scanError: NSError?
            beanManager.startScanningForBeans_error(&scanError)
            blink(1, color: UIColor.yellowColor())
            if (scanError != nil) {
                printStatusLabel("Error starting scan")
            } else {
                printStatusLabel("Bean Re-scanning")
            }
        }
    }
    
    @IBAction func sendShortPress(sender: AnyObject) {
        if (connectedBean != nil) {
            NSLog("Sending short press")
            blink(2, color: UIColor.redColor())
            connectedBean!.sendSerialString("short")
        } else {
            printStatusLabel("No connected Bean!")
        }
    }
    
    @IBAction func sendLongPress(sender: AnyObject) {
        if (connectedBean != nil) {
            NSLog("Sending long press")
            blink(10, color: UIColor.redColor())
            connectedBean!.sendSerialString("long")
        } else {
            printStatusLabel("No connected Bean!")
        }
    }
    
    @IBAction func blinkLED(sender: AnyObject) {
        if (connectedBean != nil) {
            blink(0.3, color: UIColor.redColor())
        } else {
            printStatusLabel("No connected Bean!")
        }
    }
    
    func populateInfo() {
        self.beanLabel.text = beanName
        
        if (connectedBean != nil) {
            blink(0.3, color: UIColor.blueColor())
            self.beanLabel.textColor = UIColor.blackColor()
            
            connectedBean!.readBatteryVoltage()
            connectedBean!.readTemperature()
            
            var dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .MediumStyle
            dateFormatter.timeStyle = .MediumStyle
            
            self.lastDiscovered.text = dateFormatter.stringFromDate(connectedBean!.lastDiscovered)
        } else {
            self.beanLabel.textColor = UIColor.redColor()
        }
    }
    
    func bean(bean: PTDBean!, didUpdateTemperature degrees_celsius: NSNumber!) {
        self.ambientTemp.text = "\(degrees_celsius.stringValue) Celcius"
    }
    
    func beanDidUpdateBatteryVoltage(bean: PTDBean!, error: NSError!) {
        let level = self.getBatteryLevel()
        self.batteryLevel.text = "\(level)% @ \(bean!.batteryVoltage.stringValue) Volts"
    }
    
    // Status Label functions
    
    func printStatusLabel(title: String) {
        self.statusLabel.text = title
        openStatusLabel()
    }
    
    func openStatusLabel() {
        UIView.animateWithDuration(1, animations: { () -> Void in
                var newBounds = CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.size.width, height: 40)
                self.statusDrawer.bounds = newBounds
                self.statusDrawer.backgroundColor = UIColor.lightGrayColor()
            }, completion: {(complete: Bool) in
                let selector: Selector = "closeStatusLabel"
                if (self.statusTimer != nil) {
                    self.statusTimer!.invalidate()
                }
                self.statusTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(5.0), target: self, selector: selector, userInfo: nil, repeats: false)
        })
    }

    func closeStatusLabel() {
        UIView.animateWithDuration(1, animations: { () -> Void in
                var newBounds = CGRect(x: 0, y: 40, width: UIScreen.mainScreen().bounds.size.width, height: 40)
                self.statusDrawer.bounds = newBounds
                self.statusDrawer.backgroundColor = UIColor.whiteColor()
            }
        )
    }
    
    func blink(time: Double, color: UIColor) {
        if (connectedBean != nil) {
            connectedBean!.setLedColor(color)
            clearLEDTimer(time)
        }
    }
    
    func clearLEDTimer(time: Double) {
        let selector: Selector = "clearLED"
        NSTimer.scheduledTimerWithTimeInterval(time, target: self, selector: selector, userInfo: nil, repeats: false)
    }
    
    func clearLED() {
        if (connectedBean != nil) {
            connectedBean!.setLedColor(UIColor.blackColor())
        }
    }
    
    func getBatteryLevel() -> Int {
        if (connectedBean != nil) {
            var currentVolt = connectedBean!.batteryVoltage.floatValue
            if ( currentVolt > MAXVOLT) {
                return 100
            } else {
                var value = (connectedBean!.batteryVoltage.floatValue - MINVOLT) / (MAXVOLT - MINVOLT) * 100
                return Int(value)
            }
        } else {
            return 0
        }
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Bean Alert", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let okResponse = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(okResponse)
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

