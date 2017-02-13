//
//  SearchResultVM.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 13/02/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import Foundation

class SearchDetailsVM {
    var movieItem : MovieModel?
    
    init(item: MovieModel?) {
        self.movieItem = item
    }
    
    func numberOfRowsInSection(_ section: Int) -> Int {
        return 0
    }
    
}
