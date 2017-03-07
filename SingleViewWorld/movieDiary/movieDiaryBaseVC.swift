//
//  movieDiaryBaseVC.swift
//  SingleViewWorld
//
//  Created by Samsung Electronics on 13/02/2017.
//  Copyright © 2017 samsung. All rights reserved.
//

import UIKit
import RxSwift

@objc open class movieDiaryBaseVC: UIViewController {

    let disposeBag = DisposeBag()
    let viewModel = movieDiaryBaseVM()
    var selectedMovieItem : MovieModel?
    var pageViewController: UIPageViewController? = nil
    var contentVCs = [movieLibraryVC]()
    let sizeOfContentVCs = 2
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        //Log.test("viewDidLoad")
        setCustomButtonOnNavigationBar()
        
        for index in 0 ..< sizeOfContentVCs {
            contentVCs.append(newContentController(pageIndex: index))
        }
        let initialController = contentVCs[0]
        var tapGesture : UITapGestureRecognizer? = nil
        if let gestures = pageViewController?.gestureRecognizers {
            for gesture in gestures {
                if gesture.isKind(of: UITapGestureRecognizer.self) {
                    tapGesture = gesture as? UITapGestureRecognizer
                }
            }
        }
        if tapGesture != nil {
            self.view.removeGestureRecognizer(tapGesture!)
            self.pageViewController?.view.removeGestureRecognizer(tapGesture!)
        }
        pageViewController!.setViewControllers([initialController], direction: .forward, animated: false, completion: nil)
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        //Log.test("viewWillAppear")
    }

    override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "SearchSegue" {
             
            let vc = segue.destination as! movieSearchVC
            vc.showDetailView = {
                [weak self] details in
                self?.selectedMovieItem = details
                self?.performSegue(withIdentifier: "SearchDetailSegue", sender: nil)
            }
            
        } else if segue.identifier == "SearchDetailSegue" {
            let searchDetailVC = segue.destination as! SearchDetailsVC
            searchDetailVC.viewModel = SearchDetailsVM(detail: self.selectedMovieItem)
        } else if segue.identifier == "embededSegue" {
            Log.test("embededSegue")
            pageViewController = segue.destination as? UIPageViewController
            pageViewController!.delegate = self
            pageViewController!.dataSource = self
        }
    }
    
    @IBAction func backFromOtherController(segue: UIStoryboardSegue) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        let vc = self.navigationController?.popViewController(animated: false)
        Log.test("\(vc)")
    }
    
    func presentSearch(_ sender: AnyObject) {
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

extension movieDiaryBaseVC: UIPageViewControllerDelegate {
    
    public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    }
}

extension movieDiaryBaseVC: UIPageViewControllerDataSource {

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let currentVC = viewController as! movieLibraryVC
        let currentIndex = currentVC.pageIndex
        //Log.test("viewControllerBefore \(currentIndex)PAGE")
        if currentIndex == 0 {
            return nil
        } else {
            return contentVCs[0]
        }
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?  {
        let currentVC = viewController as! movieLibraryVC
        let currentIndex = currentVC.pageIndex
        //Log.test("viewControllerAfter \(currentIndex)PAGE")
        if currentIndex == 0 {
            return contentVCs[1]
        } else {
            return nil
        }
    }
    
    
    public func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return sizeOfContentVCs
    }
    
    public func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    func newContentController(pageIndex: Int) -> movieLibraryVC {
        Log.test("newContentController create start")
        let viewController = self.storyboard!.instantiateViewController(withIdentifier: "movieLibraryVC") as! movieLibraryVC
        
        viewController.pageIndex = pageIndex
        viewController.showDetailView = {
            [weak self] details in
            self?.selectedMovieItem = details
            Log.test("performSegue details \(details?.title)")
            self?.performSegue(withIdentifier: "SearchDetailSegue", sender: nil)
        }
        Log.test("newContentController \(viewController.pageIndex)page create end")
        return viewController
    }
}
