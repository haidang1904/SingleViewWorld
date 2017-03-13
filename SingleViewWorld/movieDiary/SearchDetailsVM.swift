//
//  SearchDetailsVM.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 13/02/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import Foundation
import RealmSwift

public enum SearchDetailErrorType {
    case saved                  // save successfully into the DB
    case deleted                // delete successfully from the DB
    case existWatched           // already exist watched list in the DB
    case existBucket            // already exist bucket list in the DB
    case moveToWatched          // move from Bucket to Watched
    case canNotMoveToBucket     // can not move from Watched to Bucket
    case notExist               // not exist in the DB
    
    case unknown
}

public enum savedType {
    case watchedList
    case bucketList
    case none
}

protocol SearchDetailDelegate {
    func eventHandler(code:SearchDetailErrorType)
}

extension SearchDetailDelegate {
    func eventHandler(code:SearchDetailErrorType) {
        Log.test("")
    }
}

class SearchDetailsVM {
    var movieDetail: MovieModel?
    var movieDelegate: SearchDetailDelegate? = nil
    
    init (detail : MovieModel?) {
        self.movieDetail = detail
    }
    
    func saveMovie(isWatched : Int) {
        Log.test("saveMovie(\(isWatched))")
        if let movieData = self.movieDetail {
            let realm = try! Realm()
            if let object = realm.objects(MovieModel.self).filter("title == %@", movieData.title).first {
                
                if object.isWatched.value == 0 && isWatched == 0 {
                    self.movieDelegate?.eventHandler(code: .existWatched)
                    return
                }
                
                if object.isWatched.value == 1 && isWatched == 1 {
                    self.movieDelegate?.eventHandler(code: .existBucket)
                    return
                }

                if object.isWatched.value == 0 && isWatched == 1 {
                    self.movieDelegate?.eventHandler(code: .canNotMoveToBucket)
                    return
                }
                
                if object.isWatched.value == 1 && isWatched == 0 {
                    try! realm.write {
                        object.isWatched.value = isWatched
                        realm.add(object, update: true)
                        self.movieDetail?.isWatched.value = isWatched
                        self.movieDelegate?.eventHandler(code: .moveToWatched)
                    }
                }
            } else {
                realm.beginWrite()
                movieData.isWatched.value = isWatched
                realm.create(MovieModel.self, value: movieData, update: true)
                try! realm.commitWrite()
                self.movieDetail?.isWatched.value = isWatched
                self.movieDelegate?.eventHandler(code: .saved)
            }
        }
    }
    
    func deleteMovie() {
        Log.test("deleteMovie(\(self.movieDetail?.title))")
        if let movieData = self.movieDetail {
            let realm = try! Realm()
            if let _ = realm.objects(MovieModel.self).filter("title == %@", movieData.title).first {
                realm.beginWrite()
                realm.delete(movieData)
                try! realm.commitWrite()
                self.movieDelegate?.eventHandler(code: .deleted)
            } else {
                //self.movieDelegate?.eventHandler(code: .notExist)
            }
        }
    }
    
    func isSaved() -> savedType {
        
        if let movieData = self.movieDetail {
            let realm = try! Realm()
            if let object = realm.objects(MovieModel.self).filter("title == %@", movieData.title).first {
                if object.isWatched.value == 0 {
                    self.movieDelegate?.eventHandler(code: .existWatched)
                    return .watchedList
                } else {
                    self.movieDelegate?.eventHandler(code: .existBucket)
                    return .bucketList
                }
            } else {
                self.movieDelegate?.eventHandler(code: .notExist)
                return .none
            }
        }
        
        self.movieDelegate?.eventHandler(code: .unknown)
        return .none
    }
}
