//
//  BLEManager.swift
//  BLEDump
//
//  Created by ooba on 27/07/2017.
//  Copyright © 2017 bricklife.com. All rights reserved.
//

import Cocoa
import CoreBluetooth

class BLEManager: NSObject {
    
    static let shared = BLEManager()
    
    private var centralManager: CBCentralManager!
    
    fileprivate var didDiscover: ((DiscoveredPeripheral) -> Void)?
    fileprivate var didConnect: ((CBPeripheral) -> Void)?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScan(withServices services: [CBUUID]? = nil, didDiscover: @escaping (DiscoveredPeripheral) -> Void) {
        if centralManager.state == .poweredOn {
            self.didDiscover = didDiscover
            centralManager.scanForPeripherals(withServices: services, options: nil)
        }
    }
    
    func stopScan() {
        didDiscover = nil
        centralManager.stopScan()
    }
    
    func connect(discoveredPeripheral: DiscoveredPeripheral, didConnect: @escaping (CBPeripheral) -> Void) {
        self.didConnect = didConnect
        centralManager.connect(discoveredPeripheral.peripheral, options: nil)
    }
    
    func disconnect(discoveredPeripheral: DiscoveredPeripheral) {
        centralManager.cancelPeripheralConnection(discoveredPeripheral.peripheral)
    }
}

extension BLEManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let discoveredPeripheral = DiscoveredPeripheral(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
        didDiscover?(discoveredPeripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        didConnect?(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    }
}

struct DiscoveredPeripheral {
    
    let peripheral: CBPeripheral
    let advertisementData: [String : Any]
    let rssi: Int
    let isConnectable: Bool
    
    init(peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.rssi = rssi.intValue
        self.isConnectable = (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue ?? false
    }
}
