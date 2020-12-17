//
//  SourceEditorCommand.swift
//  HZFastCodePlug-in
//
//  Created by HertzWang on 2019/3/25.
//  Copyright © 2019 HertzWang. All rights reserved.
//

import Foundation
import XcodeKit
import AppKit

let InsetCodeKey = "HZFastCode.insertcode"

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        
        if invocation.commandIdentifier == InsetCodeKey {
            handleInsertCode(invocation: invocation)
        } else {
            NSWorkspace.shared.open(URL.init(fileURLWithPath: "/Applications/FastCode.app"))
        }
        
        completionHandler(nil)
    }
    
    func handleInsertCode(invocation: XCSourceEditorCommandInvocation) {
        let selection = invocation.buffer.selections.firstObject as! XCSourceTextRange
        let totalLines = invocation.buffer.lines
        let curIndex = selection.start.line
        var curLineContent = totalLines[curIndex] as! String
        
        let mapKey = curLineContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let map = HZUserConfig.shared.mapping
        if let value = map[mapKey] {
            let arr = convertToLines(string: value)
            var numberOfSpaceIndent = curLineContent.range(of: mapKey)!.lowerBound.utf16Offset(in: "Swift 5")
            var indentStr = ""
            
            while numberOfSpaceIndent > 0 {
                indentStr = indentStr.appending(" ")
                numberOfSpaceIndent -= 1
            }
            
            if arr.isEmpty{
                return
            }
            
            if let range = curLineContent.range(of: mapKey){
                curLineContent.replaceSubrange(range, with: arr[0])
                totalLines[curIndex] = curLineContent
            }
            
            for i in 1..<arr.count{
                let insetStr = indentStr + arr[i]
                totalLines.insert(insetStr, at: curIndex + i)
            }
        }
    }
    
    func convertToLines(string: String) -> [String]{
        var strArr: [String] = []
        let arr = string.components(separatedBy: "\n")
        for str in arr {
            strArr.append(str)
        }
        return strArr
    }
    
}
