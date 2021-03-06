//
//  MovieModel.swift
//  SingleViewWorld
//
//  Created by HYOJAE LEE on 2017. 2. 7..
//  Copyright © 2017년 samsung. All rights reserved.
//

import Foundation
import RealmSwift

class MovieModel : Object {
    @objc dynamic var title: String! = ""
    @objc dynamic var subtitle: String? = nil
    @objc dynamic var pubDate : String? = nil
    @objc dynamic var director: String? = nil
    @objc dynamic var actor: String? = nil
    @objc dynamic var image: String? = nil
    @objc dynamic var link: String? = nil
    @objc dynamic var userRating: String? = nil
    @objc dynamic var comment: String? = nil
    @objc dynamic var dateOfWatch: String? = nil
    let isBucketList = RealmOptional<Int>()
    
    override class func primaryKey() -> String? {
        return "title"
    }
    
    /*
    init(data: [String:Any]) {

        title = data["title"] as? String? ?? "nil"
        subtitle = data["subtitle"] as? String? ?? "nil"
        pubDate = data["pubDate"] as? String? ?? "nil"
        director = data["director"] as? String? ?? "nil"
        actor = data["actor"] as? String? ?? "nil"
        image = data["image"] as? String? ?? "nil"
        link = data["link"] as? String? ?? "nil"
        userRating = data["userRating"] as? String? ?? "nil"
        comment = data["comment"] as? String? ?? "nil"
        dateOfWatch = data["dateOfWatch"] as? String? ?? "nil"
        
//        if let actor = data["actor"] as? String{
//            self.actor = actor
//        }
//        if let director = data["director"] as? String{
//            self.director = director
//        }
//        if let image = data["image"] as? String{
//            self.image = image
//        }
//        if let link = data["link"] as? String{
//            self.link = link
//        }
//        if let pubDate = data["pubDate"] as? String{
//            self.pubDate = pubDate
//        }
//        if let subtitle = data["subtitle"] as? String{
//            self.subtitle = subtitle
//        }
//        if let title = data["title"] as? String{
//            self.title = title
//        }
//        if let userRating = data["userRating"] as? String{
//            self.userRating = userRating
//        }
    }
     */
    

}

extension MovieModel {
    override var description: String {
        return "MovieModel title \(title) director \(String(describing: director)) pubDate \(String(describing: pubDate))"
    }
}
