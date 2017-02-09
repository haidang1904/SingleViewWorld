//
//  SearchResultCell.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 07/02/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import UIKit

class SearchResultCell: UITableViewCell {

    
    @IBOutlet weak var providerIcon: UIImageView!
    
    @IBOutlet weak var providerDesc: UILabel!
    
    override func prepareForReuse() {
        providerIcon.image = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
