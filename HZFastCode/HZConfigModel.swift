//
//  HZConfigModel.swift
//  FastCode
//
//  Created by HertzWang on 2019/3/27.
//  Copyright © 2019 zhengjiacheng. All rights reserved.
//

import Cocoa

class HZConfigModel {
    var key: String = ""
    var value: String = ""
    
    func isEmpty() -> Bool {
        return self.key.isEmpty
    }
}
