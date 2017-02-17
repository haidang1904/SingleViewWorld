//
//  movieDiaryBaseVM.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 13/02/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import Foundation
import RealmSwift

class movieDiaryBaseVM {
    
    
    init() {
        Log.test("movieDiaryBaseVM initialized")
    }
    
    func printMovieListInDB () {
        let realm = try! Realm()
        let movies = realm.objects(MovieModel.self)
        Log.test("\(movies.count) movies are in the DB")
        for movie in movies {
            Log.test("\(movie.title) is in the DB")
        }
    }
    
//    fileprivate func compactRealm() {
//        autoreleasepool {
//            do {
//                let defaultURL = Realm.Configuration.defaultConfiguration.fileURL!
//                let defaultParentURL = defaultURL.deletingLastPathComponent()
//                let compactedURL = defaultParentURL.appendingPathComponent("default-compact.realm")
//                let realm = try Realm()
//                try realm.writeCopy(toFile: compactedURL as URL)
//                //(compactedURL)
//                try FileManager.default.removeItem(at: defaultURL)
//                try FileManager.default.moveItem(at: compactedURL, to: defaultURL)
//            } catch {
//                do {
//                    let defaultURL = Realm.Configuration.defaultConfiguration.fileURL!
//                    try FileManager.default.removeItem(at: defaultURL)
//                } catch {}
//            }
//            
//        }
//    }
//    
//    fileprivate func migrateRealm() {
//        Realm.Configuration.defaultConfiguration.deleteRealmIfMigrationNeeded = true
//        
//        let migrationBlock: MigrationBlock = {  migration, oldSchemaVersion in
//            // We haven’t migrated anything yet, so oldSchemaVersion == 0
//            switch oldSchemaVersion {
//            case 1:
//                break
//            default:
//                //TODO: your migration goes here
//                print("migration")
//            }
//        }
//        Realm.Configuration.defaultConfiguration = Realm.Configuration(schemaVersion: 1, migrationBlock: migrationBlock)
//    }
}
