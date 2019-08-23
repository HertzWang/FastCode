//
//  HZEnumNotificationModel.swift
//  FastCode
//
//  Created by Hertz on 12/8/2019.
//  Copyright © 2019 zhengjiacheng. All rights reserved.
//

import Cocoa

enum HZEnumItemType: String {
    case `import` = "ConfigImport"
    case export = "ConfigExport"
    case empty = "ConfigEmpty"
    case help = "help"
}

class HZEnumNotificationModel: NSObject {
    var type: HZEnumItemType!
    
    class func `init`(_ type : HZEnumItemType) -> HZEnumNotificationModel  {
        let model = HZEnumNotificationModel()
        model.type = type
        
        return model
    }
    
    func dictionaryValue() -> Dictionary<String, Any> {
        let dict = [ "type" : self.type.rawValue ]
        
        return dict
    }
}
