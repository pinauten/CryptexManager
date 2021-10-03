//
//  CommandLineParser.swift
//  CryptexManager
//
//  Created by Linus Henze on 2019-10-14.
//  Copyright © 2019-2021 Linus Henze. All rights reserved.
//  Copyright © 2021 Pinauten GmbH. All rights reserved.
//

import Foundation

enum CommandLineArgumentTypes {
    case String
    case Int
    case UInt
    case Flag
    case FilePath
    case OutputFilePath
    case FolderPath
    case OutputFolderPath
}

/**
 * A command line argument
 */
class CommandLineArgument: Equatable {
    let name:         String // This name will only be shown for required arguments that do not have a short or long version
    let shortVersion: String
    let longVersion:  String
    let description:  String
    let type:         CommandLineArgumentTypes
    var rawValue:     Any?
    var defaultValue: Any?
    
    var value:        Any? {
        get {
            (rawValue != nil) ? rawValue.unsafelyUnwrapped : defaultValue
        }
        set {
            rawValue = newValue
        }
    }
    
    static func == (lhs: CommandLineArgument, rhs: CommandLineArgument) -> Bool {
        return lhs.description == rhs.description
    }
    
    init(name: String, description: String, type: CommandLineArgumentTypes, defaultValue: Any? = nil) {
        self.name = name
        self.shortVersion = ""
        self.longVersion = ""
        self.description = description
        self.type = type
        self.defaultValue = defaultValue
    }
    
    init(shortVersion: String, description: String, type: CommandLineArgumentTypes, defaultValue: Any? = nil) {
        self.name = ""
        self.shortVersion = shortVersion
        self.longVersion = ""
        self.description = description
        self.type = type
        self.defaultValue = defaultValue
    }
    
    init(longVersion: String, description: String, type: CommandLineArgumentTypes, defaultValue: Any? = nil) {
        self.name = ""
        self.shortVersion = ""
        self.longVersion = longVersion
        self.description = description
        self.type = type
        self.defaultValue = defaultValue
    }
    
    init(shortVersion: String, longVersion: String, description: String, type: CommandLineArgumentTypes, defaultValue: Any? = nil) {
        self.name = ""
        self.shortVersion = shortVersion
        self.longVersion = longVersion
        self.description = description
        self.type = type
        self.defaultValue = defaultValue
    }
}

struct ParsedArguments {
    let requiredArguments: [CommandLineArgument]
    let optionalArguments: [CommandLineArgument]
    
    func getArgument<T: Any>(name: String) -> T? {
        for arg in requiredArguments {
            if arg.name == name {
                return (arg.value != nil) ? (arg.value as! T) : nil
            }
        }
        
        for arg in optionalArguments {
            if arg.name == name {
                return (arg.value != nil) ? (arg.value as! T) : nil
            }
        }
        
        return nil
    }
    
    func getArgument<T: Any>(longVersion: String) -> T? {
        for arg in requiredArguments {
            if arg.longVersion == longVersion {
                return (arg.value != nil) ? (arg.value as! T) : nil
            }
        }
        
        for arg in optionalArguments {
            if arg.longVersion == longVersion {
                return (arg.value != nil) ? (arg.value as! T) : nil
            }
        }
        
        return nil
    }
    
    func getArgument<T: Any>(shortVersion: String) -> T? {
        for arg in requiredArguments {
            if arg.shortVersion == shortVersion {
                return (arg.value != nil) ? (arg.value as! T) : nil
            }
        }
        
        for arg in optionalArguments {
            if arg.shortVersion == shortVersion {
                return (arg.value != nil) ? (arg.value as! T) : nil
            }
        }
        
        return nil
    }
}

struct GlobalArguments {
    let requiredArguments: [CommandLineArgument]
    let optionalArguments: [CommandLineArgument]
    
    func getArgument<T: Any>(longVersion: String) -> T? {
        for arg in requiredArguments {
            if arg.longVersion == longVersion {
                return (arg.value != nil) ? (arg.value as! T) : nil
            }
        }
        
        for arg in optionalArguments {
            if arg.longVersion == longVersion {
                return (arg.value != nil) ? (arg.value as! T) : nil
            }
        }
        
        return nil
    }
    
    func getArgument<T: Any>(shortVersion: String) -> T? {
        for arg in requiredArguments {
            if arg.shortVersion == shortVersion {
                return (arg.value != nil) ? (arg.value as! T) : nil
            }
        }
        
        for arg in optionalArguments {
            if arg.shortVersion == shortVersion {
                return (arg.value != nil) ? (arg.value as! T) : nil
            }
        }
        
        return nil
    }
}

/**
 * Create a new command line module
 *
 * Create a new command line module which can be accessed by running this app as:
 *
 * `app <module name> <arguments>`
 */
protocol CommandLineModule {
    static var name: String { get }
    static var description: String { get }
    static var requiredArguments: [CommandLineArgument] { get }
    static var optionalArguments: [CommandLineArgument] { get }
    
    static func main(arguments: ParsedArguments, globalArguments: GlobalArguments?) throws -> Never
}

fileprivate func typeToString(type: CommandLineArgumentTypes) -> String {
    switch type {
    case .String:
        return "value"
        
    case .Int: fallthrough
    case .UInt:
        return "number"
        
    case .Flag:
        return ""
        
    case .FilePath:
        return "file path"
        
    case .OutputFilePath:
        return "output file path"
        
    case .FolderPath:
        return "folder path"
        
    case .OutputFolderPath:
        return "output folder path"
    }
}

fileprivate func getModuleDescription(module: CommandLineModule.Type, appName: String, hasGlobalArgs: Bool) -> String {
    var result = ""
    result += "\t\(module.name)\n"
    result += "\t\tUsage:\n"
    var usageString = "\(appName)\(hasGlobalArgs ? " <global parameters>" : "") \(module.name)"
    
    if module.optionalArguments.count != 0 {
        usageString += " <optional parameters>"
    }
    
    for i in module.requiredArguments {
        let type = typeToString(type: i.type)
        
        if i.shortVersion != "" {
            usageString += " \(i.shortVersion) <\(type)>"
        } else if i.longVersion != "" {
            usageString += " \(i.longVersion) <\(type)>"
        } else if i.name != "" {
            usageString += " <\(i.name)>"
        } else {
            fatalError("getModuleDescription: XXX - This shouldn't happen")
        }
    }
    
    result += "\t\t\t\(usageString)\n"
    result += "\t\tDescription:\n"
    result += "\t\t\t\(module.description.replacingOccurrences(of: "\n", with: "\n\t\t\t"))\n"
    if module.requiredArguments.count != 0 {
        result += "\t\tRequired Parameters:\n"
        func buildParamText(_ i: CommandLineArgument) -> String {
            var result = ""
            
            let type = typeToString(type: i.type)
            if i.shortVersion != "" {
                result += "\(i.shortVersion)"
            }
            
            if i.longVersion != "" {
                if i.shortVersion != "" {
                    result += ", \(i.longVersion)"
                } else {
                    result += "\(i.longVersion)"
                }
            }
            
            if i.name != "" && i.shortVersion == "" && i.longVersion == "" {
                result += "<\(i.name)>"
            } else {
                result += " <\(type)>"
            }
            
            return result
        }
        
        var longest = 0
        for i in module.requiredArguments {
            let len = buildParamText(i).count
            if len > longest {
                longest = len
            }
        }
        
        for i in module.requiredArguments {
            result += "\t\t\t"
            
            var text = buildParamText(i)
            if text.count < longest {
                text.append(String(repeating: " ", count: longest - text.count))
            }
            
            result += text
            
            result += "\t\(i.description)\n"
        }
    }
    
    if module.optionalArguments.count != 0 {
        result += "\t\tOptional Parameters:\n"
        func buildParamText(_ i: CommandLineArgument) -> String {
            var result = ""
            
            let type = typeToString(type: i.type)
            if i.shortVersion != "" {
                result += "\(i.shortVersion)"
            }
            
            if i.longVersion != "" {
                if i.shortVersion != "" {
                    result += ", \(i.longVersion)"
                } else {
                    result += "\(i.longVersion)"
                }
            }
            
            if i.name != "" && i.shortVersion == "" && i.longVersion == "" {
                fatalError("getModuleDescription: A short or long version must be set for optional parameters, not a name.")
            } else {
                if type != "" {
                    result += " <\(type)>"
                }
            }
            
            return result
        }
        
        var longest = 0
        for i in module.optionalArguments {
            let len = buildParamText(i).count
            if len > longest {
                longest = len
            }
        }
        
        for i in module.optionalArguments {
            result += "\t\t\t"
            
            var text = buildParamText(i)
            if text.count < longest {
                text.append(String(repeating: " ", count: longest - text.count))
            }
            
            result += text
            
            result += "\t\(i.description)\n"
        }
    }
    
    return result
}

fileprivate func printUsage(modules: [CommandLineModule.Type], globalArgs: GlobalArguments?) -> Never {
    var appName = "app"
    if let appNameReal = getprogname() {
        appName = String(cString: appNameReal)
    }
    
    if globalArgs != nil {
        print("Usage: \(appName) <global parameters> <action> <parameters>")
        print("Where global parameters can be:")
        var result = ""
        
        if globalArgs.unsafelyUnwrapped.requiredArguments.count != 0 {
            result += "\tRequired Parameters:\n"
            for i in globalArgs.unsafelyUnwrapped.requiredArguments {
                result += "\t\t"
                
                let type = typeToString(type: i.type)
                if i.shortVersion != "" {
                    result += "\(i.shortVersion)"
                }
                
                if i.longVersion != "" {
                    if i.shortVersion != "" {
                        result += ", \(i.longVersion)"
                    } else {
                        result += "\(i.longVersion)"
                    }
                }
                
                if i.name != "" && i.shortVersion == "" && i.longVersion == "" {
                    if type != "" {
                        result += "[\(i.name) <\(type)>]"
                    } else {
                        result += "[\(i.name)]"
                    }
                } else {
                    if type != "" {
                        result += " <\(type)>"
                    }
                }
                
                result += "\t\(i.description)\n"
            }
        }
        
        if globalArgs.unsafelyUnwrapped.optionalArguments.count != 0 {
            result += "\tOptional Parameters:\n"
            for i in globalArgs.unsafelyUnwrapped.optionalArguments {
                result += "\t\t"
                
                let type = typeToString(type: i.type)
                if i.shortVersion != "" {
                    result += "\(i.shortVersion)"
                }
                
                if i.longVersion != "" {
                    if i.shortVersion != "" {
                        result += ", \(i.longVersion)"
                    } else {
                        result += "\(i.longVersion)"
                    }
                }
                
                if i.name != "" && i.shortVersion == "" && i.longVersion == "" {
                    fatalError("getModuleDescription: A short or long version must be set for optional parameters, not a name.")
                } else {
                    if type != "" {
                        result += " <\(type)>"
                    }
                }
                
                result += "\t\(i.description)\n"
            }
        }
        
        print(result, terminator: "")
    } else {
        print("Usage: \(appName) <action> <parameters>")
    }
    
    print("Where action can be one of:")
    
    var descriptions = ""
    for i in 0..<modules.count {
        descriptions += getModuleDescription(module: modules[i], appName: appName, hasGlobalArgs: globalArgs != nil)
        if i != modules.count - 1 {
            descriptions += "\n"
        }
    }
    
    print(descriptions.replacingOccurrences(of: "\t", with: "    "), terminator: "")
    
    exit(-1)
}

fileprivate func parseInput(input: String, type: CommandLineArgumentTypes) -> Any? {
    switch type {
    case .String:
        return input as Any
        
    case .Int:
        if let value = Int(input) {
            return value as Any
        }
        
        if input.starts(with: "0x") {
            if let value = Int(input[input.index(after: input.index(after: input.startIndex))...]) {
                return value as Any
            }
        }
        
        return nil
        
    case .UInt:
        return UInt(input) as Any
        
    case .Flag:
        return true as Any
        
    case .FilePath:
        var isFolder: ObjCBool = false
        if !FileManager.default.fileExists(atPath: input, isDirectory: &isFolder) {
            return nil
        }
        
        if isFolder.boolValue {
            return nil
        }
        
        return input as Any
        
    case .OutputFilePath:
        var isFolder: ObjCBool = false
        if FileManager.default.fileExists(atPath: input, isDirectory: &isFolder) {
            if isFolder.boolValue {
                return nil
            }
        }
        
        return input as Any
        
    case .FolderPath:
        var isFolder: ObjCBool = false
        if !FileManager.default.fileExists(atPath: input, isDirectory: &isFolder) {
            return nil
        }
        
        if !isFolder.boolValue {
            return nil
        }
        
        return input as Any
    
    case .OutputFolderPath:
        var isFolder: ObjCBool = false
        if FileManager.default.fileExists(atPath: input, isDirectory: &isFolder) {
            if !isFolder.boolValue {
                return nil
            }
        } else {
            // Make sure the folder exists
            do {
                try FileManager.default.createDirectory(atPath: input, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("Failed to create output folder '\(input)'!")
                return nil
            }
        }
        
        return input as Any
    }
}

fileprivate func parseArgumentsFor(module: CommandLineModule.Type, allModules: [CommandLineModule.Type], globalArgs: GlobalArguments?, firstParamIndex: Int) throws -> Never {
    var parsedRequiredArguments = Array<CommandLineArgument>()
    var parsedOptionalArguments = Array<CommandLineArgument>()
    
    var nextIsValue         = false
    var wasRequiredArgument = false
    
    var counter = firstParamIndex
    
    for arg in CommandLine.arguments[firstParamIndex...] {
        if nextIsValue {
            nextIsValue = false
            
            let argument = wasRequiredArgument ? parsedRequiredArguments.last! : parsedOptionalArguments.last!
            let type = argument.type
            
            guard let value = parseInput(input: arg, type: type) else {
                print("Value passed to argument \(CommandLine.arguments[counter]) is not a \(typeToString(type: type))!")
                exit(-1)
            }
            
            argument.value = value
            
            continue
        }
        
        var found = false
        
        // Maybe a required argument?
        for i in module.requiredArguments {
            if arg == i.shortVersion || arg == i.longVersion {
                if let index = parsedRequiredArguments.firstIndex(of: i) {
                    parsedRequiredArguments.remove(at: index)
                }
                
                parsedRequiredArguments.append(i)
                if i.type != .Flag {
                    nextIsValue = true
                    wasRequiredArgument = true
                } else {
                    parsedRequiredArguments.last!.value = true as Any
                }
                
                found = true
                
                break
            }
        }
        
        if found {
            counter += 1
            continue
        }
        
        // Maybe an optional argument?
        for i in module.optionalArguments {
            if arg == i.shortVersion || arg == i.longVersion {
                if let index = parsedOptionalArguments.firstIndex(of: i) {
                    parsedOptionalArguments.remove(at: index)
                }
                
                parsedOptionalArguments.append(i)
                if i.type != .Flag {
                    nextIsValue = true
                    wasRequiredArgument = false
                } else {
                    parsedOptionalArguments.last!.value = true as Any
                }
                
                found = true
                
                break
            }
        }
        
        if found {
            counter += 1
            continue
        }
        
        // Maybe the direct argument to a required argument?
        for i in module.requiredArguments {
            if i.name != "" {
                if i.value == nil {
                    guard let value = parseInput(input: arg, type: i.type) else {
                        print("Value passed to argument \(i.name) is not a \(typeToString(type: i.type))!")
                        exit(-1)
                    }
                    
                    i.value = value
                    
                    parsedRequiredArguments.append(i)
                    
                    found = true
                    
                    break
                }
            }
        }
        
        if found {
            counter += 1
            continue
        }
        
        print("Unknown argument \(arg)!")
        printUsage(modules: allModules, globalArgs: globalArgs)
    }
    
    // A value is still missing...
    if nextIsValue {
        print("Value for \(CommandLine.arguments.last!) is missing!")
        printUsage(modules: allModules, globalArgs: globalArgs)
    }
    
    if parsedRequiredArguments.count != module.requiredArguments.count {
        print("Not enough arguments!")
        printUsage(modules: allModules, globalArgs: globalArgs)
    }
    
    // Invoke block!
    try module.main(arguments: ParsedArguments(requiredArguments: parsedRequiredArguments, optionalArguments: parsedOptionalArguments), globalArguments: globalArgs)
}

func parseCommandLine(modules: [CommandLineModule.Type], globalArgs: GlobalArguments? = nil) throws -> Never {
    if CommandLine.arguments.count < 2 {
        printUsage(modules: modules, globalArgs: globalArgs)
    }
    
    var argToSet: CommandLineArgument?
    
    globalArgLoop:
    for i in 1..<CommandLine.arguments.count {
        let arg = CommandLine.arguments[i]
        
        if argToSet != nil {
            argToSet.unsafelyUnwrapped.value = parseInput(input: arg, type: argToSet.unsafelyUnwrapped.type)
            argToSet = nil
        } else {
            if arg == "" {
                // Nope
                print("Found empty argument!")
                
                printUsage(modules: modules, globalArgs: globalArgs)
            }
            
            if globalArgs != nil {
                // Check required arguments
                for args in globalArgs.unsafelyUnwrapped.requiredArguments {
                    if args.name != "" {
                        fatalError("Global arguments *must* have a short and/or long version!")
                    } else if arg == args.longVersion || arg == args.shortVersion {
                        if args.type != .Flag {
                            argToSet = args
                        } else {
                            args.value = true as Any
                        }
                        
                        continue globalArgLoop
                    }
                }
                
                // Check optional arguments
                for args in globalArgs.unsafelyUnwrapped.optionalArguments {
                    if arg == args.longVersion || arg == args.shortVersion {
                        if args.type != .Flag {
                            argToSet = args
                        } else {
                            args.value = true as Any
                        }
                        
                        continue globalArgLoop
                    }
                }
            }
            
            // Not an argument, maybe a module
            for m in modules {
                if CommandLine.arguments[i] == m.name {
                    // Check if we got all required arguments
                    if globalArgs != nil {
                        for arg in globalArgs.unsafelyUnwrapped.requiredArguments {
                            guard arg.value != nil else {
                                let name = (arg.longVersion != "") ? arg.longVersion : arg.shortVersion
                                print("Required argument \(name) not specified!")
                                
                                printUsage(modules: modules, globalArgs: globalArgs)
                            }
                        }
                    }
                    
                    try parseArgumentsFor(module: m, allModules: modules, globalArgs: globalArgs, firstParamIndex: i+1)
                }
            }
            
            // Nothing? Print usage!
            print("Unknown argument/action '\(arg)'!")
            printUsage(modules: modules, globalArgs: globalArgs)
        }
    }
    
    if argToSet != nil {
        let name = (argToSet.unsafelyUnwrapped.longVersion != "") ? argToSet.unsafelyUnwrapped.longVersion : argToSet.unsafelyUnwrapped.shortVersion
        print("Missing value to parameter '\(name)'!")
    } else {
        print("Missing action!")
    }
    
    printUsage(modules: modules, globalArgs: globalArgs)
}
