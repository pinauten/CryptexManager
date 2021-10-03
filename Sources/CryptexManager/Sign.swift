//
//  Sign.swift
//  CryptexManager
//
//  Created by Linus Henze on 2021-09-08.
//  Copyright © 2021 Pinauten GmbH. All rights reserved.
//

import Foundation
import Swift_libimobiledevice
import libcryptex

class SignInstallModule: iDeviceCommandLineModule {
    static var name: String = "signInstall"
    static var description: String = "Sign and install a cryptex. Requires TSS to be reachable (gs.apple.com)"
    static var requiredArguments: [CommandLineArgument] = [
        .init(shortVersion: "-i", longVersion: "--identifier", description: "The identifier of the cryptex", type: .String),
        .init(shortVersion: "-v", longVersion: "--version", description: "The version of the cryptex", type: .String),
        .init(name: "dmg", description: "Path to cryptex dmg", type: .FilePath),
        .init(name: "trustcache", description: "Path to cryptex trustcache", type: .FilePath)
    ]
    static var optionalArguments: [CommandLineArgument] = [
        .init(shortVersion: "-r", longVersion: "--replace", description: "Replace cryptex if it is already installed", type: .Flag, defaultValue: false)
    ]
    
    static func main(device: iDevice, arguments: ParsedArguments, globalArguments: GlobalArguments?) throws {
        let name: String = arguments.getArgument(longVersion: "--identifier")!
        let version: String = arguments.getArgument(longVersion: "--version")!
        let dmgPath: String = arguments.getArgument(name: "dmg")!
        let tcPath: String = arguments.getArgument(name: "trustcache")!
        
        guard let dmg = try? Data(contentsOf: URL(fileURLWithPath: dmgPath)) else {
            print("Failed to read cryptex dmg!")
            exit(-1)
        }
        guard let tc = try? Data(contentsOf: URL(fileURLWithPath: tcPath)) else {
            print("Failed to read cryptex trustcache!")
            exit(-1)
        }
        
        let devInfo = try TSSDeviceInfo(device: device)
        
        let mounter = try MobileImageMounter(device: device)
        
        let cryptex = CryptexInfo(identifier: name, version: version, dmg: dmg, trustCache: tc)
        
        var signature: Data!
        try StatusIndicator.new("Generating signature", { status in
            signature = try TSSSign(cryptex: cryptex, forDevice: devInfo)
            
            return "Done!"
        })
        
        if arguments.getArgument(longVersion: "--replace") ?? false {
            StatusIndicator.new("Uninstalling cryptex in case it is installed") { status in
                try? mounter.uninstallCryptex(withIdentifier: name)
                
                return "Done!"
            }
        }
        
        try StatusIndicator.new("Installing cryptex") { status in
            _ = try mounter.installCryptex(trustCache: tc, infoPlist: cryptex.infoPlist!, signature: signature, cryptex: dmg)
            
            return "Done!"
        }
    }
}
