//
//  AWAREFileManager.swift
//  AWAREWatch Extension
//
//  Created by Yuuki Nishiyama on 2017/12/18.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

import UIKit

class AWAREFileManager: NSObject {
    var fileName:String
    var localFileURL: URL
    var fileHandle: FileHandle

    override init() {
        self.fileName = "data.csv"
        self.localFileURL = URL(fileURLWithPath: "temp.csv")
        self.fileHandle = FileHandle()
        if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
            self.localFileURL = dir.appendingPathComponent( fileName )
        }
    }
    
    func openFile(){
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: localFileURL.path) {
                self.fileHandle = try FileHandle(forWritingTo: localFileURL)
                print("file exist")
            }else{
                try "".write(to: localFileURL, atomically: true, encoding: String.Encoding.utf8)
                self.fileHandle = try FileHandle(forWritingTo: localFileURL)
                print("file not exist")
            }
            
        } catch {
            // Error
        }
    }
    
    func closeFile(){
        self.fileHandle.closeFile()
    }
    
    func writeData(data:String){
        let stringToWrite = data + "\n"
        fileHandle.seekToEndOfFile()
        fileHandle.write(stringToWrite.data(using: String.Encoding.utf8)!)
    }
    
    func showData(){
        do {
            let text = try String( contentsOf: localFileURL, encoding: String.Encoding.utf8 )
            print( text )
        } catch {
            print("error at show data!")
        }
    }
    
}
