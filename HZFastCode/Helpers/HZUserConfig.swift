//
//  HZUserConfig.swift
//  HZFastCode
//
//  Created by HertzWang on 2019/3/25.
//  Copyright © 2018年 HertzWang. All rights reserved.
//

import Cocoa

let HZEnumNotification = "com.hertzwang.fastcode.enum"

let HZUserConfigSuiteName = "group.com.hertzwang.fast-code"
let MappingOldKey = "HZMappingKey"
let MappingKey = "HZModelMappingKey"

class HZUserConfig: NSObject {
    static let shared = HZUserConfig.init()
    var sharedUserDefaults: UserDefaults!
    
    var mapping = [String: HZConfigModel]()
    
    private override init() {
        sharedUserDefaults = UserDefaults(suiteName: HZUserConfigSuiteName)
        if let map = sharedUserDefaults.value(forKey: MappingOldKey) as? [String: String] {
            for (key, value) in map {
                mapping[key] = HZConfigModel.model(key, value)
            }
        }
        if let map = sharedUserDefaults.value(forKey: MappingKey) as? [String: String] {
            for (key, json) in map {
                mapping[key] = HZConfigModel.model(json)
            }
        }
    }
    
    /// 保存数据
    func saveMapping(_ map: [String : HZConfigModel]) {
        self.sharedUserDefaults.set(stringMapping(map), forKey: MappingKey)
        self.sharedUserDefaults.synchronize()
        mapping = map
    }
    
    /// 合并配置信息
    ///
    /// - Parameter importMap: 导入的配置信息
    func mergeAndSave(_ importMap: [String : String]) -> [String : HZConfigModel] {
        var map = importMap
        map.merge(HZUserConfig.shared.stringMapping(nil)) { (current, old) in old } // 保留之前的
        
        var result = [String: HZConfigModel]()
        for (key, json) in map {
            result[key] = HZConfigModel.model(json)
        }
        
        HZUserConfig.shared.saveMapping(result)
        
        // TODO: 合并时冲突提示：“忽略”、“替换”、“取消”
        
        return result
    }
    
    /// 清空旧数据
    func cleanOldData() {
        if let map = sharedUserDefaults.value(forKey: MappingOldKey) as? [String: String] {
            if map.count > 0 {
                self.sharedUserDefaults.removeObject(forKey: MappingOldKey)
                saveMapping(mapping)
            }
        }
    }
    
    /// mapping的string格式
    /// - Returns: dict
    func stringMapping(_ map: [String : HZConfigModel]?) -> [String: String] {
        var result = [String: String]()
        for (key, model) in (map ?? self.mapping) {
            result[key] = model.jsonValue()
        }
        return result
    }
}
