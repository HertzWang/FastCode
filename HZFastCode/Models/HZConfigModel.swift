//
//  HZConfigModel.swift
//  FastCode
//
//  Created by HertzWang on 2019/3/27.
//  Copyright © 2019 HertzWang. All rights reserved.
//

import Cocoa

class HZConfigModel: NSObject {
    var key: String = ""
    var value: String = ""
    
    class func model(_ key: String, _ value: String) -> HZConfigModel {
        let model = HZConfigModel();
        model.key = key
        model.value = value
        
        return model
    }
    
    func isEmpty() -> Bool {
        return self.key.isEmpty
    }
}
