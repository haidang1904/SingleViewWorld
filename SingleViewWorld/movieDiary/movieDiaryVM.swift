//
//  movieDiaryVM.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 07/02/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import SDWebImage

// Client ID : MIxoONv5MR9tqGoUlLrf
// Client Secret : CwVvqL2Nky

class movieDiaryVM {

    let nAPIclientID = "MIxoONv5MR9tqGoUlLrf"
    let nAPIclientSecret = "CwVvqL2Nky"
    let nAPImovieSearchURLJson = "https://openapi.naver.com/v1/search/movie.json"
    var queue: DispatchQueue? = nil
    var nAPIheader : HTTPHeaders? = nil
    var nAPIparameter : Parameters? = nil
    var resultList : [[String:Any]]? = nil
    var resultCount : Int = 0
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
            
        Log.test("movieDiaryVM initialized")
    }
    
    
    func sendSearchAPItoNaver(keyword: String) {
        
        self.resultList?.removeAll()
        self.resultCount = 0
        
        let urlString : String = "\(nAPImovieSearchURLJson)"
        let url = URL(string: urlString)
        self.nAPIparameter = ["query":keyword,"display":displayCount]
        
        queue?.async(execute: {
            
            Alamofire.request(url!, method: .get, parameters: self.nAPIparameter, encoding: URLEncoding.default, headers: self.nAPIheader)
                .response(completionHandler: {[weak self] (data) in
                    Log.test("request \(data.request?.url?.absoluteString) is received")
                    Log.test("response data \(data.data)")
                    if let _ = data.response, data.response?.statusCode == 200 {
                        self?.parsingData(data: data.data!, ip:(data.request?.url?.absoluteString)!)
                    }
                })
        })
    }
    
    func parsingData(data:Data, ip:String) {
        do {
            if let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                if let resultListTemp = jsonResult["items"] as? [[String:Any]], let resultCountTemp = jsonResult["total"] as? Int {
                    self.resultList = resultListTemp
                    self.resultCount = resultCountTemp
                    isSearchSubject.onNext(true)
                    self.storeImageToCache(datas: self.resultList!, count: self.resultCount)
                } else {
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
                if !customImageManager.sharedInstance.imageCache.diskImageExists(withKey: iconpath) {
                    Log.test("\(iconpath) is not exist")
                    let url = NSURL(string: iconpath)!
                    customImageManager.sharedInstance.imageManager
                        .downloadImage(with: url as URL! ,
                                       options: .retryFailed,
                                       progress: nil,
                                       completed: { [weak self] (image, error, cacheType, finished, url) in
                                        if image != nil  && finished {
                                            Log.test("\(iconpath) download complete \(cacheType)")
                                            customImageManager.sharedInstance.imageCache.store(image, forKey: iconpath)
                                            self?.isDownloadImageSubject.onNext(true)
                                        }
                    })
                }
            }
        }
    }
    
    func getName(_ index:Int) -> String? {
        if (self.resultList?.count)! > index {
            if let title = self.resultList?[index]["title"] as? String {
                var movieName = title
                movieName = movieName.replacingOccurrences(of: "<b>", with: "")
                movieName = movieName.replacingOccurrences(of: "</b>", with: "")
            return movieName
            } else {
                return ""
            }
        } else {
            return ""
        }
    }
    
    func getImage(_ index:Int) -> UIImage? {
        let placeholder : UIImage = UIImage(named: "poster_placeholder")!
        
        if (self.resultList?.count)! > index {
            if let iconPath = self.resultList?[index]["image"] as? String {
                if let image = customImageManager.sharedInstance.imageCache.imageFromDiskCache(forKey: iconPath) {
                    Log.test("\(iconPath) image in DiskCache")
                    return image
                } else if let image = customImageManager.sharedInstance.imageCache.imageFromMemoryCache(forKey: iconPath) {
                    Log.test("\(iconPath) image in MemoryCache")
                    return image
                } else {
                    return placeholder
                }
            } else {
                return placeholder
            }
        } else {
            return placeholder
        }
    }
    
    func getMovieInfo(_ index:Int) -> MovieModel? {
        // to do
        if let movieData = self.resultList?[index] {
                return MovieModel(data: movieData)
        } else {
            return MovieModel(data: nil)
        }
    }
    
    func getResultCount() -> Int {
        return self.resultCount
    }
    
}
//let dictionary = try JSONSerialization.jsonObject(with: dataOK, options: JSONSerialization.ReadingOptions()) as AnyObject!
