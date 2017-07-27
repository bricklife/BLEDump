//
//  GATTDumpViewController.swift
//  BLEDump
//
//  Created by ooba on 27/07/2017.
//  Copyright © 2017 bricklife.com. All rights reserved.
//

import Cocoa

class GATTDumpViewController: NSViewController {
    
    var discoveredPeripheral: DiscoveredPeripheral?
    
    @IBOutlet var textView: NSTextView!
    
    private let manager = BLEManager.shared
    private var dumper: GATTDumper?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        guard let discoveredPeripheral = discoveredPeripheral else { return }
        
        update(text: "Dumping...")
        
        manager.connect(discoveredPeripheral: discoveredPeripheral) { [weak self] (peripheral) in
            self?.dumper = GATTDumper(peripheral: peripheral)
            self?.dumper?.startDump() { (text) in
                self?.update(text: text)
            }
        }
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        
        guard let discoveredPeripheral = discoveredPeripheral else { return }

        manager.disconnect(discoveredPeripheral: discoveredPeripheral)
    }
    
    private func update(text: String) {
        guard let discoveredPeripheral = discoveredPeripheral else { return }
        
        var output = ""
        output += discoveredPeripheral.peripheral.name ?? "Unknown"
        output += "\n\(discoveredPeripheral.peripheral.identifier)\n\n"
        output += "advertisementData: \(discoveredPeripheral.advertisementData.description)\n\n"
        output += text
        
        textView.string = output
    }
}
