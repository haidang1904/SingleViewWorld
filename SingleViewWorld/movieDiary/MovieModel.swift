//
//  MovieModel.swift
//  SingleViewWorld
//
//  Created by HYOJAE LEE on 2017. 2. 7..
//  Copyright © 2017년 samsung. All rights reserved.
//

import Foundation

open class MovieModel {
    var actor: String?
    var director: String?
    var image: String?
    var link: String?
    var pubDate : String?
    var subtitle: String?
    var title: String?
    var userRating: String?
    
    init?(data: [String:Any]) {

        if let actor = data["actor"] as? String{
            self.actor = actor
        }
        if let director = data["director"] as? String{
            self.director = director
        }
        if let image = data["image"] as? String{
            self.image = image
        }
        if let link = data["link"] as? String{
            self.link = link
        }
        if let pubDate = data["pubDate"] as? String{
            self.pubDate = pubDate
        }
        if let subtitle = data["subtitle"] as? String{
            self.subtitle = subtitle
        }
        if let title = data["title"] as? String{
            self.title = title
        }
        if let userRating = data["userRating"] as? String{
            self.userRating = userRating
        }

    }
    
    var description: String {
        return "MovieModel title \(title)  subtitle \(subtitle) director \(director) actor \(actor) pubDate \(pubDate) userRating \(userRating) link \(link) image \(image)"
    }
}
