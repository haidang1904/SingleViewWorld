//
//  MovieModel.swift
//  SingleViewWorld
//
//  Created by HYOJAE LEE on 2017. 2. 7..
//  Copyright © 2017년 samsung. All rights reserved.
//

import Foundation

open class MovieModel {
    var title: String!
    var subtitle: String!
    var pubDate : String!
    var director: String!
    var actor: String!
    var image: String!
    var link: String!
    var userRating: String!
    var comment: String!
    var dateOfWatch: String!
    
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
    
    var description: String {
        return "MovieModel title \(title!)  subtitle \(subtitle!) director \(director!) actor \(actor!) pubDate \(pubDate!) comment \(comment) dateOfWatch \(dateOfWatch)"
    }
}
