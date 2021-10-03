//
//  Create.swift
//  CryptexManager
//
//  Created by Linus Henze on 2021-09-29.
//  Copyright © 2021 Pinauten GmbH. All rights reserved.
//  

import Foundation
import Swift_libimobiledevice
import libcryptex

class CreateModule: iDeviceCommandLineModule {
    static var name: String = "create"
    static var description: String = "Create a cryptex cptx folder from a dmg and distribution root. Requires TSS to be reachable (gs.apple.com)"
    static var requiredArguments: [CommandLineArgument] = [
        .init(shortVersion: "-i", longVersion: "--identifier", description: "The identifier of the cryptex", type: .String),
        .init(shortVersion: "-v", longVersion: "--version", description: "The version of the cryptex", type: .String),
        .init(name: "dmg", description: "Path to cryptex dmg", type: .FilePath),
        .init(name: "dstroot", description: "Path to cryptex distribution root", type: .FolderPath),
        .init(name: "cptx path", description: "Path to the output cptx directory", type: .OutputFolderPath)
    ]
    static var optionalArguments: [CommandLineArgument] = [
        // None
    ]
    
    static func main(device: iDevice, arguments: ParsedArguments, globalArguments: GlobalArguments?) throws {
        let name: String = arguments.getArgument(longVersion: "--identifier")!
        let version: String = arguments.getArgument(longVersion: "--version")!
        let dmgPath: String = arguments.getArgument(name: "dmg")!
        let dstrootPath: String = arguments.getArgument(name: "dstroot")!
        let cptxPath: String = arguments.getArgument(name: "cptx path")!
        
        guard let dmg = try? Data(contentsOf: URL(fileURLWithPath: dmgPath)) else {
            print("Failed to read cryptex dmg!")
            exit(-1)
        }
        
        var tc: Data!
        try StatusIndicator.new("Building trust cache") { status in
            tc = try buildTrustCache(fromPath: dstrootPath, wrapInIM4P: true)
            
            return "Done!"
        }
        
        let devInfo = try TSSDeviceInfo(device: device)
        
        let cryptex = CryptexInfo(identifier: name, version: version, dmg: dmg, trustCache: tc)
        
        var signature: Data!
        try StatusIndicator.new("Generating signature") { status in
            signature = try TSSSign(cryptex: cryptex, forDevice: devInfo)
            
            return "Done!"
        }
                                
        StatusIndicator.new("Writing cptx") { status in
            // Write tc, info plist, signature, dmg
            let base = URL(fileURLWithPath: cptxPath)
            
            status.update("Writing ltrs file")
            do {
                try tc.write(to: base.appendingPathComponent("ltrs"))
            } catch {
                status.failAndExit(msg: "Failed to write ltrs file!")
            }
            
            status.update("Writing c411 file")
            do {
                try cryptex.infoPlist!.write(to: base.appendingPathComponent("c411"))
            } catch {
                status.failAndExit(msg: "Failed to write c411 file!")
            }
            
            status.update("Writing im4m file")
            do {
                try signature.write(to: base.appendingPathComponent("im4m"))
            } catch {
                status.failAndExit(msg: "Failed to write im4m file!")
            }
            
            status.update("Writing cpxd file")
            do {
                try dmg.write(to: base.appendingPathComponent("cpxd"))
            } catch {
                status.failAndExit(msg: "Failed to write cpxd file!")
            }
            
            return "Done!"
        }
    }
}
