//
//  Logger.swift
//  MomentRomance
//
//  Created by Tanaka on 2016/07/11.
//  Copyright © 2016年 Milan Market Place Inc. All rights reserved.
//

import Foundation

class Logger{
    class func debug(
        message: String,
        function: String = #function,
        file: String = #file,
        line: Int = #line) { Logger.write("[DEBUG]", message: message, function: function, file: file, line: line) };
    class func info(
        message: String,
        function: String = #function,
        file: String = #file,
        line: Int = #line) { Logger.write("[INFO]", message: message, function: function, file: file, line: line) };
    class func warning(
        message: String,
        function: String = #function,
        file: String = #file,
        line: Int = #line) { Logger.write("[WARNING]", message: message, function: function, file: file, line: line) };
    class func error(
        message: String,
        function: String = #function,
        file: String = #file,
        line: Int = #line) { Logger.write("[ERROR]", message: message, function: function, file: file, line: line) };
    class func write(
        loglevel: String,
        message: String,
        function: String,
        file: String,
        line: Int) {
        
        let now = NSDate() // 現在日時の取得
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "ja_JP")
        dateFormatter.timeStyle = .MediumStyle
        dateFormatter.dateStyle = .MediumStyle
        //println(dateFormatter.stringFromDate(now)) // => 2014/12/11 15:19:04
        
        let nowdate = dateFormatter.stringFromDate(now)
        
        var filename = file
        if let match = filename.rangeOfString("[^/]*$", options: .RegularExpressionSearch) {
            filename = filename.substringWithRange(match)
        }
        print("\(loglevel) => \"\(message)\" \(nowdate) L\(line) \(function) @\(filename)")
    }
}
