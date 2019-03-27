//
//  HZUserConfig.swift
//  HZFastCode
//
//  Created by HertzWang on 2019/3/25.
//  Copyright © 2018年 HertzWang. All rights reserved.
//

import Cocoa

let HZShowHelpWindowNotification = "com.hertzwang.show.help"

let HZUserConfigSuiteName = "group.com.hertzwang.fast-code"
let MappingKey = "HZMappingKey"

class HZUserConfig: NSObject {
    static let shared = HZUserConfig.init()
    var sharedUserDefaults: UserDefaults!
    
    fileprivate var _mapping: [String: String] = [:]
    var mapping: [String: String] {
        if let map = UserDefaults(suiteName: HZUserConfigSuiteName)?.value(forKey: MappingKey) as? [String: String]{
            return map
        }
        return [:]
    }
    
    private override init(){
        sharedUserDefaults = UserDefaults(suiteName: HZUserConfigSuiteName)
        if let map = sharedUserDefaults.value(forKey: MappingKey) as? [String: String]{
            _mapping = map
        }
    }
    
    func saveMapping(_ dic: [String : String]) {
        self.sharedUserDefaults.set(dic, forKey: MappingKey)
        self.sharedUserDefaults.synchronize()
        _mapping = dic
    }
    
    /// 合并配置信息
    ///
    /// - Parameter importMap: 导入的配置信息
    func mergeAndSave(_ importMap: [String : String]) -> [String : String] {
        var map = importMap
        map.merge(HZUserConfig.shared.mapping) { (current, old) in old } // 保留之前的
        // TODO: map 排序
        
        HZUserConfig.shared.saveMapping(map)
        
        return map
    }
}
