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
let CharacteristicTXUUID = CBUUID(string: "0783b03e-8535-b5a0-7140-a304d2495cb8")
let CharacteristicRXUUID = CBUUID(string: "0783b03e-8535-b5a0-7140-a304d2495cba")
let CharacteristicFCUUID = CBUUID(string: "0783b03e-8535-b5a0-7140-a304d2495cb9")
let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"

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
    }

    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        // See if it was PAN1740 that disconnected
        if (peripheral == self.peripheralPAN1740) {
            self.peripheralPAN1740 = nil
        }
        self.startScanning()
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
                    self.CharacteristicTX = characteristic
                    // Implement a method to notify the app
                case CharacteristicRXUUID:
                    // This characteristic is set up to notify when value changed
                    self.CharacteristicRX = characteristic
                    self.peripheralPAN1740?.setNotifyValue(true, for: characteristic)
                case CharacteristicFCUUID:
                    self.CharacteristicFC = characteristic
                default:
                    break
                }
            }
        }

    }
    
    
    
}


