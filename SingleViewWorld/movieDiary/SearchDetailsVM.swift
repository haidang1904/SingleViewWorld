//
//  SearchDetailsVM.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 13/02/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import Foundation
import RealmSwift


protocol SearchDetailDelegate {
    func didSaveMovie()
    func didDeleteMovie()
}


class SearchDetailsVM {
    var movieDetail: MovieModel?
    var movieDelegate: SearchDetailDelegate? = nil
    
    init (detail : MovieModel?) {
        self.movieDetail = detail
    }
    
    func saveMovie() {
        Log.test("saveMovie()")
        if let movieData = self.movieDetail {
            let realm = try! Realm()
            if let _ = realm.objects(MovieModel.self).filter("title == %@", movieData.title).first {
                Log.test("\(movieData.title) is already exist in the DB")
            } else {
                realm.beginWrite()
                realm.create(MovieModel.self, value: movieData, update: true)
                try! realm.commitWrite()
                self.movieDelegate?.didSaveMovie()
            }
        }
    }
    
    func deleteMovie() {
        Log.test("deleteMovie()")
        if let movieData = self.movieDetail {
            let realm = try! Realm()
            if let _ = realm.objects(MovieModel.self).filter("title == %@", movieData.title).first {
                realm.beginWrite()
                realm.delete(movieData)
                try! realm.commitWrite()
                self.movieDelegate?.didDeleteMovie()
            } else {
                Log.test("\(movieData.title) is not exist in the DB")
            }
        }
    }
    
    func isSaved() -> Bool {
        
        if let movieData = self.movieDetail {
            let realm = try! Realm()
            if let _ = realm.objects(MovieModel.self).filter("title == %@", movieData.title).first {
                Log.test("\(movieData.title) is already exist in the DB")
                return true
            } else {
                Log.test("\(movieData.title) is not exist in the DB")
                return false
            }
        }
        
        return false
    }
}
