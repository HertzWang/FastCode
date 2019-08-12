//
//  HZHelpWindowController.swift
//  FastCode
//
//  Created by HertzWang on 2019/3/27.
//  Copyright © 2019 HertzWang. All rights reserved.
//

import Cocoa

class HZHelpWindowController: NSWindowController {
    
    // MARK: - Property
    
    @IBOutlet weak var clipView: NSClipView!
    
    // MARK: - Override
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    override func awakeFromNib() {
        self.clipView.scroll(NSZeroPoint)
    }
    
    // MARK: - Public
    
    /// 显示帮助
    ///
    /// - Parameter viewController: 主视图
    func show(_ viewController: NSViewController) {
        self.clipView?.scroll(NSZeroPoint)
        self.window?.center()
        self.showWindow(viewController)
    }
    
}
