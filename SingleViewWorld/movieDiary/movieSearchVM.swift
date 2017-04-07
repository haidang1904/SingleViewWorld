//
//  movieSearchVC.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 07/02/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import SDWebImage
import RealmSwift

// Client ID : MIxoONv5MR9tqGoUlLrf
// Client Secret : CwVvqL2Nky

class movieSearchVM {

    let nAPIclientID = "MIxoONv5MR9tqGoUlLrf"
    let nAPIclientSecret = "CwVvqL2Nky"
    let nAPImovieSearchURLJson = "https://openapi.naver.com/v1/search/movie.json"
    var queue: DispatchQueue? = nil
    var nAPIheader : HTTPHeaders? = nil
    var nAPIparameter : Parameters? = nil
    var resultList : [[String:Any]] = [[String:Any]]()
    var resultCount : Int = 0
    var resultDisplay : Int = 0
    let displayCount : Int = 100
    
    fileprivate let isSearchSubject = BehaviorSubject<Bool>(value: false)
    internal var isSearch: Observable<Bool> {
        return isSearchSubject.asObservable()
    }
    
    fileprivate let isDownloadImageSubject = BehaviorSubject<Bool>(value: false)
    internal var isDownloadImage: Observable<Bool> {
        return isDownloadImageSubject.asObservable()
    }
    
    init() {
        self.queue = DispatchQueue(label: "movieDiarySearchQueue")
        self.nAPIheader = ["X-Naver-Client-ID":"MIxoONv5MR9tqGoUlLrf","X-Naver-Client-Secret":"CwVvqL2Nky"]
            
        //Log.test("movieDiaryVM initialized")
    }
    
    
    func sendSearchAPItoNaver(keyword: String) {
        
        self.resultList.removeAll()
        self.resultCount = 0
        
        let urlString : String = "\(nAPImovieSearchURLJson)"
        let url = URL(string: urlString)
        self.nAPIparameter = ["query":keyword,"display":displayCount]
        
        queue?.async(execute: {
            
            Alamofire.request(url!, method: .get, parameters: self.nAPIparameter, encoding: URLEncoding.default, headers: self.nAPIheader)
                .response(completionHandler: {[weak self] (data) in
                    //Log.test("request \(data.request?.url?.absoluteString) is received")
                    if let _ = data.response, data.response?.statusCode == 200 {
                        self?.parsingData(data: data.data!, ip:(data.request?.url?.absoluteString)!)
                    }
                })
        })
    }
    
    func parsingData(data:Data, ip:String) {
        do {
            if let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                if let resultList = jsonResult["items"] as? [[String:Any]], let resultCount = jsonResult["total"] as? Int, resultCount > 0 {
                    Log.test("There are \(resultCount) results")
                    self.resultList = resultList
                    self.resultCount = resultCount
                    isSearchSubject.onNext(true)
                    self.storeImageToCache(datas: self.resultList, count: self.resultCount)
                } else {
                    Log.test("There are \(resultCount) results")
                    isSearchSubject.onNext(false)
                }
            }
        } catch {
            isSearchSubject.onNext(false)
            Log.test("json parse error")
        }
    }
    
    func storeImageToCache(datas:[[String:Any]], count:Int) {
        
        for data in datas {
            if let iconpath = data["image"] as? String {
                if (!customImageManager.sharedInstance.imageCache.diskImageExists(withKey: iconpath)) && (iconpath != "") {
                    Log.test("\(iconpath) is not exist")
                    let url = NSURL(string: iconpath)!
                    customImageManager.sharedInstance.imageManager
                        .downloadImage(with: url as URL! ,
                                       options: .retryFailed,
                                       progress: nil,
                                       completed: { [weak self] (image, error, cacheType, finished, url) in
                                        if image != nil  && finished {
                                            //Log.test("\(iconpath) download complete \(cacheType)")
                                            customImageManager.sharedInstance.imageCache.store(image, forKey: iconpath)
                                            self?.isDownloadImageSubject.onNext(true)
                                        }
                    })
                }
            }
        }
    }
    
    func getName(_ index:Int) -> String {
        if (self.resultList.count) > index {
            if let title = self.resultList[index]["title"] as? String {
                return String(htmlEncodedString: title)
            } else {
                return ""
            }
        } else {
            return ""
        }
    }
    
    func getImage(_ index:Int) -> UIImage {
        let placeholder : UIImage = UIImage(named: "poster_placeholder")!
        
        if (self.resultList.count) > index {
            if let iconPath = self.resultList[index]["image"] as? String {
                if let image = customImageManager.sharedInstance.imageCache.imageFromDiskCache(forKey: iconPath) {
                    //Log.test("\(iconPath) image in DiskCache")
                    return image
                } else if let image = customImageManager.sharedInstance.imageCache.imageFromMemoryCache(forKey: iconPath) {
                    //Log.test("\(iconPath) image in MemoryCache")
                    return image
                }
            }
        }
        return placeholder
    }
    
    func getMovieInfo(_ index:Int) -> MovieModel? {
        let title = getName(index)
        if let model = isSaved(title: title) {
            Log.test("\(title) already saved movie in \(model.isBucketList.value)")
            return model
        }
        
        if (self.resultList.count) > index {
            return createMovieModel(data: resultList[index])
        } else {
            return nil
        }
    }
    
    func getResultCount() -> Int {
        return self.resultCount
    }
    
    func createMovieModel(data : [String:Any]) -> MovieModel? {
        let movieModel = MovieModel()
        if let title = data["title"] as! String! {
            movieModel.title = String(htmlEncodedString: title)
        } else {
            return nil
        }
        movieModel.subtitle = data["subtitle"] as? String? ?? "nil"
        movieModel.pubDate = data["pubDate"] as? String? ?? "nil"
        movieModel.director = data["director"] as? String? ?? "nil"
        movieModel.actor = data["actor"] as? String? ?? "nil"
        movieModel.image = data["image"] as? String? ?? "nil"
        movieModel.link = data["link"] as? String? ?? "nil"
        movieModel.userRating = data["userRating"] as? String? ?? "nil"
        movieModel.comment = data["comment"] as? String? ?? "nil"
        movieModel.dateOfWatch = data["dateOfWatch"] as? String? ?? "nil"
        movieModel.isBucketList.value = nil
        return movieModel
    }
    
    func isSaved(title:String) -> MovieModel? {
        
        let realm = try! Realm()
        if let object = realm.objects(MovieModel.self).filter("title == %@", title).first {
            return object
        }
        return nil
    }
    
}
//let dictionary = try JSONSerialization.jsonObject(with: dataOK, options: JSONSerialization.ReadingOptions()) as AnyObject!
