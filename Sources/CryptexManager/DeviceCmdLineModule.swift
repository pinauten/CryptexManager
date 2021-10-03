//
//  DeviceCmdLineModule.swift
//  CryptexManager
//
//  Created by Linus Henze on 2021-09-29.
//  Copyright © 2021 Pinauten GmbH. All rights reserved.
//  

import Foundation
import Swift_libimobiledevice

enum iDeviceCommandLineModuleError: Error {
    case connectionFailed
}

protocol iDeviceCommandLineModule: CommandLineModule {
    static func main(device: iDevice, arguments: ParsedArguments, globalArguments: GlobalArguments?) throws
}

extension iDeviceCommandLineModule {
    static func main(arguments: ParsedArguments, globalArguments: GlobalArguments?) throws -> Never {
        handleIDeviceErrors {
            var device: iDevice!
            if let udid: String = globalArguments?.getArgument(longVersion: "--udid") {
                do {
                    device = try iDevice(UDID: udid)
                } catch {
                    throw iDeviceCommandLineModuleError.connectionFailed
                }
            } else {
                let udids = iDevice.allDeviceUDIDsExtended
                guard udids.count != 0 else {
                    print("No device connected!")
                    
                    exit(-1)
                }
                
                do {
                    device = try iDevice(UDID: udids.keys.first!)
                } catch {
                    throw iDeviceCommandLineModuleError.connectionFailed
                }
            }
            
            try main(device: device, arguments: arguments, globalArguments: globalArguments)
        }
    }
}

internal func handleIDeviceErrors(_ cb: () throws -> Void) -> Never {
    do {
        try cb()
        exit(0)
    } catch iDeviceError.noDevice {
        print("Failed to connect to device!")
    } catch MobileImageMounterError.failedToMountImage(additionalData: let ad) {
        print("Failed to mount cryptex!")
        print("If the cryptex is already installed, you will have to uninstall it first.")
        if ad != nil {
            print("Additional data: \(ad!.debugDescription)")
        }
    } catch MobileImageMounterError.cryptexNotFound {
        print("The specified cryptex could not be found!")
    } catch MobileImageMounterError.failedToGetImages {
        print("Couldn't get images - Is this a Security Research Device?")
        print("This error may also occur if your device is locked.")
    } catch MobileImageMounterError.failedToGetCryptexNonce {
        print("Failed to get cryptex nonce - Is this a Security Research Device?")
        print("This error may also occur if your device is locked.")
    } catch iDeviceCommandLineModuleError.connectionFailed {
        print("Couldn't connect to the iDevice - Make sure it is availbale!")
    } catch PropertyListServiceError.invalidArg {
        print("Oops, this doesn't seem to be a Security Research Device!")
    } catch let e {
        print("An unhandled exception occured:")
        print("\(type(of: e)).\(e)")
    }
    
    exit(-1)
}
