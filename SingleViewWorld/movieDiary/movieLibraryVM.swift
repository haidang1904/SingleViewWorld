//
//  movieLibraryVM.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 20/02/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import Foundation
import RealmSwift

class movieLibraryVM {
    
    var movieObject : [MovieModel] = [MovieModel]()
    
    init(isWatched : Int) {
        //Log.test("movieLibraryVM initialized")
        getFromDB(isWatched: isWatched)
        Log.test("movieLibraryVM init")
    }
    
    func getFromDB(isWatched : Int) {
        //Log.test("movieLibraryVM getFromDB()")
        movieObject.removeAll()
        let realm = try! Realm()
        let movies = realm.objects(MovieModel.self).filter("isWatched = %@", isWatched)
        for movie in movies {
            movieObject.append(movie)
        }
    }
    
    func getCount() -> Int {
        return movieObject.count
    }
    
    func getTitleForIndex(indexPath: IndexPath) -> String {
        
        if movieObject.count > indexPath.row {
            if let title = movieObject[indexPath.row]["title"] as? String {
                return String(htmlEncodedString: title)
            }
        }
        return "no Title"
    }
    
    func getTitleForPage(index: Int) -> String {
        
        if index == 0 {
            return "Watched Movie"
        } else {
            return "Bucket List"
        }
    }
    
    func getMovieInfo(indexPath: IndexPath) -> MovieModel? {
        if movieObject.count > indexPath.row {
            return movieObject[indexPath.row]
        }
        return nil
    }
    
    
    func getImageForIndex(indexPath : IndexPath) -> UIImage {
        var placeholder : UIImage = UIImage(named: "poster_placeholder")!
        
        if movieObject.count > indexPath.row {
            if let iconPath = movieObject[indexPath.row]["image"] as? String {
                if let image = customImageManager.sharedInstance.imageCache.imageFromDiskCache(forKey: iconPath) {
                    placeholder = image
                } else if let image = customImageManager.sharedInstance.imageCache.imageFromMemoryCache(forKey: iconPath) {
                    placeholder = image
                } else {
                    let url = NSURL(string: iconPath)!
                    customImageManager.sharedInstance.imageManager
                        .downloadImage(with: url as URL! ,
                                       options: .retryFailed,
                                       progress: nil,
                                       completed: {(image, error, cacheType, finished, url) in
                                        if image != nil  && finished {
                                            customImageManager.sharedInstance.imageCache.store(image, forKey: iconPath)
                                        }
                        })
                }
            }
        }
        return placeholder
    }
}
