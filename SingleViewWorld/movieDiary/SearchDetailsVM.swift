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
    
    func saveMovie(watchDate:String) {
        self.saveMovie(watchDate:watchDate, comment:"", isBucketList:0)
    }
    
    func saveMovie(watchDate:String, comment:String) {
        self.saveMovie(watchDate:watchDate, comment:comment, isBucketList:0)
    }
    
    func saveMovieForBucket() {
        self.saveMovie(watchDate:"", comment:"", isBucketList: 1)
    }
    
    private func saveMovie(watchDate : String , comment: String, isBucketList : Int) {
        Log.test("saveMovie to \(isBucketList) date is \"\(watchDate)\"")
        if let movieData = self.movieDetail {
            let realm = try! Realm()
            if let object = realm.objects(MovieModel.self).filter("title == %@", movieData.title).first {
                
                if isBucketList == 1 {
                    if object.isBucketList.value == 0 {
                        self.movieDelegate?.eventHandler(code: .canNotMoveToBucket)
                    } else {
                        self.movieDelegate?.eventHandler(code: .existBucket)
                    }
                    return
                }

                try! realm.write {
                    object.isBucketList.value = isBucketList
                    object.dateOfWatch = watchDate
                    object.comment = comment
                    realm.add(object, update: true)
                    self.movieDetail?.isBucketList.value = isBucketList
                }
                
            } else {
                realm.beginWrite()
                movieData.isBucketList.value = isBucketList
                movieData.dateOfWatch = watchDate
                movieData.comment = comment
                realm.create(MovieModel.self, value: movieData, update: true)
                try! realm.commitWrite()
                self.movieDetail?.isBucketList.value = isBucketList
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
                if object.isBucketList.value == 0 {
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
