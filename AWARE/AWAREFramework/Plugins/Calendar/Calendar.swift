//
//  Calendar.swift
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/12/24.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

import UIKit

class Calendar: AWARESensor {
    
    //////////// Keys //////////////
    let ACCOUNT_NAME = "account_name"
    let ALL_DAY      = "all_day"
    // let AVAILABILITY = "availability"
    let BEGIN        = "begin"
    // let CALENDAR_COLOR       = "calendar_color"
    let CALENDAR_DESCRIPTION = "calenadr_description"
    let CALENDAR_ID          = "calendar_id"
    let CALENDAR_NAME        = "calendar_name"
    let END                  = "end"
    let EVENT_ID             = "event_id"
    let EVENT_TIMEZONE       = "event_timezone"
    let LOCATION             = "location"
    let OWNER_ACCOUNT        = "owner_account"
    let STATUS               = "status"
    let TITLE                = "title"
    let NOTE                 = "note"
    
    ///////// For Calendar API ///////
    let eventStore = EKEventStore()
    
    required init?(coder aDecoder: NSCoder) {
        // fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)
    }
    
    override init() {
        super.init()
    }
    
    required init!(awareStudy study: AWAREStudy!, sensorName name: String!) {
        // fatalError("init(awareStudy:sensorName:) has not been implemented")
        super.init(awareStudy: study, dbType: AwareDBTypeCoreData)
    }
    
    override init!(awareStudy study: AWAREStudy!, dbType: AwareDBType) {
        super.init(awareStudy: study,
                 sensorName: "calendar",
                    dbEntityName: NSStringFromClass(EntityCalendar.classForCoder()),
                    dbType: AwareDBTypeCoreData)
    }
    
    override init!(awareStudy study: AWAREStudy!, sensorName name: String!, dbEntityName entity: String!, dbType: AwareDBType, bufferSize buffer: Int32) {
        super.init(awareStudy: study,
                   sensorName: name,
                   dbEntityName: entity,
                   dbType: dbType,
                   bufferSize: buffer)
    }
    
    ////////////////// Common AWARE Methods /////////////////
    
    override func createTable() {
        /// make a create table query
        let tcqMaker = TCQMaker()
        tcqMaker.addColumn(ACCOUNT_NAME,      type: TCQTypeText, default: "")
        tcqMaker.addColumn(ALL_DAY,           type: TCQTypeBlob, default: "")
        tcqMaker.addColumn(BEGIN,             type: TCQTypeText, default: "")
        tcqMaker.addColumn(CALENDAR_DESCRIPTION, type: TCQTypeText, default:"")
        tcqMaker.addColumn(CALENDAR_ID,       type: TCQTypeText, default: "")
        tcqMaker.addColumn(CALENDAR_NAME,     type: TCQTypeText, default: "")
        tcqMaker.addColumn(END,               type: TCQTypeText, default: "")
        tcqMaker.addColumn(EVENT_ID,          type: TCQTypeText, default: "")
        tcqMaker.addColumn(EVENT_TIMEZONE,    type: TCQTypeText, default: "")
        tcqMaker.addColumn(LOCATION,          type: TCQTypeText, default: "")
        tcqMaker.addColumn(OWNER_ACCOUNT,     type: TCQTypeText, default: "")
        tcqMaker.addColumn(STATUS,            type: TCQTypeText, default: "")
        tcqMaker.addColumn(TITLE,             type: TCQTypeText, default: "")
        tcqMaker.addColumn(NOTE,              type: TCQTypeText, default: "")
        super.createTable(tcqMaker.getDefaudltTableCreateQuery())
    }
    
    override func startSensor(withSettings settings: [Any]!) -> Bool {
        
        /// Authorize
        if !getAuthorization_status(){
            allowAuthorization()
        }

        /// Get a setting of the calendar plugin
        
        /// Subscribe calendar update notifications
        
        // TODO: just for test
//        let calendars = eventStore.calendars(for: .event)
//        for calendar in calendars{
//            print(calendar)
//        }
        
        // NotificationCenter.default.addObserver(self, selector: #selector(self.update), name: .EKEventStoreChanged, object: eventStore)
        NotificationCenter.default.addObserver(self, selector: #selector(self.eventStoreChanged), name: .EKEventStoreChanged, object: eventStore)
        
        return true
    }
    
    override func stopSensor() -> Bool {
        NotificationCenter.default.removeObserver(self)
        
        return true
    }
    
    override func insertNewEntity(withData data: [AnyHashable : Any]!, managedObjectContext childContext: NSManagedObjectContext!, entityName entity: String!) {
        let managedObject: AnyObject = NSEntityDescription.insertNewObject(forEntityName: entity, into: childContext)
        
        let model = managedObject as! EntityCalendar
        model.device_id = data["device_id"] as? String
        model.timestamp = data["timestamp"] as? NSNumber
        model.calendar_id = data[CALENDAR_ID] as? String
        model.calendar_name = data[CALENDAR_NAME] as? String
        model.calendar_description = data[CALENDAR_DESCRIPTION] as? String
        model.location = data[LOCATION] as? String
        model.all_day = data[ALL_DAY] as? NSNumber
        model.begin = data[BEGIN] as? String
        model.end = data[END] as? String
        model.event_id = data[EVENT_ID] as? String
        model.owner_account = data[OWNER_ACCOUNT] as? String
        model.account_name = data[ACCOUNT_NAME] as? String
        model.status = data[STATUS] as? String
        model.title = data[TITLE] as? String
        model.note = data[NOTE] as? String
    }
    
    ////////////////// Special Methods /////////////////////////////
    @objc func eventStoreChanged(_ notification: Notification) {
        print("******************** Calendar changed")
//        let startDate = Date()         // will initialise a date object with the current date.
//        print("start date: \(String(describing: startDate))")
//
//        let endDate = startDate.addingTimeInterval(60*60*24*31*3)
//        print("end date: \(String(describing: endDate))")
//
//        // Array of Event changes:
//        let ekEventStoreChangedObjectIDArray = notification.userInfo!["EKEventStoreChangedObjectIDsUserInfoKey"] as! NSArray
//
//        ekEventStoreChangedObjectIDArray.enumerateObjects({ ekEventStoreChangedObjectID, index, stop in
//            //your code
//            print("*** \(ekEventStoreChangedObjectID)")
//        })
//
//        let predicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
//        self.eventStore.enumerateEvents(matching: predicate) { (ekEvent, stop) in
//            print("event: \(ekEvent)")
//        }
        
    }
    
    
    func allowAuthorization() {
        if getAuthorization_status() {
            return
        } else {
            eventStore.requestAccess(to: .event, completion: {
                (granted, error) in
                if granted {
                    return
                }
                else {
                    print("Not allowed")
                }
            })
            
        }
    }
    
    func getAuthorization_status() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .notDetermined:
            print("NotDetermined")
            return false
        case .denied:
            print("Denied")
            return false
        case .authorized:
            print("Authorized")
            return true
        case .restricted:
            print("Restricted")
            return false
        }
    }
    
    
    
}
