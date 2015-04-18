//
//  ViewController.swift
//  lightblue_bean_control
//
//  Created by copper on 6/2/15.
//  Copyright (c) 2015 sulphate. All rights reserved.
//

import UIKit

class ViewController: UIViewController, PTDBeanManagerDelegate, PTDBeanDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    var beanManager = PTDBeanManager()
    var connectedBean: PTDBean?
    
    // Define the name of your LightBlue Bean
    var beanName = ""
    
    var statusTimer: NSTimer?
    var connectTimer: NSTimer?
    
    @IBOutlet weak var statusDrawer: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var beanLabel: UILabel!
    @IBOutlet weak var batteryLevel: UILabel!
    @IBOutlet weak var beanPicker: UIPickerView!
    
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
        
        if (beanName == "") {
            beanName = "RemoteBean"
        }
        
        shortPress.enabled = false
        longPress.enabled = false
        flashPress.enabled = false
        
        beanManager.delegate = self
        beanPicker.delegate = self
        
        self.beanLabel.text = beanName
        self.beanLabel.textColor = UIColor.redColor()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 2
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        var name: NSString?
        if (row == 0) {
            name = "RemoteBean"
        } else if (row == 1) {
            name = "RemotePlus"
        }
        return name
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (row == 0) {
            beanName = "RemoteBean"
        } else if (row == 1) {
            beanName = "RemotePlus"
        }
        self.beanLabel.text = beanName
        // dealloc the old bean
        var dcError: NSError?
        if (connectedBean != nil) {
            self.beanManager.disconnectBean(connectedBean!, error: &dcError)
            connectedBean = nil
        }
        if (dcError != nil) {
            printStatusLabel("Error disconnecting \(beanName)")
        } else {
            // Perform a rescan on a reselection of picker view
            startScanBeans()
        }
    }
    
    func beanManagerDidUpdateState(beanManager: PTDBeanManager!) {
        if (beanManager.state == BeanManagerState.PoweredOn) {
            startScanBeans()
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
                    beanManager.stopScanningForBeans_error(&connectError)
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
    }
    
    func startScanBeans() {
        var scanError: NSError?
        beanManager.startScanningForBeans_error(&scanError)
        blink(1, color: UIColor.yellowColor())
        if (scanError != nil) {
            printStatusLabel("Error starting scan")
        } else {
            printStatusLabel("Re-scanning for \(beanName)")

            let selector: Selector = "stopScanBeans"
            if (self.connectTimer != nil) {
                self.connectTimer!.invalidate()
            }
            self.connectTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(120.0), target: self, selector: selector, userInfo: nil, repeats: false)
            
        }
    }
    
    func stopScanBeans() {
        self.beanLabel.text = beanName
        if (connectedBean? == nil) {
            showAlert("Cannot find \(beanName) after 2 minutes. Refresh to try again.")
            self.beanLabel.textColor = UIColor.redColor()
        }
        var dcError: NSError?
        beanManager.stopScanningForBeans_error(&dcError)
    }
    
    
    @IBAction func showBeanName(sender: AnyObject) {
        // Perform a rescan on a reselection of picker view
        var scanError: NSError?
        NSLog("Current Selected: \(beanPicker.selectedRowInComponent(0))")
        if (beanPicker.selectedRowInComponent(0) == 0) {
            beanName = "RemoteBean"
        } else {
            beanName = "RemotePlus"
        }
        if (connectedBean != nil && connectedBean!.name == beanName) {
            printStatusLabel(connectedBean!.name)
            populateInfo()
        } else {
            printStatusLabel("No connected Bean!")
            startScanBeans()
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
        
        if (connectedBean != nil && connectedBean!.name == beanName) {
            
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

