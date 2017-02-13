//
//  MovieModel.swift
//  SingleViewWorld
//
//  Created by HYOJAE LEE on 2017. 2. 7..
//  Copyright © 2017년 samsung. All rights reserved.
//

import Foundation

open class MovieModel {
    var actor: String = ""
    var director: String = ""
    var image: String = ""
    var link: Int = 0
    var subtitle: String = ""
    var title: String = ""
    var userRating: String = ""
    
    init?(data: [String:Any]?) {
        if let title = data?["title"] as? String{
            self.title = title
        }
    }
    
    var description: String {
        return "MovieModel title \(title)  subtitle \(subtitle) director \(director) actor \(actor)"
    }
}
