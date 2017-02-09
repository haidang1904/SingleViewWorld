//
//  Log.swift
//  SingleViewWorld
//
//  Created by samsung on 2016. 7. 5..
//  Copyright © 2016년 samsung. All rights reserved.
//

import Foundation

public struct Log {

    public static func test(_ message:  Any , _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        #if !DISABLE_LOG
            
            guard let fileName =  (URL(string: file)?.deletingPathExtension().lastPathComponent) else {return}
            
            var fun = function
            if let r = function.range(of: "(")?.lowerBound {
                fun  = function.substring(to: r)
            }
            
            let prefix = "\(fileName).\(fun)(\(line)): "
            Swift.print("\(prefix)\t\(message)")
        #endif
    }
    
    public static func lhjtest(_ message:  Any , _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        #if !DISABLE_LOG
            let fileName: String =  (NSURL(string: file)?.deletingPathExtension?.lastPathComponent)!
            
            var fun = function
            if let r = function.range(of: "(")?.lowerBound {
                fun  = function.substring(to: r)
            }
            
            let prefix = "\(fileName).\(fun)(\(line)): "
            Swift.print("[LHJ TEST]\n\(prefix)\t\(message)")
        #endif
    }
}
