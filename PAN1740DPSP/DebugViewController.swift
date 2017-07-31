//
//  ViewController.swift
//  PAN1740DPSP
//
//  Created by Michael Chan on 3/16/17.
//  Copyright © 2017 com.UCLABiomimeticLab. All rights reserved.
//

import UIKit
import Charts

class liveSignal {
    var window_counter = 0
    var lineChartView: LineChartView!
    var dataSet: LineChartDataSet!
}


class DebugViewController: UIViewController, UITextFieldDelegate{
    
    // BLE variables
    var myBLE: BLEService!
    var BLEconnectTimeout: Timer!
    var myTimer: Timer!
    var SlicedBuffer: [UInt8] = []
    
    // Graph size (pixels)
    let GraphWindowSize = 300 // Can draw 5 beat cycle
    var ECGWindow_counter = 0
    var RedWindow_counter = 0
    
    // ECG Wave Parameters
    let ECGsize = 100
    
    // Chart variables
    
    
    @IBOutlet weak var ECGLineChartView: LineChartView!
    
    @IBOutlet weak var RedLineChartView: LineChartView!
    
    @IBOutlet weak var IRLineChartView: LineChartView!
    
    @IBOutlet weak var RespLineChartView: LineChartView!
    
    var ECGsignal = liveSignal()
    var Redsignal = liveSignal()
    var IRsignal = liveSignal()
    var Respsignal = liveSignal()
    
    var ECGDataSet = LineChartDataSet()
    
    var RedDataSet = LineChartDataSet()
    
    var IRDataSet = LineChartDataSet()
    
    var RespDataSet = LineChartDataSet()


    
    // Sine Wave Timer
    var timeLeft = 1000
    var TotalTime = 1000
    var dataTimer: Timer!
    

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
        }
        else {
            print("Enter someting in textfield")
        }
    }
    
    @IBOutlet weak var sendTextButton: UIButton!
    
    
    

    
    
    @IBOutlet weak var termInputTextField: UITextField!
    

//    @IBOutlet weak var PPGLabel: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(DebugViewController.notificationHandler(_:)), name: NSNotification.Name(rawValue: "RXUpdatedNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DebugViewController.notificationHandler(_:)), name: NSNotification.Name(rawValue: "BLEConnectNotification"), object: nil)
        
        
        
        // Produce fake ECG data
        var defaultECG = [Double]()
        var i = 1
        while i <= GraphWindowSize/ECGdata.count {
            defaultECG = defaultECG + ECGdata
            i = i + 1
        }
        


        ECGDataSet = initializeChart(thisChartView: ECGLineChartView, defaultData: defaultECG)
        ECGsignal.window_counter = 0
        ECGsignal.dataSet = ECGDataSet
        ECGsignal.lineChartView = ECGLineChartView
        
        RedDataSet = initializeChart(thisChartView: RedLineChartView, defaultData: defaultECG)
        Redsignal.window_counter = 0
        Redsignal.dataSet = RedDataSet
        Redsignal.lineChartView = RedLineChartView

        IRDataSet = initializeChart(thisChartView: IRLineChartView, defaultData: defaultECG)
        IRsignal.window_counter = 0
        IRsignal.dataSet = IRDataSet
        IRsignal.lineChartView = IRLineChartView

        
        RespDataSet = initializeChart(thisChartView: RespLineChartView, defaultData: defaultECG)
        Respsignal.window_counter = 0
        Respsignal.dataSet = RespDataSet
        Respsignal.lineChartView = RespLineChartView

        
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
                        
//                        print(myData.count % 3)
                        if myData.count % 3 != 0 {
                            let a = myData.count
                        }
                        
                        if SlicedBuffer.count != 0 {
                            byte.insert(contentsOf: SlicedBuffer, at: 0)
                            SlicedBuffer.removeAll()
                        }


                        
                        let loopcount = byte.count/3-1
                        
                        var i = 0
                        while i < byte.count/3 {
                            
                            
                            let rawBytes : [UInt8] = [byte[i*3+1],byte[i*3+2]]
//                            var RawData : Int16 = 0
//                            let DATA = NSData(bytes: rawBytes, length: 2)
//                            DATA.getBytes(&RawData, length: 2)
//                            RawData = Int16(bigEndian: RawData)
                            
                            UpdateChart(header: UInt8(byte[i*3]), rawData: rawBytes)

                            
//                            UpdateChart(header: UInt8(byte[i*3]), rawData: UInt16(byte[i*3+1]) << 8 + UInt16(byte[i*3+2]))
                            
//                            let header = UInt8(byte[i*3])
//                            let rawECG = UInt16(byte[i*3+1]) << 8 + UInt16(byte[i*3+2])
//                            if header == 0x01 {
//                                ECGLineChartUpdate(ECGdata: rawECG)
//                            } else if header == 0x02 {
//                                RedLineChartUpdate(ECGdata: rawECG)
//                            } else if header == 0x03 {
//                                
//                            } else if header == 0x04 {
//                                
//                            }
                            i = i + 1
                        }
                        

                        if byte.count % 3 != 0  {
                            SlicedBuffer.append(contentsOf: byte[(loopcount+1)*3...byte.endIndex-1])
                        }


//                            

                            

                        
                    } else {
//                        print(myData.count)
                    }
                    

                    
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
    func setChart(TheChartView: LineChartView, values: [Double]) -> LineChartDataSet
    {
        
        var dataEntries: [ChartDataEntry] = []
        // 1 - creating an array of data entries (e.g. an array of ECG data)
        for i in 0..<values.count {
            let dataEntry = ChartDataEntry(x: Double(i), y: values[i]) // Specify the time (x) and value (y)
            dataEntries.append(dataEntry)
        } // A dataEntries will be ready by the end of the arry (similar to TS in matlab)
        
        // 2 - create a data set with our array, the DataSet is used to modify the appearance also
        let lineChartDataSet = LineChartDataSet(values: dataEntries, label: "")
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

            if ECGWindow_counter == GraphWindowSize {
                ECGWindow_counter = 0
            }
            
            let dataEntry1 = ChartDataEntry(x: Double(ECGWindow_counter), y: Double(ECGdata))
            
            ECGLineChartView.data?.removeEntry(xValue: Double(ECGWindow_counter), dataSetIndex: 0)
            ECGDataSet.addEntryOrdered(dataEntry1)
            ECGLineChartView.notifyDataSetChanged() //Need this every time you update Chart!
            ECGLineChartView.setNeedsDisplay()
            ECGLineChartView.chartDescription?.text = "Time Elapsed: \(TotalTime - timeLeft)"

            ECGWindow_counter = ECGWindow_counter + 1
        
        }
    }
    
    func RedLineChartUpdate(ECGdata: UInt16) {
        
        if PlayPauseToggle == true {
            
            if RedWindow_counter == GraphWindowSize {
                RedWindow_counter = 0
            }
            
            let dataEntry1 = ChartDataEntry(x: Double(RedWindow_counter), y: Double(ECGdata))
            
            RedLineChartView.data?.removeEntry(xValue: Double(RedWindow_counter), dataSetIndex: 0)
            RedDataSet.addEntryOrdered(dataEntry1)
            RedLineChartView.notifyDataSetChanged() //Need this every time you update Chart!
            RedLineChartView.setNeedsDisplay()
            RedLineChartView.chartDescription?.text = "Time Elapsed: \(TotalTime - timeLeft)"
            
            RedWindow_counter = RedWindow_counter + 1
            
        }
    }
    
    
    func UpdateChart (header: UInt8, rawData: [UInt8]) {
        if PlayPauseToggle == true {

            var thisSignal = liveSignal()
            var PlotData: Double = 0

//            var finalData: Int = 0

            
            if header == 0x01 {
                thisSignal = Respsignal
                
                var RawData : Int16 = 0
                let DATA = NSData(bytes: rawData, length: 2)
                DATA.getBytes(&RawData, length: 2)
                RawData = Int16(bigEndian: RawData)
                PlotData = Double(RawData)
            } else if header == 0x02 {
                thisSignal = ECGsignal
                
                var RawData : Int16 = 0
                let DATA = NSData(bytes: rawData, length: 2)
                DATA.getBytes(&RawData, length: 2)
                RawData = Int16(bigEndian: RawData)
                PlotData = Double(RawData)
            } else if header == 0x03 {
                thisSignal = Redsignal
                
                var RawData : UInt16 = 0
                let DATA = NSData(bytes: rawData, length: 2)
                DATA.getBytes(&RawData, length: 2)
                RawData = UInt16(bigEndian: RawData)
                PlotData = Double(RawData)
            } else if header == 0x04 {
                thisSignal = IRsignal
                
                var RawData : UInt16 = 0
                let DATA = NSData(bytes: rawData, length: 2)
                DATA.getBytes(&RawData, length: 2)
                RawData = UInt16(bigEndian: RawData)
                PlotData = Double(RawData)
            }
            
            print(PlotData)
            
            let thisView = thisSignal.lineChartView
            let thisCounter = thisSignal.window_counter
            let thisDataSet = thisSignal.dataSet
            
            if thisCounter == GraphWindowSize {
                thisSignal.window_counter = 0
            }
            
            let dataEntry1 = ChartDataEntry(x: Double(thisCounter), y: Double(PlotData))
            
            thisView?.data?.removeEntry(xValue: Double(thisCounter), dataSetIndex: 0)
            thisDataSet?.addEntryOrdered(dataEntry1)
            thisView?.notifyDataSetChanged() //Need this every time you update Chart!
            thisView?.setNeedsDisplay()
//            thisView.chartDescription?.text = "Time Elapsed: \(TotalTime - timeLeft)"
            
            thisSignal.window_counter = thisSignal.window_counter + 1
            
        }
    }
    
//    func UpdateChartInt()

    
    func takeScreenshot(view: UIView) {
        UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 0.0)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
    }
    

    func initializeChart (thisChartView: LineChartView, defaultData: [Double]) -> LineChartDataSet {
        // ECG Line Chart Configuration
        
        thisChartView.noDataText = "You need to provide data for the chart."
        thisChartView.chartDescription?.text = "Tap node for details"
        thisChartView.chartDescription?.position = CGPoint(x: 320.0, y: 168.0)
        thisChartView.chartDescription?.textColor = UIColor.black
        thisChartView.drawGridBackgroundEnabled = true
        thisChartView.gridBackgroundColor = UIColor.white
        thisChartView.borderLineWidth = 0.0
        thisChartView.drawBordersEnabled = false
        thisChartView.borderColor = .clear
        thisChartView.highlightPerTapEnabled = true
        
        thisChartView.noDataText = "You need to provide data for the chart."
        
        
        let ChartXaxis = thisChartView.xAxis
        ChartXaxis.labelPosition = .bottom
        ChartXaxis.labelFont = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 8.0)!
        ChartXaxis.labelTextColor = .black
        ChartXaxis.axisMaximum = Double(GraphWindowSize + 10)
        ChartXaxis.gridColor = UIColor(red: (239/255.0), green: (239/255.0), blue: (239/255.0), alpha: (1.0)) //alpha defines transparency
        //        ECGxaxis.drawLimitLinesBehindDataEnabled = true
        
        let ChartYaxis = thisChartView.leftAxis
        ChartYaxis.labelPosition = .outsideChart
        ChartYaxis.labelFont = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 8.0)!
        ChartYaxis.labelTextColor = .black
        ChartYaxis.gridColor = UIColor(red: (239/255.0), green: (239/255.0), blue: (239/255.0), alpha: (1.0)) //alpha defines transparency
        ChartYaxis.drawBottomYLabelEntryEnabled = false
        
        thisChartView.rightAxis.enabled = false
        
        let thisDataSet = setChart(TheChartView: thisChartView, values: defaultData)

        return thisDataSet
    }
    

}

