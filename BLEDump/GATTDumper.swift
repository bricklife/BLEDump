//
//  GATTDumper.swift
//  BLEDump
//
//  Created by ooba on 27/07/2017.
//  Copyright © 2017 bricklife.com. All rights reserved.
//

import Foundation
import CoreBluetooth

class GATTDumper: NSObject {
    
    let peripheral: CBPeripheral
    
    var update: ((String) -> Void)?
    
    var notifyLog: [(Date, CBUUID, String)] = []
    
    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
    }
    
    func startDump(update: @escaping (String) -> Void) {
        self.update = update
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    fileprivate func dump() {
        var text = ""
        peripheral.services?.forEach { service in
            text += "\(service.uuid.uuidString) \(service.includedServices?.map { $0.uuid.uuidString } ?? [])\n"
            service.characteristics?.forEach { characteristic in
                text += "\t\(characteristic.uuid.uuidString) \(characteristic.properties.strings) \(hexDump(data:characteristic.value)) \(stringFor(descriptors: characteristic.descriptors))\n"
            }
        }
        text += "\nNotification Log:\n"
        notifyLog.forEach { (date, uuid, string) in
            text += "\(msec(date: date)) - \(uuid.uuidString) \(string)\n"
        }
        update?(text)
    }
    
    fileprivate func stringFor(descriptors: [CBDescriptor]?) -> [String] {
        guard let descriptors = descriptors else { return [] }
        guard descriptors.count > 0 else { return [] }
        return descriptors.map { (descriptor) -> String in
            if let value = descriptor.value {
                return "\(descriptor.uuid) \(value)"
            } else {
                return "\(descriptor.uuid)"
            }
        }
    }
    
    fileprivate func hexDump(data: Data?) -> String {
        guard let data = data else { return "-" }
        return (data as NSData).description
    }
    
    fileprivate func msec(date: Date) -> String {
        return String(format: "%.5lf", date.timeIntervalSince1970)
    }
}

extension GATTDumper: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        dump()
        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics(nil, for: service)
            peripheral.discoverIncludedServices(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        dump()
        service.characteristics?.forEach { characteristic in
            peripheral.discoverDescriptors(for: characteristic)
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        dump()
        characteristic.descriptors?.forEach { descriptor in
            peripheral.readValue(for: descriptor)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        dump()
        service.includedServices?.forEach { service in
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.isNotifying {
            notifyLog.append((Date(), characteristic.uuid, "Notify: \(hexDump(data: characteristic.value))"))
        }
        dump()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        dump()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        notifyLog.append((Date(), characteristic.uuid, "isNotifying: \(characteristic.isNotifying)"))
        dump()
    }
}

extension CBCharacteristicProperties {
    
    var strings: [String] {
        return [
            (.broadcast, "broadcast"),
            (.read, "read"),
            (.writeWithoutResponse, "writeWithoutResponse"),
            (.write, "write"),
            (.notify, "notify"),
            (.indicate, "indicate"),
            (.authenticatedSignedWrites, "authenticatedSignedWrites"),
            (.extendedProperties, "extendedProperties"),
            (.notifyEncryptionRequired, "notifyEncryptionRequired"),
            (.indicateEncryptionRequired, "indicateEncryptionRequired"),
            ]
            .compactMap { self.contains($0) ? $1 : nil }
    }
}
