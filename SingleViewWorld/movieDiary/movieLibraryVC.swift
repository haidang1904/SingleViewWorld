//
//  movieLibraryVC.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 20/02/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import UIKit

class movieLibraryVC: UIViewController {

    var pageIndex = 0
    var viewModel : movieLibraryVM? = nil
    var showDetailView: ((_ selectedMovie: MovieModel?) -> Void)? = nil
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var movieLibraryCollection: UICollectionView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel?.getFromDB(isWatched: pageIndex)
        titleLabel.text = viewModel?.getTitleForPage(index: pageIndex)
        movieLibraryCollection.reloadData()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = movieLibraryVM(isWatched: pageIndex)
        // Do any additional setup after loading the view.
    }
        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension movieLibraryVC : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        collectionView.deselectItem(at: indexPath, animated: false)
        Log.test("didSelectItemAt \(indexPath.row)")
        if let movieInfo = viewModel?.getMovieInfo(indexPath: indexPath) {
            
            self.showDetailView?(movieInfo)
        }
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = CGSize(width: collectionView.frame.size.width * 0.3 , height: (((collectionView.frame.size.width * 0.3) / 110 ) * 158) )
        return size
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return viewModel!.getCount()
    }
    

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell : movieLibraryCell = collectionView.dequeueReusableCell(withReuseIdentifier: "movieLibraryCell", for: indexPath) as! movieLibraryCell
        cell.imageView.image = viewModel!.getImageForIndex(indexPath: indexPath)
        cell.labelView.text = viewModel!.getTitleForIndex(indexPath: indexPath)
        return cell
    }
    
//    _cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
//    if (_cell == nil) {
//    _cell = [[MenuCollectionViewCell alloc] init];
//    }
//    
//    _cell.backgroundColor = [UIColor lightGrayColor];
//    _cell.label.text = [self dispMenu:indexPath.row];
//    
//    //CALayer *mylayer = [_cell layer];
//    //[mylayer setCornerRadius:10];
//    
//    return _cell;
}



