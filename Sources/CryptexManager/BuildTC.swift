//
//  BuildTC.swift
//  CryptexManager
//
//  Created by Linus Henze on 2021-09-08.
//  Copyright © 2021 Pinauten GmbH. All rights reserved.
//

import Foundation
import libcryptex

class BuildTCModule: CommandLineModule {
    static var name = "buildTrustCache"
    static var description = "Create a trust cache from a directory"
    static var requiredArguments: [CommandLineArgument] = [
        .init(name: "directory", description: "Path to directory used for trust cache generation", type: .FolderPath),
        .init(name: "trustcache", description: "Output", type: .OutputFilePath)
    ]
    static var optionalArguments: [CommandLineArgument] = [
        .init(shortVersion: "-i", longVersion: "--im4p", description: "Wrap trust cache in an IM4P container (required for cryptexes)", type: .Flag)
    ]
    
    static func main(arguments: ParsedArguments, globalArguments: GlobalArguments?) throws -> Never {
        let folderPath: String = arguments.getArgument(name: "directory")!
        let tcPath: String = arguments.getArgument(name: "trustcache")!
        
        StatusIndicator.new("Building trust cache", { status in
            let wrap = arguments.getArgument(longVersion: "--im4p") ?? false
            
            do {
                let tc = try buildTrustCache(fromPath: folderPath, wrapInIM4P: wrap)
                
                do {
                    try tc.write(to: URL(fileURLWithPath: tcPath))
                } catch {
                    status.failAndExit(msg: "Trust cache path is not writable!")
                }
            } catch let e as TrustCacheCreateError {
                switch e {
                case .folderDoesNotExist:
                    status.failAndExit(msg: "The specified folder does not exist!")
                    
                case .notAFolder:
                    status.failAndExit(msg: "Please specify a folder!")
                    
                case .cannotReadFolder:
                    status.failAndExit(msg: "Cannot read folder!")
                }
            } catch {
                fatalError()
            }
            
            return "Done!"
        })
        
        exit(0)
    }
}
