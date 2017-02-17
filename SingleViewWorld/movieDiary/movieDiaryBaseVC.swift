//
//  movieDiaryBaseVC.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 13/02/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import UIKit
import RxSwift

class movieDiaryBaseVC: UIViewController {

    let disposeBag = DisposeBag()
    let viewModel = movieDiaryBaseVM()
    var selectedMovieItem : MovieModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setCustomButtonOnNavigationBar()
        
        viewModel.printMovieListInDB()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "SearchSegue" {
             
            let vc = segue.destination as! movieDiaryVC
            vc.showDetailView = {
                [weak self] details in
                self?.selectedMovieItem = details
                self?.performSegue(withIdentifier: "SearchDetailSegue", sender: nil)
            }
            
        } else if segue.identifier == "SearchDetailSegue" {
            let searchDetailVC = segue.destination as! SearchDetailsVC
            searchDetailVC.viewModel = SearchDetailsVM(detail: self.selectedMovieItem)
        }
    }
    
    @IBAction func backFromOtherController(segue: UIStoryboardSegue) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func presentSearch(_ sender: AnyObject) {
        //viewModel.printMovieListInDB()
        performSegue(withIdentifier: "SearchSegue", sender: nil)
    }
    
    func setCustomButtonOnNavigationBar() {
        let buttonItem : UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "Search_Icon"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(movieDiaryBaseVC.presentSearch(_:)))
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationItem.setRightBarButton(buttonItem, animated: false)
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
