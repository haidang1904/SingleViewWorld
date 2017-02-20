//
//  SearchDetailsVM.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 13/02/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import Foundation
import RealmSwift

class SearchDetailsVM {
    var movieDetail: MovieModel?
    
    init (detail : MovieModel?) {
        self.movieDetail = detail
    }
    
    func saveMovie() {
        
        // Query and update from any thread
        //DispatchQueue(label: "background").async {
            if let movieData = self.movieDetail {
                let realm = try! Realm()
                if let movieObject = realm.objects(MovieModel.self).filter("title == %@", movieData.title).first {
                    Log.test("\(movieObject.title) is already exist in the DB")
                } else {
                    realm.beginWrite()
                    realm.create(MovieModel.self, value: movieData, update: true)
                    try! realm.commitWrite()
                    Log.test("\(movieData.title) is saved in the DB")
                }
            }
        //}
    }
    
    func deleteMovie() {
        
        // Query and update from any thread
        //DispatchQueue(label: "background").async {
            if let movieData = self.movieDetail {
                let realm = try! Realm()
                if let movieObject = realm.objects(MovieModel.self).filter("title == %@", movieData.title).first {
                    realm.beginWrite()
                    realm.delete(movieObject)
                    try! realm.commitWrite()
                    //Log.test("\(movieData.title) is deleteed successfully from DB")
                } else {
                    Log.test("\(movieData.title) is not exist in the DB")
                }
            }
        //}
    }
}
