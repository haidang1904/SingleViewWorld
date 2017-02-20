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
    
}
