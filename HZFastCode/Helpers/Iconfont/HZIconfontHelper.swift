//
//  HZIconfontHelper.swift
//  FastCode
//
//  Created by Wang, Haizhou on 2019/8/9.
//  Copyright © 2019 HertzWang. All rights reserved.
//

import Cocoa

let HZIconFontStringEmpty : String = "\u{e629}"
let HZIconFontStringHelp : String = "\u{e64a}"
let HZIconFontStringAddConfig : String = "\u{e657}"
let HZIconFontStringImportConfig : String = "\u{e621}"
let HZIconFontStringExportConfig : String = "\u{e61e}"

//let instance = HZIconfontHelper()
//let HZIconFont = NSFont.init(name: "iconfont", size: 40)

class HZIconfontHelper: NSObject {
    
//    class var shared: HZIconfontHelper {
//        return instance;
//    }
    
    lazy var font: NSFont = {
        let iconfont = NSFont.init(name: "iconfont", size: 30)
        return iconfont ?? NSFont.systemFont(ofSize: 13)
    }()
}
