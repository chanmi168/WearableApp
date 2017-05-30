//
//  BLEService.swift
//  PAN1740DPSP
//
//  Created by Michael Chan on 3/16/17.
//  Copyright © 2017 com.UCLABiomimeticLab. All rights reserved.
//


import Foundation
import CoreBluetooth


// Services & Characteristics UUIDs, can be found on UM-B-038 //
let ServiceDSPSUUID = CBUUID(string: "0783b03e-8535-b5a0-7140-a304d2495cb7")
let CharacteristicTXUUID = CBUUID(string: "0783b03e-8535-b5a0-7140-a304d2495cba") // RX of PAN1740
let CharacteristicRXUUID = CBUUID(string: "0783b03e-8535-b5a0-7140-a304d2495cb8") // TX of PAN1740
let CharacteristicFCUUID = CBUUID(string: "0783b03e-8535-b5a0-7140-a304d2495cb9")
let BLEServiceChangedStatusNotification = "BLEServiceChangedStatusNotification"

//let btDiscoverySharedInstance = BTDiscovery();


class BLEService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager?
    var peripheralPAN1740: CBPeripheral?
    var CharacteristicTX: CBCharacteristic?
    var CharacteristicRX: CBCharacteristic?
    var CharacteristicFC: CBCharacteristic?
    
    
    override init() {
        super.init()
        
        // Assign central manager queue to the right thread
        let serialCentralQueue = DispatchQueue(label: "com.mindcontrol")
        centralManager = CBCentralManager(delegate: self, queue: serialCentralQueue)
    }

    
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .poweredOff:
            clearDevices()
        case .unauthorized:
            // Tell the user that the iOS device does not support BLE.
            break
        case .unknown:
            // Wait for another event
            break
        case .poweredOn:
            self.startScanning()
        case .resetting:
            self.clearDevices()
            
        case .unsupported:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Be sure to retain the peripheral or it will fail during connection.
        
        // Validate peripheral information
        if ((peripheral.name == nil) || (peripheral.name == "")) {
            return
        }
        
        // If not already connected to a peripheral, then connect to this one
        if ((peripheralPAN1740 == nil) || (peripheralPAN1740?.state == .disconnected)) {

            // Retain the peripheral before trying to connect
            peripheralPAN1740 = peripheral
            peripheralPAN1740?.delegate = self
            // Connect to peripheral
            centralManager?.connect(peripheral, options: nil)
            
        }

    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to Peripherial, Yay!")
        print("Now start discovering services")
        peripheral.discoverServices([ServiceDSPSUUID]) // Expect to call didDiscoverService when found
        centralManager?.stopScan()
        
        let connectWrapped:[String: Int] = ["status": 1]
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "BLEConnectNotification"), object: nil, userInfo: connectWrapped)
        }
    }

    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        // See if it was PAN1740 that disconnected
        if (peripheral == self.peripheralPAN1740) {
            self.peripheralPAN1740 = nil
        }
        let connectWrapped:[String: Int] = ["status": 0]
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "BLEConnectNotification"), object: nil, userInfo: connectWrapped)
        }
        // Don't scan unless the user prompt
//        self.startScanning()
    }

    
    // Private functions I made to perform BLE work
    
    // This function scans for peripheral with DSPSServiceUUID
    func startScanning () {
        if let central = centralManager {
            central.scanForPeripherals(withServices: [ServiceDSPSUUID], options: nil)
        }
    }
    
    // This function clears peripheralPAN1740 in this class
    func clearDevices() {
        peripheralPAN1740 = nil
    }
    
    
    // Mark: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let uuidsForDSPSService: [CBUUID] = [CharacteristicTXUUID, CharacteristicRXUUID, CharacteristicFCUUID]
        
        if (peripheral != self.peripheralPAN1740) {
            // Wrong Peripheral, do nothing
            return
        }
        
        if (error != nil) {
            return
        }
        
        if ((peripheral.services == nil) || (peripheral.services!.count == 0)) {
            // No Services
            return
        }
        
        for service in peripheral.services! {
            if service.uuid == ServiceDSPSUUID {
                peripheral.discoverCharacteristics(uuidsForDSPSService, for: service)
            }
        }
    }
    

    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (peripheral != self.peripheralPAN1740) {
            // Wrong Peripheral
            return
        }
        
        if (error != nil) {
            // Can be used for debugging
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                switch characteristic.uuid {
                case CharacteristicTXUUID:
                    print("Found TX")
                    CharacteristicTX = characteristic
                    peripheralPAN1740?.setNotifyValue(true, for: characteristic)
                case CharacteristicRXUUID:
                    // This characteristic is set up to notify when value changed
                    print("Found RX")
                    CharacteristicRX = characteristic
                    peripheralPAN1740?.setNotifyValue(true, for: characteristic)
                case CharacteristicFCUUID:
                    print("Found FC")
                    CharacteristicFC = characteristic
                    peripheralPAN1740?.setNotifyValue(true, for: characteristic)
                default:
                    break
                }
            }
        }

    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("[ERROR] Error updating value. \(error!.localizedDescription)")
            return
        }
        if characteristic.uuid == CharacteristicTXUUID {
                        print("TX updated")
            // Decode the bytes here
//            var data: NSData = characteristic.value! as NSData
//            var dataArray = [CUnsignedChar](repeating: CUnsignedChar(), count: 20)
//            var len: Int = 0
//            data.getBytes(&dataArray, length: 3)
//            translatedata(dataArray, length: data.length)
        }
        if characteristic.uuid == CharacteristicFCUUID {
            let data: NSData = characteristic.value! as NSData
            var dataArray = [UInt8](repeating: 0, count: 20)
            data.getBytes(&dataArray, length: 1)
            print("Flow control updated")
            
        }
        if characteristic.uuid == CharacteristicRXUUID {
//            let data: NSData = characteristic.value! as NSData
//            var dataArray = [UInt8](repeating: 0, count: 20)
//            data.getBytes(&dataArray, length: 5)
            
            let data = characteristic.value! as Data
//            print("RX updated")
            let dataArrayWrapped:[String: Data] = ["rawData": data]
            
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RXUpdatedNotification"), object: nil, userInfo: dataArrayWrapped)
            }
        }
        
    }
    
    

    
    func writeText(cmd: String) {
        let textBuffer = [UInt8](cmd.utf8)
        
        let buf: [UInt8] = [0x41, 0x43, 0x44]
        let XON: [UInt8] = [0x01]
        let XOFF: [UInt8] = [0x02]
        let data: NSData = NSData(bytes: textBuffer, length: textBuffer.count)
        let dataXON: NSData = NSData(bytes: XON, length: 1)
        let dataXOFF: NSData = NSData(bytes: XOFF, length: 1)
        peripheralPAN1740?.writeValue(data as Data, for: CharacteristicTX!, type: .withoutResponse)
        peripheralPAN1740?.writeValue(dataXOFF as Data, for: CharacteristicFC!, type: .withoutResponse)
        peripheralPAN1740?.writeValue(dataXON as Data, for: CharacteristicFC!, type: .withoutResponse)
    }
    
    
    
    
    func disconnect() {
        
        // 1 - verify we have a peripheral
        guard let peripheral = self.peripheralPAN1740 else {
            print("No peripheral available to cleanup.")
            return
        }
        
        // 2 - Don't do anything if we're not connected
        if peripheral.state != .connected {
            print("Peripheral is not connected.")
            self.peripheralPAN1740 = nil
            return
        }
        
        // 3
        guard let services = peripheral.services else {
            // disconnect directly
            centralManager?.cancelPeripheralConnection(peripheral)
            return
        }
        
        // 4 - iterate through services
        for service in services {
            // iterate through characteristics
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    // find the all characteristics
                    switch characteristic.uuid {
                    case CharacteristicTXUUID:
                        peripheral.setNotifyValue(false, for: characteristic)
                    case CharacteristicRXUUID:
                        peripheral.setNotifyValue(false, for: characteristic)
                    case CharacteristicFCUUID:
                        peripheral.setNotifyValue(false, for: characteristic)
                    default:
                        break
                    }

                }
            }
        } 
        
        // 6 - disconnect from peripheral
        centralManager?.cancelPeripheralConnection(peripheral)
    }
    
    
    
    
    
}


