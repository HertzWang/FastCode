//
//  HZConfigModel.swift
//  FastCode
//
//  Created by HertzWang on 2019/3/27.
//  Copyright © 2019 HertzWang. All rights reserved.
//

import Cocoa
import CommonCrypto

/*
 
一共有六项不同，分别是：前缀、作用域、内容、标识符、概要、标题
 第一版：可输入前缀和内容，标题、概要同前缀，使用域为All，标识符根据规则自动生成
 第二版：可修改标题、概要、使用域
 第三版：可修改言语和平台
 
*/

let HZCodeSnippetIdentifierPrefix = "com.hertzwang.fast-code.identifier.prefix"

class HZConfigModel: NSObject {
    var prefix: String = "" /// 代码块前缀
    var contents: String = "" /// 代码块内容
    var title: String = "" /// 代码块标题
    var summary: String = "" /// 代码块概要
    var scopes: String = "" /// 代码块作用域
    var identifier: String = "" /// 代码块唯一标识符 MD5如：FF167DB4-0C2D-4F6D-9A2B-0C0785239FFB
    
    class func model(_ prefix: String, _ contents: String) -> HZConfigModel {
        let model = HZConfigModel();
        model.prefix = prefix
        model.contents = contents
        
        return model
    }
    
    class func model(_ json: String) -> HZConfigModel {
        let model = HZConfigModel();
        guard let data = json.data(using: .utf8) else { return model }
        if let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: String] {
            model.prefix = dict["prefix"] ?? ""
            model.contents = dict["contents"] ?? ""
            model.title = dict["title"] ?? ""
            model.summary = dict["summary"] ?? ""
            model.scopes = dict["scopes"] ?? ""
            model.identifier = dict["identifier"] ?? ""
        }
        
        return model
    }
    
    func isEmpty() -> Bool {
        return self.prefix.isEmpty
    }
    
    func jsonValue() -> String {
        var result = ""
        if let data = try? JSONSerialization.data(withJSONObject: dictValue(), options: JSONSerialization.WritingOptions.fragmentsAllowed) {
            result = String.init(data: data, encoding: .utf8) ?? ""
        }
        return result
    }
    
    fileprivate func dictValue() -> [String: String] {
        return [
            "prefix" : self.prefix,
            "contents" : self.contents,
            "title" : self.prefix,
            "summary" : self.prefix,
            "scopes" : "All",
            "identifier" : HZCodeSnippetIdentifierPrefix.appending(self.prefix).hz_md5()
        ]
    }
}

extension String {
    func hz_md5() -> String {
        let str = self.cString(using: .utf8)
        let strLen = CUnsignedInt(self.lengthOfBytes(using: .utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let md = UnsafeMutablePointer<UInt8>.allocate(capacity: digestLen)
        CC_MD5(str, strLen, md)
        let arr = [3, 5, 7, 9]
        let hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", md[i])
            if arr.contains(i) {
                hash.append("-")
            }
        }
        free(md)
        return String(format: hash.uppercased as String)
    }
}

/*
 
 1.  代码块前缀 IDECodeSnippetCompletionPrefix 对应的 string
 2.  代码块作用域 IDECodeSnippetCompletionScopes 对应的 array<string>，目前已知有 All、CodeBlock
 3.  代码块内容 IDECodeSnippetContents 对应的 string，其中填充部份以 &lt;#  开头并以 #&gt; 结尾，Xcode中是填充部分
 4.  代码块唯一标识符 IDECodeSnippetIdentifier 对应的 string，格式为 8位-4位-4位-4位-12位 的16进制，如：FF167DB4-0C2D-4F6D-9A2B-0C0785239FFB
 5.  代码块概要 IDECodeSnippetSummary 对应的string，无内容可为空字符串
 6.  代码块标题 IDECodeSnippetTitle 对应的 string
 
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>IDECodeSnippetCompletionPrefix</key>
    <string>代码块前缀</string>
    <key>IDECodeSnippetCompletionScopes</key>
    <array>
        <string>代码块作用域</string>
    </array>
    <key>IDECodeSnippetContents</key>
    <string>代码块内容</string>
    <key>IDECodeSnippetIdentifier</key>
    <string>代码块唯一标识符</string>
    <key>IDECodeSnippetLanguage</key>
    <string>Xcode.SourceCodeLanguage.Objective-C</string>
    <key>IDECodeSnippetSummary</key>
    <string>代码块概要</string>
    <key>IDECodeSnippetTitle</key>
    <string>代码块标题</string>
    <key>IDECodeSnippetUserSnippet</key>
    <true/>
    <key>IDECodeSnippetVersion</key>
    <integer>2</integer>
</dict>
</plist>

*/
