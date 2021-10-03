//
//  main.swift
//  CryptexManager
//
//  Created by Linus Henze on 2021-09-07.
//  Copyright © 2021 Pinauten GmbH. All rights reserved.
//

import Foundation

try parseCommandLine(modules: [
    InstallModule.self,
    CreateModule.self,
    SignInstallModule.self,
    ListModule.self,
    UninstallModule.self,
    BuildTCModule.self
], globalArgs: GlobalArguments(requiredArguments: [
    // No required arguments
], optionalArguments: [
    .init(shortVersion: "-u", longVersion: "--udid", description: "UDID of the device to connect to", type: .String)
]))
