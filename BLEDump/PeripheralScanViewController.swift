//
//  PeripheralScanViewController.swift
//  BLEDump
//
//  Created by ooba on 27/07/2017.
//  Copyright © 2017 bricklife.com. All rights reserved.
//

import Cocoa
import CoreBluetooth

class PeripheralScanViewController: NSViewController {
    
    private let manager = BLEManager.shared
    
    fileprivate var discoveredIdentifiers: [String] = []
    fileprivate var discoveredPeripherals: [String : DiscoveredPeripheral] = [:]

    @IBOutlet weak var tableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) { 
            self.startScan()
        }
    }
    
    private func startScan() {
        discoveredIdentifiers = []
        tableView.reloadData()
        manager.startScan() { [weak self] (discoveredPeripheral) in
            self?.didDiscover(discoveredPeripheral)
        }
    }
    
    private func didDiscover(_ discoveredPeripheral: DiscoveredPeripheral) {
        guard discoveredPeripheral.isConnectable else { return }
        
        let uuid = discoveredPeripheral.peripheral.identifier.uuidString
        if !discoveredIdentifiers.contains(uuid) {
            discoveredIdentifiers.append(uuid)
        }
        discoveredPeripherals[uuid] = discoveredPeripheral
        tableView.reloadData()
    }
    
    @IBAction func scanButtonPushed(_ sender: Any) {
        startScan()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard tableView.selectedRow >= 0 else { return }
        
        if let vc = segue.destinationController as? GATTDumpViewController {
            let identifier = discoveredIdentifiers[tableView.selectedRow]
            vc.discoveredPeripheral = discoveredPeripherals[identifier]
        }
    }
}

extension PeripheralScanViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return discoveredIdentifiers.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let identifier = discoveredIdentifiers[row]
        guard let discoveredPeripheral = discoveredPeripherals[identifier] else { return nil }
        
        let peripheral = discoveredPeripheral.peripheral
        let advertisementData = discoveredPeripheral.advertisementData
        
        switch tableColumn?.identifier.rawValue {
        case "Name"?:
            return peripheral.name ?? "Unnamed"
        case "Data"?:
            if let uuids = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID],
                let uuid = uuids.first?.uuidString {
                return uuid
            }
            return nil
        default:
            return nil
        }
    }
}

extension PeripheralScanViewController: NSTableViewDelegate {
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard tableView.selectedRow >= 0 else { return }
        
        performSegue(withIdentifier: "Dump", sender: nil)
    }
}
