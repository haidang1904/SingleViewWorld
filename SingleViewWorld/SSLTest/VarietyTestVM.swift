//
//  SDKTestViewModel.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 7/20/16.
//  Copyright © 2016 samsung. All rights reserved.
//

import UIKit
import SmartView
import Alamofire
import RxSwift

class discoveredTVInfo : NSObject {
    var vdProductType: String = ""
    var friendlyName: String = ""
    var year: String = ""
    var ip: String = ""
    var udn: String = ""
    var isOCF: Bool = false
}

class VarietyTestVM : NSObject {
    
    var deviceIp : String? = nil
    var discoveredTVList : [discoveredTVInfo] = []
    var discoveredTV = discoveredTVInfo()
    var currentIP : String = ""
    
    var parseData : XMLParser? = nil
    var queue: DispatchQueue? = nil
    var currentElementName : String = ""
    
    let TargetTV :String = "[TV] Bed room"
    
    
    fileprivate let connectDataSubject = BehaviorSubject<Bool>(value: false)
    internal var connectData: Observable<Bool> {
        return connectDataSubject.asObservable()
    }
    
    fileprivate let appsDataSubject = BehaviorSubject<Bool>(value: false)
    internal var appsData: Observable<Bool> {
        return appsDataSubject.asObservable()
    }

    override init() {
        super.init()
        self.queue = DispatchQueue(label: "VarietyTestQueue")
        self.parseData?.delegate = self
    }
    
    func close(){
    }
    
    func discoverStart(){
        self.discoveredTVList.removeAll()
        
        queue?.async(execute: {
            var urlString : String = "192.168.0.1"
            var url : URL? = nil
            for last in 2...254
            {
                urlString = String(format: "192.168.0.\(last)")
                url = URL(string: "http://\(urlString):9197/dmr")
                //Log.test("request url : \(url)")
                Alamofire.request(url! , method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil)
                    .response(completionHandler: {[weak self] (data) in
                        if let _ = data.response, data.response?.statusCode == 200 {
                            Log.test("request \(data.request?.url?.absoluteString) is received")
                            self?.parsingData(data: data.data!, ip:(data.request?.url?.absoluteString)!)
                        }
                    })
            }
        })
        //return false
    }
    func parsingData(data:Data, ip:String) {
        self.parseData = XMLParser(data:data)
        self.parseData?.delegate = self
        self.currentIP = ip.replacingOccurrences(of: ":9197/dmr", with: "")
        self.currentIP = self.currentIP.replacingOccurrences(of: "http://", with: "")
        if let isparse = self.parseData?.parse(), isparse == true {
            Log.test("Parsing is success")
        } else {
            Log.test("Parsing is fail")
        }
        self.currentIP = ""
    }
    
    
    func getDiscoveredTVName(_ index:Int) -> String? {
        if self.discoveredTVList.count > index {
            let returnStr = String(format: "\(self.discoveredTVList[index].friendlyName)  (IP:\(self.discoveredTVList[index].ip))")
            return returnStr
        } else {
            return ""
        }
    }
    
    func getDiscoveredTVIP(_ index:Int) -> String? {
        if self.discoveredTVList.count > index {
            return self.discoveredTVList[index].ip
        } else {
            return ""
        }
    }
    
    func getDiscoveredTVCount() -> Int {
        return self.discoveredTVList.count
    }
    
}

extension VarietyTestVM : XMLParserDelegate{
    
    @objc public func parserDidStartDocument(_ parser: XMLParser){
        Log.test("parserDidStartDocument")
        discoveredTV.friendlyName = ""
        discoveredTV.ip = ""
        discoveredTV.isOCF = false
        discoveredTV.udn = ""
        discoveredTV.vdProductType = ""
        discoveredTV.year = ""
        
    }
    
    @objc public func parserDidEndDocument(_ parser: XMLParser){
        let willAddTV = discoveredTVInfo()
        willAddTV.ip = self.currentIP
        willAddTV.friendlyName = discoveredTV.friendlyName
        willAddTV.isOCF = discoveredTV.isOCF
        willAddTV.udn = discoveredTV.udn
        willAddTV.vdProductType = discoveredTV.vdProductType
        willAddTV.year = discoveredTV.year
        discoveredTVList.append(willAddTV)
        self.connectDataSubject.onNext(true)
        Log.test("parserDidEndDocument and DidEndAddToList == Count:\(discoveredTVList.count), Info:\(willAddTV.ip) ")
    }
    
    @objc public func parser(_ parser: XMLParser, foundNotationDeclarationWithName name: String, publicID: String?, systemID: String?) {
        Log.test("foundNotationDeclarationWithName == name:\(name) ")
    }
    
    @objc public func parser(_ parser: XMLParser, foundUnparsedEntityDeclarationWithName name: String, publicID: String?, systemID: String?, notationName: String?) {
        Log.test("foundUnparsedEntityDeclarationWithName == name:\(name) ")
    }
    
    @objc public func parser(_ parser: XMLParser, foundAttributeDeclarationWithName attributeName: String, forElement elementName: String, type: String?, defaultValue: String?) {
        Log.test("foundAttributeDeclarationWithName == attributeName:\(attributeName), elementName:\(elementName), type:\(type)")
    }
    
    @objc public func parser(_ parser: XMLParser, foundElementDeclarationWithName elementName: String, model: String) {
        Log.test("foundElementDeclarationWithName == elementName:\(elementName), model:\(model)")
    }
    
    @objc public func parser(_ parser: XMLParser, foundInternalEntityDeclarationWithName name: String, value: String?) {
        Log.test("foundInternalEntityDeclarationWithName == name:\(name), value:\(value)")
    }
    
    @objc public func parser(_ parser: XMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?, systemID: String?) {
        Log.test("foundExternalEntityDeclarationWithName == name:\(name) ")
    }
    
    @objc public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        //Log.test("didStartElement == elementName:\(elementName) ")
        
        if ( elementName == "sec:ProductCap" || elementName == "friendlyName" || elementName  == "UDN" ) {
            currentElementName = elementName
        }
    }
    
    @objc public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        //Log.test("didEndElement == elementName:\(elementName) ")
    }
    
    @objc public func parser(_ parser: XMLParser, didStartMappingPrefix prefix: String, toURI namespaceURI: String) {
        Log.test("didStartMappingPrefix == prefix:\(prefix) ")
    }
    
    @objc public func parser(_ parser: XMLParser, didEndMappingPrefix prefix: String) {
        Log.test("didEndMappingPrefix == prefix:\(prefix) ")
    }
    
    @objc public func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch (currentElementName) {
        case "sec:ProductCap":
            if (string.contains("Y2017")){
                discoveredTV.year = "2017"
            }
            if (string.contains("vdProductType=TV")){
                discoveredTV.vdProductType = "TV"
            }
            if (string.contains("OCF=1")){
                discoveredTV.isOCF = true
            }
            break
        case "friendlyName":
            discoveredTV.friendlyName = string
            break
        case "UDN":
            discoveredTV.udn = string
            break
        default:
            break
        }
        currentElementName = ""
        
    }
    
    @objc public func parser(_ parser: XMLParser, foundIgnorableWhitespace whitespaceString: String) {
        Log.test("foundIgnorableWhitespace == whitespaceString:\(whitespaceString) ")
    }
    
    @objc public func parser(_ parser: XMLParser, foundProcessingInstructionWithTarget target: String, data: String?) {
        Log.test("foundProcessingInstructionWithTarget == target:\(target) ")
    }
    
    @objc public func parser(_ parser: XMLParser, foundComment comment: String) {
        Log.test("foundComment == comment:\(comment) ")
    }
    
    
    @objc public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        Log.test("parseErrorOccurred == name:\(parseError) ")
    }
    
    @objc public func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        Log.test("validationErrorOccurred == name:\(validationError) ")
    }
}

