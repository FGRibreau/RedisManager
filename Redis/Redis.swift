//
//  Task.swift
//  Redis
//
//  Created by Giuseppe Salvo on 15/01/16.
//  Copyright © 2016 Giuseppe Salvo. All rights reserved.
//

import Foundation
import Cocoa

//
// Redis
// Singleton
//

class Redis {
    
    // MARK: vars
    private var launchPath : String { return RedisPath }
    private let arguments  : [String]  = []
  
    static var debug = true
    static var error : String?
    
    var task : NSTask!
    
    static var isRunning = false
    
    //
    // MARK: Singleton
    // In swift is fairly simple
    //
    static let instance : Redis! = Redis()
    private init () {
        build()
    }
    
    //
    // I use build function because NSTask, after terminate, it's not able to relaunch
    //
    func build() {
        self.task = NSTask.init()
        task.launchPath = self.launchPath
        task.arguments = self.arguments
    }
    
    //
    // Log task result
    //
    func log () {
        if self.dynamicType.debug {
            print( self.task.debugDescription )
        }
    }
    
    //
    // Trying to connect to localhost:6379 with telnet to check if redis is already running
    //
    func portIsActive (host: String, port: Int) -> Bool {
        
        let telnet = NSTask.init()
        telnet.launchPath = "/usr/bin/telnet"
        telnet.arguments = [ host, "\(port)" ]
        telnet.launch()
        
        NSThread.sleepForTimeInterval(0.5)
        
        func terminateTelnet () {
            telnet.suspend()
            telnet.terminate()
            
            let t = NSRunningApplication(processIdentifier: self.task!.processIdentifier)
            t?.terminate()
            t?.forceTerminate()
            
            system("kill -9 \(telnet.processIdentifier)")
        }
        
        if telnet.running {
            terminateTelnet()
            return true
        } else {
            terminateTelnet()
            return false
        }
    }
    
    //
    // MARK: Start Task
    //
    func start () -> Bool {

        if self.portIsActive("localhost", port: 6379) {
            self.dynamicType.isRunning = false
            self.dynamicType.error = "Port 6379 is busy :("
            return false
        }
        
        if !self.dynamicType.isRunning {
            
            self.task.launch()
            log()
            
            NSThread.sleepForTimeInterval(1)
            
            print( "\n\n\nprocessIdentifier: \(self.task.processIdentifier)\n\n\n" )
            
            if self.task.running {
                self.dynamicType.isRunning = true
                self.dynamicType.error = ""
                    
                return true
            } else {
                self.dynamicType.isRunning = false
                self.task.terminate()
                self.build()
                self.dynamicType.error = "Error while executing redis-server command"
                    
                return false
            }
            
        }
        else {
            print( "Task is already running" )
            self.dynamicType.error = "Redis is already running"
            
            return false
        }
    
    }
    
    //
    // MARK: Stop Task
    //
    func stop () -> Bool {
        
        if self.dynamicType.isRunning {
            
            self.task.suspend()
            self.task.terminate()

            let t = NSRunningApplication(processIdentifier: self.task!.processIdentifier)
            t?.terminate()
            t?.forceTerminate()
            
            system("kill -9 \(self.task.processIdentifier)")
            
            print( "\n\n\nprocessIdentifier: \(self.task.processIdentifier)\n\n\n" )
            
            self.build()
            
            self.dynamicType.isRunning = false
            self.dynamicType.error = ""
            
            log()
            return true
        }
        else {
            print( "Task is not running" )
            self.dynamicType.error = "Redis is not running"
            
            return false
        }
    }
}
