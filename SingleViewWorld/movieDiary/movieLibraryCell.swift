//
//  movieLibraryCell.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 20/02/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import UIKit

class movieLibraryCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelView: UILabel!
    @IBOutlet weak var deleteImageView: UIImageView!
    
    override func prepareForReuse() {
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.labelView.backgroundColor = UIColor.black
        self.labelView.textColor = UIColor.white
        self.labelView.alpha = 0.65
        
        // Initialization code
    }
    
}
