//
//  InstallUninstall.swift
//  CryptexManager
//
//  Created by Linus Henze on 2021-09-07.
//  Copyright © 2021 Pinauten GmbH. All rights reserved.
//

import Foundation
import Swift_libimobiledevice
import libcryptex

class InstallModule: iDeviceCommandLineModule {
    static var name: String = "install"
    static var description: String = "Install a cryptex"
    static var requiredArguments: [CommandLineArgument] = [
        .init(name: "cptx path", description: "Path to the cptx folder of the cryptex to be installed", type: .FolderPath)
    ]
    static var optionalArguments: [CommandLineArgument] = [
        // None
    ]
    
    static func main(device: iDevice, arguments: ParsedArguments, globalArguments: GlobalArguments?) throws {
        let mounter = try MobileImageMounter(device: device)
        
        try mounter.installCryptex(cptxPath: arguments.getArgument(name: "cptx path")!)
        
        print("Successfully installed cryptex!")
    }
}

class UninstallModule: iDeviceCommandLineModule {
    static var name: String = "uninstall"
    static var description: String = "Uninstall a cryptex"
    static var requiredArguments: [CommandLineArgument] = [
        .init(name: "cryptex id", description: "Identifier of the cryptex to be uninstalled", type: .String)
    ]
    static var optionalArguments: [CommandLineArgument] = [
        // None
    ]
    
    static func main(device: iDevice, arguments: ParsedArguments, globalArguments: GlobalArguments?) throws {
        let mounter = try MobileImageMounter(device: device)
        try mounter.uninstallCryptex(withIdentifier: arguments.getArgument(name: "cryptex id")!)
        
        print("Successfully uninstalled cryptex!")
    }
}

class ListModule: iDeviceCommandLineModule {
    static var name: String = "list"
    static var description: String = "List installed cryptexes"
    static var requiredArguments: [CommandLineArgument] = [
        // None
    ]
    static var optionalArguments: [CommandLineArgument] = [
        // None
    ]
    
    static func main(device: iDevice, arguments: ParsedArguments, globalArguments: GlobalArguments?) throws {
        let mounter = try MobileImageMounter(device: device)
        let images = try mounter.getMountedImages()
        
        var foundAtLeastOne = false
        for image in images {
            if image["DiskImageType"] as? String == "Cryptex",
               let id = image["CryptexName"] as? String,
               let version = image["CryptexVersion"] as? String,
               let mntPath = image["MountPath"] as? String {
                foundAtLeastOne = true
                
                let dmgPath = image["BackingImage"] as? String ?? "<unknown>"
                
                print("\(id):")
                print("\tVersion: \(version)")
                print("\tMounted at: \(mntPath)")
                print("\tDisk image path: \(dmgPath)")
            }
        }
        
        if !foundAtLeastOne {
            print("<no cryptex installed>")
        }
    }
}
