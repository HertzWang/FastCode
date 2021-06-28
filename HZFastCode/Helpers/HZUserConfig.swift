//
//  HZUserConfig.swift
//  HZFastCode
//
//  Created by HertzWang on 2019/3/25.
//  Copyright © 2018年 HertzWang. All rights reserved.
//

import Cocoa

class HZUserConfig: NSObject {
    static let shared = HZUserConfig.init()
    var sharedUserDefaults: UserDefaults!
    
    var mapping = [String: HZConfigModel]()
    
    private override init() {
        sharedUserDefaults = UserDefaults(suiteName: kFCUserConfigSuiteName)
        if let map = sharedUserDefaults.value(forKey: kFCMappingOldKey) as? [String: String] {
            for (key, value) in map {
                mapping[key] = HZConfigModel.model(key, value)
            }
        }
        if let map = sharedUserDefaults.value(forKey: kFCMappingKey) as? [String: String] {
            for (key, json) in map {
                mapping[key] = HZConfigModel.model(json)
            }
        }
    }
    
    /// 保存数据
    func saveMapping(_ map: [String : HZConfigModel]) {
        self.sharedUserDefaults.set(stringMapping(map), forKey: kFCMappingKey)
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
        if let map = sharedUserDefaults.value(forKey: kFCMappingOldKey) as? [String: String] {
            if map.count > 0 {
                self.sharedUserDefaults.removeObject(forKey: kFCMappingOldKey)
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
    
    func outputXMLFile() {
        let fm = FileManager.default
        if let documentDirectory = fm.urls(for: .documentDirectory, in: .userDomainMask).first?.absoluteString as NSString? {
            do {
                let cachedPath = documentDirectory.appending(kFCFolderName)
                if let folderPath = URL.init(string: cachedPath) {
                    try fm.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
                }
                let loc = documentDirectory.range(of: kFCPathKeyword).location
                let xcodeSnippetsPath = "\(documentDirectory.substring(to: loc))Library/Developer/Xcode/UserData/CodeSnippets"
                var files = [String]()
                let mapping = HZUserConfig.shared.mapping
                for (key, model) in mapping {
                    let fileName =  "fast_code_custom_\(key).codesnippet"
                    let filePath = "\(cachedPath)/" + fileName
                    if let fileURL = URL.init(string: filePath) {
                        try? fm.removeItem(at: fileURL)
                        try model.data()?.write(to: fileURL)
                        files.append(fileName)
                    }
                }
                // 提权移动至Xcode相应目录
                moveFiles(cachedPath, xcodeSnippetsPath, files)
            } catch {
                // TODO: 异常处理
                print(error)
            }
        }
    }
    
    fileprivate func moveFiles(_ fromPath: String, _ toPath: String, _ files: [String]) {
        var listOfFiles = ""
        for fileName in files {
            if listOfFiles.count > 0 {
                listOfFiles += ", \"\(fileName)\""
            } else {
                listOfFiles += "\"\(fileName)\""
            }
        }
        let sourceFolder = kFCHardDiskName + fromPath.replacingOccurrences(of: kFCFilePathPrefix, with: "").replacingOccurrences(of: "/", with: ":")
        let goFolder = kFCHardDiskName + toPath.replacingOccurrences(of: kFCFilePathPrefix, with: "").replacingOccurrences(of: "/", with: ":")
        
        var scpt = """
            set listOfFiles to {FCScptFilesName}
            tell application "Finder"
                open folder "FCScptGoFolder"
                set sourceFolder to folder "FCScptSourceFolder"
                set goFolder to folder "FCScptGoFolder"
                set goFiles to every file of sourceFolder whose name is in listOfFiles
                move goFiles to goFolder
            
            end tell
            """
        scpt = scpt.replacingOccurrences(of: kFCScptFilesName, with: listOfFiles).replacingOccurrences(of: kFCScptSourceFolder, with: sourceFolder).replacingOccurrences(of: kFCScptGoFolder, with: goFolder)

        let scptPath = fromPath.replacingOccurrences(of: kFCFolderName, with: "").appending("moveFile.scpt")
        if let scptURL = URL.init(string: scptPath) {
            try? FileManager.default.removeItem(at: scptURL)
            try? scpt.data(using: .utf8)?.write(to: scptURL)
            NSWorkspace.shared.openFile(scptPath)
        }
    }
}
