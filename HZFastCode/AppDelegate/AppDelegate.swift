//
//  AppDelegate.swift
//  HZFastCode
//
//  Created by HertzWang on 2019/3/25.
//  Copyright © 2018年 HertzWang. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if flag {
            return false
        } else {
            sender.windows.first?.makeKeyAndOrderFront(self)
            return true
        }
    }
    
    // MARK: - Action
    
    /// 显示帮助
    ///
    /// - Parameter sender: 按钮
    @IBAction func showHelpWindow(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name.init(HZEnumNotification), object: HZEnumNotificationModel.`init`(.help))
    }
    
    /// 导入配置
    ///
    /// - Parameter sender: 导入按钮
    @IBAction func importConfigAction(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name.init(HZEnumNotification), object: HZEnumNotificationModel.`init`(.import))
    }
    
    /// 导出配置
    ///
    /// - Parameter sender: 导出按钮
    @IBAction func exportConfigAction(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name.init(HZEnumNotification), object: HZEnumNotificationModel.`init`(.export))
    }
    
    /// 清空配置
    ///
    /// - Parameter sender: 清空按钮
    @IBAction func emptyConfigAction(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name.init(HZEnumNotification), object: HZEnumNotificationModel.`init`(.empty))
    }
    
}

