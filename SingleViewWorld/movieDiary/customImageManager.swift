//
//  customImageManager.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 09/02/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import Foundation
import SDWebImage

class customImageManager {
    
    open let imageCache: SDImageCache
    open let imageManager: SDWebImageManager
    
    static let sharedInstance = customImageManager()
    
    private init() {
        
        imageCache = SDImageCache(namespace: "com.hyodolski.movieDiary.cache", diskCacheDirectory: NSTemporaryDirectory())
        imageManager = SDWebImageManager(cache: imageCache, downloader: SDWebImageDownloader())
    }
}
