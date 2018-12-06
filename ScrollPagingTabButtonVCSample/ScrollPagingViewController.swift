//
//  ScrollPagingViewController.swift
//  ScrollPagingTabButtonVCSample
//
//  Created by park kyung suk on 2018/12/06.
//  Copyright © 2018年 park kyung suk. All rights reserved.
//

import UIKit

protocol ScrollTabPageViewControllerProtocol {
    var scrollTabPageViewController: ScrollPagingViewController { get }
    var scrollView: UIScrollView { get }
}

class ScrollPagingViewController: UIPageViewController {
    
    private let headerAreaHeight: CGFloat = 280
    private let tabViewHeight: CGFloat = 44
    private var pageViewControllers: [UIViewController] = []
    private var contentsView: ContentsView!
    private var scrollContentOffsetY: CGFloat = 0
    private var shouldScrollFrame: Bool = true
    private var shouldUpdateLayout: Bool = false
    private var updateIndex: Int = 0
    private var currentIndex: Int? {
        guard let viewController = viewControllers?.first, let index = pageViewControllers.index(of: viewController) else {
            return nil
        }
        return index
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupOutlets()
    }
}


// MARK: - View
extension ScrollPagingViewController {
    
    private func setupOutlets() {
        setupViewControllers()
        setHeaderView()
        setupPageViewController()
        
        view.addSubview(contentsView)
    }
    
    private func setupViewControllers() {
        let sb1 = UIStoryboard(name: "Main", bundle: nil)
        let vc1 = sb1.instantiateViewController(withIdentifier: "ViewController")
        
        let sb2 = UIStoryboard(name: "Main", bundle: nil)
        let vc2 = sb2.instantiateViewController(withIdentifier: "ViewController")
        
        pageViewControllers = [vc1, vc2]
    }
    
    private func setupPageViewController() {
        dataSource = self
        delegate = self
        
        setViewControllers([pageViewControllers[0]],
                           direction: .forward,
                           animated: false,
                           completion: { [weak self] (completed: Bool) in
                            //初期ページ設定が完了したらHeader領域分insetを設定
                            self?.setHeaderContentInset()
        })
    }
    
    //ヘッダーを設定
    private func setHeaderView() {
        contentsView = ContentsView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: headerAreaHeight))
        
        //タブボタンをタップした際のページ切り替え
        contentsView.tabButtonPressedBlock = { [weak self] (buttonTabIndex: Int) in
            guard let `self` = self else { return }
            
            self.shouldUpdateLayout = true
            self.updateIndex = buttonTabIndex
            let direction: UIPageViewController.NavigationDirection = (self.currentIndex! < buttonTabIndex) ? .forward : .reverse
            
            self.setViewControllers([self.pageViewControllers[buttonTabIndex]],
                                    direction: direction,
                                    animated: true,
                                    completion: { [weak self] (completed: Bool) in
                                        guard let `self` = self else { return }
                                        
                                        if self.shouldUpdateLayout {
                                            self.setHeaderViewOffsetY(index: buttonTabIndex, scroll: -self.scrollContentOffsetY)
                                            self.shouldUpdateLayout = false
                                        }
            })
        }
        
        contentsView.scrollDidChangedBlock = { [weak self] (scroll: CGFloat, shouldScrollFrame: Bool) in
            self?.shouldScrollFrame = shouldScrollFrame
            self?.updateContentOffsetY(scroll: scroll)
        }
        
    }
}


// MARK: - updateScroll

extension ScrollPagingViewController {
    
    private func setHeaderContentInset() {
        guard let currentIndex = currentIndex, let vc = pageViewControllers[currentIndex] as? ScrollTabPageViewControllerProtocol else {
            return
        }
        
        let inset = UIEdgeInsets(top: headerAreaHeight, left: 0, bottom: 0, right: 0)
        vc.scrollView.contentInset = inset
        vc.scrollView.scrollIndicatorInsets = inset
    }
    
    //切り替えたVCのヘッダーのOffsetYを反映する
    private func setHeaderViewOffsetY(index: Int, scroll: CGFloat) {
        guard let  vc = pageViewControllers[index] as? ScrollTabPageViewControllerProtocol else {
            return
        }
        
        if scroll == 0.0 {
            vc.scrollView.contentOffset.y = -headerAreaHeight
        }
        else if (scroll < headerAreaHeight - tabViewHeight) || (vc.scrollView.contentOffset.y <= -tabViewHeight) {
            vc.scrollView.contentOffset.y = scroll - headerAreaHeight
        }
    }
    
    private func updateContentView(scroll: CGFloat) {
        if shouldScrollFrame {
            contentsView.frame.origin.y = scroll
            scrollContentOffsetY = scroll
        }
        shouldScrollFrame = true
    }
    
    private func updateContentOffsetY(scroll: CGFloat) {
        if let currentIndex = currentIndex, let vc = pageViewControllers[currentIndex] as? ScrollTabPageViewControllerProtocol {
            vc.scrollView.contentOffset.y += scroll
        }
    }
    
    //各ViewControllerのScrollDidScrolledから呼び出される
    //ヘッダーを動かす
    func updateContentViewFrame() {
        guard let currentIndex = currentIndex, let vc = pageViewControllers[currentIndex] as? ScrollTabPageViewControllerProtocol else {
            return
        }
        var scrollOffsetY: CGFloat = 0
        if vc.scrollView.contentOffset.y >= -tabViewHeight {
            scrollOffsetY = headerAreaHeight - tabViewHeight
            vc.scrollView.scrollIndicatorInsets.top = tabViewHeight
        } else {
            scrollOffsetY = headerAreaHeight + vc.scrollView.contentOffset.y
            vc.scrollView.scrollIndicatorInsets.top = -vc.scrollView.contentOffset.y
        }
        updateContentView(scroll: -scrollOffsetY)
    }
    
    func updateLayoutIfNeeded() {
        if shouldUpdateLayout {
            let vc = pageViewControllers[updateIndex] as? ScrollTabPageViewControllerProtocol
            let shouldSetupContentOffsetY = vc?.scrollView.contentInset.top != headerAreaHeight
            
            let scroll = scrollContentOffsetY
            setHeaderContentInset()
            setHeaderViewOffsetY(index: updateIndex, scroll: -scroll)
            shouldUpdateLayout = shouldSetupContentOffsetY
        }
    }
}


// MARK: - UIPageViewControllerDateSource

extension ScrollPagingViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard var index = pageViewControllers.index(of: viewController) else {
            return nil
        }
        
        index = index + 1
        
        if index >= 0 && index < pageViewControllers.count {
            return pageViewControllers[index]
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard var index = pageViewControllers.index(of: viewController) else {
            return nil
        }
        
        index = index - 1
        
        if index >= 0 && index < pageViewControllers.count {
            return pageViewControllers[index]
        }
        return nil
    }
}


// MARK: - UIPageViewControllerDelegate

extension ScrollPagingViewController: UIPageViewControllerDelegate {
    
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        if let vc = pendingViewControllers.first, let index = pageViewControllers.index(of: vc) {
            shouldUpdateLayout = true
            updateIndex = index
        }
    }
    
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let _ = previousViewControllers.first, let currentIndex = currentIndex else {
            return
        }
        
        if shouldUpdateLayout {
            setHeaderContentInset()
            setHeaderViewOffsetY(index: currentIndex, scroll: -scrollContentOffsetY)
        }
        
        // ボタンのカレントを設定する
        if currentIndex >= 0 && currentIndex < contentsView.tabButtons.count {
            contentsView.updateCurrentIndex(index: currentIndex, animated: false)
        }
    }
}
