//
//  ViewController.swift
//  PAN1740DPSP
//
//  Created by Michael Chan on 3/16/17.
//  Copyright © 2017 com.UCLABiomimeticLab. All rights reserved.
//

import UIKit
import Charts

class DebugViewController: UIViewController, UITextFieldDelegate{
    
    // BLE variables
    var myBLE: BLEService!
    var BLEconnectTimeout: Timer!
    var myTimer: Timer!
    var myECG: String!
    var myPPG: String!
    
    var ECGorRedToggle = false // ECG first
    
    // Sine Wave parameters
    let sineArraySize = 1000
    let frequency1 = 5.0
    let frequency2 = 10.0
    let phase = [0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 18.0]
    let amplitude1 = 2.0
    var sineWave1: [Double] = []
    var sineWave2: [Double] = []
    var toggleState = 1
    
    // Graph size (pixels)
    let GraphWindowSize = 500 // Can draw 5 beat cycle
    var GraphWindow_counter = 0
    
    // ECG Wave Parameters
    let ECGsize = 100
    var ECG_counter = 20
    
    // Chart variables
    var ECGDataSet = LineChartDataSet()
//    var PPGDataSet = LineChartDataSet()
    var ECGxaxis: XAxis!
    var ECGyaxis: YAxis!
    
    var RedDataSet = LineChartDataSet()
    var Redxaxis: XAxis!
    var Redyaxis: YAxis!
    
    // Sine Wave Timer
    var timeLeft = 1000
    var TotalTime = 1000
    var dataTimer: Timer!
    
//    weak var delegate: ChartViewDelegate?
    
    @IBOutlet weak var HighLightedLabel: UILabel!
    // Control Panel parameters
    var PlayPauseToggle: Bool = false {
        // false = puasing, true = playing
        didSet {
            if PlayPauseToggle == true {
                PlayPauseButton.setImage(UIImage(named: "PauseButton"), for: .normal)
            } else {
                PlayPauseButton.setImage(UIImage(named: "PlayButton"), for: .normal)
            }
        }
    }

    
    @IBOutlet weak var ECGLineChartView: LineChartView!
    
    @IBOutlet weak var RedLineChartView: LineChartView!
//    @IBOutlet weak var PPGLineChartView: LineChartView!
    
    @IBOutlet weak var PlayPauseButton: UIButton!
    @IBAction func PlayPauseButton(_ sender: Any) {
        if PlayPauseToggle == true {
            // Want to pause
            PlayPauseToggle = false
            myBLE.writeText(cmd: "stop")

//            if dataTimer == nil {
//            dataTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(DebugViewController.ECGLineChartUpdate), userInfo: nil, repeats: true)
//            }
            
        } else {
            // Want to play
            PlayPauseToggle = true
            myBLE.writeText(cmd: "begin")

//            if dataTimer != nil {
//                dataTimer.invalidate()
//            }
//            dataTimer = nil
        }

//        if PlayPauseButton.backgroundImage(for: .normal)
//        PlayPauseButton.setImage(UIImage(named: "PlayButton"), for: .normal)
    }
    
    
    @IBOutlet weak var ScreenShotButton: UIButton!
    
    @IBAction func ScreenShotButton(_ sender: Any) {
        takeScreenshot(view: self.view)
    }
    
    
    @IBOutlet weak var cmdTextField: UITextField!

    @IBAction func connectSwitch(_ sender: Any) {
        if connectSwitch.isOn == true {
            if myBLE == nil {
                myBLE = BLEService() // Create a BLE variable to handle BLE connection and communication
            } else {
                myBLE.startScanning()
            }
            if BLEconnectTimeout == nil {
                BLEconnectTimeout = Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(DebugViewController.connectTimerEnd), userInfo: nil, repeats: true)
            }
        } else {
            myBLE.disconnect()
        }
    }
    
    func connectTimerEnd () {
        if myBLE.peripheralPAN1740 == nil {
            connectSwitch.isOn = false
        }
//        self.view.addSubview(connectWarningView)
//        var warningTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: <#T##Selector#>, userInfo: <#T##Any?#>, repeats: <#T##Bool#>)
        BLEconnectTimeout.invalidate()
        BLEconnectTimeout = nil
    }
    
    @IBOutlet var connectWarningView: UIView!
    @IBOutlet weak var connectSwitch: UISwitch!
    
    
    @IBAction func sendTextButton(_ sender: Any) {
        
        if let text = termInputTextField.text, !text.isEmpty {
            myBLE.writeText(cmd: text)
//            sendTextButton.setTitle("Stop", for: .normal)
//            myTimer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(timerCode), userInfo: nil, repeats: true)
        }
        else {
            print("Enter someting in textfield")
        }
//        if sendTextButton.titleLabel?.text == "Send Command" {
//            
//            if myTimer == nil {
//                if let text = termInputTextField.text, !text.isEmpty {
//                    sendTextButton.setTitle("Stop", for: .normal)
//                    myTimer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(timerCode), userInfo: nil, repeats: true)
//                }
//                else {
//                    print("Enter someting in textfield")
//                }
//            }
//        }
//        else if sendTextButton.titleLabel?.text == "Stop" {
//            sendTextButton.setTitle("Send Command", for: .normal)
//            myTimer.invalidate()
//            myTimer = nil
//        }
        
    }
    
    @IBOutlet weak var sendTextButton: UIButton!
    
    
    
    func timerCode() {
//        let text = termInputTextField.text
        myBLE.writeText(cmd: "hello")
    }
    
    
    @IBOutlet weak var termInputTextField: UITextField!
    
    @IBOutlet weak var RxLabel: UILabel!

//    @IBOutlet weak var PPGLabel: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(DebugViewController.notificationHandler(_:)), name: NSNotification.Name(rawValue: "RXUpdatedNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DebugViewController.notificationHandler(_:)), name: NSNotification.Name(rawValue: "BLEConnectNotification"), object: nil)
        
        
        
        
        // ECG Line Chart Configuration 
        
        ECGLineChartView.noDataText = "You need to provide data for the chart."
        ECGLineChartView.chartDescription?.text = "Tap node for details"
        ECGLineChartView.chartDescription?.position = CGPoint(x: 320.0, y: 168.0)
        ECGLineChartView.chartDescription?.textColor = UIColor.black
        ECGLineChartView.drawGridBackgroundEnabled = true
        ECGLineChartView.gridBackgroundColor = UIColor.white
        ECGLineChartView.borderLineWidth = 0.0
        ECGLineChartView.drawBordersEnabled = false
        ECGLineChartView.borderColor = .clear
        ECGLineChartView.highlightPerTapEnabled = true
        
//        ECGLineChartView.borderColor = UIColor(red: (50.0/255.0), green: (50.0/255.0), blue: (50.0/255.0), alpha: (0.5))
        ECGLineChartView.noDataText = "You need to provide data for the chart."
        sineWave1 = (0..<sineArraySize).map {
            amplitude1 * sin(2.0 * Double.pi / Double(sineArraySize) * Double($0) * frequency1 + phase[8])
        }
        sineWave2 = (0..<sineArraySize).map {
            amplitude1 * sin(2.0 * Double.pi / Double(sineArraySize) * Double($0) * frequency2 + phase[3])
        }
        
        ECGxaxis = ECGLineChartView.xAxis
        ECGxaxis.labelPosition = .bottom
        ECGxaxis.labelFont = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 8.0)!
        ECGxaxis.labelTextColor = .black
        ECGxaxis.axisMaximum = Double(GraphWindowSize + 10)
        ECGxaxis.gridColor = UIColor(red: (239/255.0), green: (239/255.0), blue: (239/255.0), alpha: (1.0)) //alpha defines transparency
//        ECGxaxis.drawLimitLinesBehindDataEnabled = true
        
        ECGyaxis = ECGLineChartView.leftAxis
        ECGyaxis.labelPosition = .outsideChart
        ECGyaxis.labelFont = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 8.0)!
        ECGyaxis.labelTextColor = .black
        ECGyaxis.gridColor = UIColor(red: (239/255.0), green: (239/255.0), blue: (239/255.0), alpha: (1.0)) //alpha defines transparency
        ECGyaxis.drawBottomYLabelEntryEnabled = false
        
        ECGLineChartView.rightAxis.enabled = false
    
        ECGDataSet = setChart(TheChartView: ECGLineChartView, values: ECGdata + ECGdata + ECGdata + ECGdata + ECGdata)

        
        
        
        // ECG Line Chart Configuration
        
        RedLineChartView.noDataText = "You need to provide data for the chart."
        RedLineChartView.chartDescription?.text = "Tap node for details"
        RedLineChartView.chartDescription?.position = CGPoint(x: 320.0, y: 168.0)
        RedLineChartView.chartDescription?.textColor = UIColor.black
        RedLineChartView.drawGridBackgroundEnabled = true
        RedLineChartView.gridBackgroundColor = UIColor.white
        RedLineChartView.borderLineWidth = 0.0
        RedLineChartView.drawBordersEnabled = false
        RedLineChartView.borderColor = .clear
        RedLineChartView.highlightPerTapEnabled = true
        
        RedLineChartView.noDataText = "You need to provide data for the chart."
       
        
        Redxaxis = ECGLineChartView.xAxis
        Redxaxis.labelPosition = .bottom
        Redxaxis.labelFont = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 8.0)!
        Redxaxis.labelTextColor = .black
        Redxaxis.axisMaximum = Double(GraphWindowSize + 10)
        Redxaxis.gridColor = UIColor(red: (239/255.0), green: (239/255.0), blue: (239/255.0), alpha: (1.0)) //alpha defines transparency
        //        ECGxaxis.drawLimitLinesBehindDataEnabled = true
        
        Redyaxis = ECGLineChartView.leftAxis
        Redyaxis.labelPosition = .outsideChart
        Redyaxis.labelFont = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 8.0)!
        Redyaxis.labelTextColor = .black
        Redyaxis.gridColor = UIColor(red: (239/255.0), green: (239/255.0), blue: (239/255.0), alpha: (1.0)) //alpha defines transparency
        Redyaxis.drawBottomYLabelEntryEnabled = false
        
        RedLineChartView.rightAxis.enabled = false
        
        RedDataSet = setChart(TheChartView: RedLineChartView, values: ECGdata + ECGdata + ECGdata + ECGdata + ECGdata)
        
        
        
        
        

        self.navigationController?.isNavigationBarHidden = true
        
        // Text field configuration
        self.cmdTextField.delegate = self
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(self.view.endEditing(_:))))
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Text Field delegation
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    
    
//    func endEditing() {
//        cmdTextField.resignFirstResponder()
////        self.view.endEditing(true)
//    }

    // Dealing with BLE
    func notificationHandler (_ notification: NSNotification) {
        
        switch notification.name.rawValue {
            case "RXUpdatedNotification":
                if let myData = notification.userInfo?["rawData"] as? Data {
                    if myData.count < 20*7+1 && myData.count > 0 { //Sometimes. Come back later Michael!
                        var byte = [UInt8](repeating:0, count: myData.count)
                        myData.copyBytes(to: &byte, count: myData.count)
                        
//                        if myData.count < 10 {
//                            let aaa = byte
//                        }
                        
                        for i in 0...byte.count/2-1 {
                            let rawECG = UInt16(byte[i*2]) << 8 + UInt16(byte[i*2+1])
                            print(rawECG)
                            myECG = String(rawECG)
                            ECGLineChartUpdate(ECGdata: rawECG)
//                            
//                            if ECGorRedToggle == true{
//                                RedLineChartUpdate(ECGdata: rawECG)
//                                ECGorRedToggle = false
//                            }
//                            else {
//                                ECGLineChartUpdate(ECGdata: rawECG)
//                                ECGorRedToggle = true
//                            }
                            

                        }
                    } else {
                        print(myData.count)
                    }
                    

                        RxLabel.text = myECG
//                        PPGLabel.text = myPPG
                    
                }
            case "BLEConnectNotification":
                let connectChange = notification.userInfo?["status"] as! Int
                if connectChange == 0 {
                    connectSwitch.isOn = false
                }
//                    connectSwitch.isOn = true
//                } else if connectChange == 0 {
//                    connectSwitch.isOn = false
//                }
                break
//                switch connectChange
//
        default:
            break
            
        }
    }
    
    
    // Dealing with live plot
    func setChart(TheChartView: LineChartView, values: [Double]) -> LineChartDataSet {
        
        var dataEntries: [ChartDataEntry] = []
        // 1 - creating an array of data entries (e.g. an array of ECG data)
        for i in 0..<values.count {
            let dataEntry = ChartDataEntry(x: Double(i), y: values[i]) // Specify the time (x) and value (y)
            dataEntries.append(dataEntry)
        } // A dataEntries will be ready by the end of the arry (similar to TS in matlab)
        
        // 2 - create a data set with our array, the DataSet is used to modify the appearance also
        let lineChartDataSet = LineChartDataSet(values: dataEntries, label: "Real-Time ECG")
//        let lineChartDataSet = LineChartDataSet(values: dataEntries, label: "Voltage (mV)")
        lineChartDataSet.axisDependency = .left
        lineChartDataSet.setColor(UIColor(red: (0.0/255.0), green: (102/255.0), blue: (204/255.0), alpha: (0.8))) //alpha defines transparency
        lineChartDataSet.lineWidth = 2.0 //2.0
        lineChartDataSet.circleRadius = 0
        lineChartDataSet.fillAlpha = 255.0/255.0
        lineChartDataSet.fillColor = UIColor.blue
        lineChartDataSet.highlightColor = UIColor.red
        lineChartDataSet.drawCircleHoleEnabled = false
        lineChartDataSet.drawValuesEnabled = false
//        lineChartDataSet.drawIconsEnabled = false
//        lineChartDataSet.drawValuesEnabled = false
        
        //3 - create an array to store our LineChartDataSets. Do this because we could have "line array"
        var dataSets : [LineChartDataSet] = [LineChartDataSet]()
        dataSets.append(lineChartDataSet)
        
        //4 - pass our DataSet into LineChartData
        let lineChartData = LineChartData(dataSets: dataSets) // Line Chart Data can have "line array"
//        lineChartData.setValueTextColor(UIColor.white) //white color for value on the point
        //5 - finally set our data
        TheChartView.data = lineChartData
        
        return lineChartDataSet
        
    }
    

    func ECGLineChartUpdate(ECGdata: UInt16) {

        if PlayPauseToggle == true {

            if GraphWindow_counter == GraphWindowSize {
                GraphWindow_counter = 0
            }
            
            let dataEntry1 = ChartDataEntry(x: Double(GraphWindow_counter), y: Double(ECGdata))
            
            ECGLineChartView.data?.removeEntry(xValue: Double(GraphWindow_counter), dataSetIndex: 0)
            ECGDataSet.addEntryOrdered(dataEntry1)
            ECGLineChartView.notifyDataSetChanged() //Need this every time you update Chart!
            ECGLineChartView.setNeedsDisplay()
            ECGLineChartView.chartDescription?.text = "Time Elapsed: \(TotalTime - timeLeft)"

            ECG_counter = ECG_counter + 1
            GraphWindow_counter = GraphWindow_counter + 1
        
        }
    }
    
    func RedLineChartUpdate(ECGdata: UInt16) {
        
        if PlayPauseToggle == true {
            
            if GraphWindow_counter == GraphWindowSize {
                GraphWindow_counter = 0
            }
            
            let dataEntry1 = ChartDataEntry(x: Double(GraphWindow_counter), y: Double(ECGdata))
            
            RedLineChartView.data?.removeEntry(xValue: Double(GraphWindow_counter), dataSetIndex: 0)
            RedDataSet.addEntryOrdered(dataEntry1)
            RedLineChartView.notifyDataSetChanged() //Need this every time you update Chart!
            RedLineChartView.setNeedsDisplay()
            RedLineChartView.chartDescription?.text = "Time Elapsed: \(TotalTime - timeLeft)"
            
            ECG_counter = ECG_counter + 1
            GraphWindow_counter = GraphWindow_counter + 1
            
        }
    }
    
    
    

    
    func takeScreenshot(view: UIView) {
        UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 0.0)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
    }
    
//    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
//        var highlightText = "Selected Point = ("
//        let thisX = entry.x
//        let thisY = entry.y
//        highlightText.append(String(thisX))
//        highlightText.append(", ")
//        highlightText.append(String(thisY))
//        HighLightedLabel.text = highlightText
//
//    }
    
    

}

