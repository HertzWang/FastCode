//
//  ViewController.swift
//  HZFastCode
//
//  Created by HertzWang on 2019/3/25.
//  Copyright © 2018年 HertzWang. All rights reserved.
//

import Cocoa
import WebKit

class ViewController: NSViewController {
    
    // MARK: - Property
    
    @IBOutlet private weak var tableView: NSTableView!
    @IBOutlet fileprivate var contentTextView: NSTextView!
    @IBOutlet weak var codeWebView: WebView!
    
    fileprivate var keywordDesc: Bool = false
    fileprivate var dataModels: [HZConfigModel] = []
    fileprivate var helpRequest: URLRequest? {
        if let filePath = Bundle.main.path(forResource: "help_html/help", ofType: "html") {
            let url = URL.init(fileURLWithPath: filePath)
            let request = URLRequest.init(url: url)
            return request
        }
        return nil
    }
    fileprivate var showCodeRequest: URLRequest? {
        if let filePath = Bundle.main.path(forResource: "code_html/code", ofType: "html") {
            let url = URL.init(fileURLWithPath: filePath)
            let request = URLRequest.init(url: url)
            return request
        }
        return nil
    }
    
    lazy fileprivate var configViewController: HZConfigurationViewController = {
        let configViewController = HZConfigurationViewController.init(nibName: NSNib.Name.init("HZConfigurationViewController"), bundle: Bundle.main)
        configViewController.delegate = self
        return configViewController
    }()
    
    lazy fileprivate var helpWindow: HZHelpWindowController = {
        let helpWindow = HZHelpWindowController(windowNibName: NSNib.Name.init("HZHelpWindowController"))
        
        return helpWindow
    }()
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initData()
        initView()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(enumNotification),
                                               name: NSNotification.Name.init(HZEnumNotification),
                                               object: nil)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    
        guard self.codeWebView.mainFrameURL == nil else {
            return
        }
        
        if let request = self.helpRequest {
            self.codeWebView.mainFrame.load(request)
        }
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // MARK: - Private
    
    /// 初始化数据
    private func initData(map: [String : String]? = nil) {
        let mapping = map ?? HZUserConfig.shared.mapping
        var arr: [HZConfigModel] = []
        for (key, value) in mapping {
            let model = HZConfigModel.model(key, value)
            arr.append(model)
        }
        
        self.dataModels = arr
    }
    
    /// 初始化界面
    private func initView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
    }
    
    /// 保存数据
    private func saveConfig() {
        var dic: [String : String] = [:]
        for model in self.dataModels {
            if !model.key.isEmpty,  !model.value.isEmpty {
                dic[model.key] = model.value
            }
        }
        
        HZUserConfig.shared.saveMapping(dic)
    }
    
    /// 刷新列表
    ///
    /// - Parameter map: 数据源
    fileprivate func refreshTable(_ map: [String : String]) {
        initData(map: map)
        self.tableView.reloadData()
    }
    
    // MARK: -  Action
    
    /// 添加配置信息
    ///
    /// - Parameter sender: 添加按钮
    @IBAction fileprivate func addConfigAction(_ sender: NSButton) {
        self.configViewController.model(HZConfigModel())
        self.presentViewControllerAsSheet(self.configViewController)
    }
    
    /// 删除配置信息
    ///
    /// - Parameter sender: 删除按钮
    @IBAction fileprivate func removeConfigAction(_ sender: NSButton) {
        guard self.tableView.selectedRow >= 0 else {
            return
        }
        
        let alert = NSAlert()
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消") // 默认为取消操作
        alert.messageText = "提示"
        alert.informativeText = "删除选中配置？"
        alert.alertStyle = .warning
        alert.beginSheetModal(for: self.view.window!) { (returnCode) in
            if returnCode.rawValue == NSApplication.ModalResponse.alertFirstButtonReturn.rawValue {
                self.dataModels.remove(at: self.tableView.selectedRow)
                self.tableView.reloadData()
                self.saveConfig()
            }
        }
    }
    
    /// 编辑配置信息
    ///
    /// - Parameter sender: 编辑按钮
    @IBAction func editConfigAction(_ sender: NSButton) {
        guard self.tableView.selectedRow >= 0 else {
            return
        }
        
        let item = dataModels[tableView.selectedRow]
        self.configViewController.model(item)
        self.presentViewControllerAsSheet(self.configViewController)
    }
    
    /// 导入配置
    ///
    /// - Parameter sender: 按钮
    fileprivate func importConfigListAction() {
        
        let panel = NSOpenPanel()
        panel.resolvesAliases = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["json"]
        let result = panel.runModal()
        if result.rawValue == NSFileHandlingPanelOKButton {
            debugPrint("url \(panel.urls)")
            guard panel.urls.count > 0 else {
                return;
            }
            
            do {
                let string = try? String.init(contentsOf: panel.urls.first!, encoding: .utf8)
                let data = string?.data(using: .utf8)
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                
                if let inputMap = json as? [String: String] {
                    let map = HZUserConfig.shared.mergeAndSave(inputMap)
                    refreshTable(map)
                }
            } catch {
                // TODO: 异常处理
            }
        }
    }
    
    /// 导出配置
    ///
    /// - Parameter sender: 按钮
    fileprivate func exportConfigListAction() {

        let savePanel = NSSavePanel()
        savePanel.nameFieldLabel = "文件名"
        savePanel.nameFieldStringValue = "FastCode配置文件" + "\(Int(NSDate().timeIntervalSince1970))"
        savePanel.message = "导出配置信息"
        savePanel.allowsOtherFileTypes = false
        savePanel.allowedFileTypes = ["json"]
        savePanel.isExtensionHidden = true
        savePanel.canCreateDirectories = true
        savePanel.beginSheetModal(for: self.view.window!) { (result) in
            if result.rawValue == NSFileHandlingPanelOKButton {
                if let path = savePanel.url {
                    
                    let objc = HZUserConfig.shared.mapping
                    do {
                        let data = try JSONSerialization.data(withJSONObject: objc, options: .prettyPrinted)
                        let string = String.init(data: data, encoding: .utf8)
                        try? string?.write(to: path, atomically: true, encoding: .utf8)
                    } catch {
                        // TODO: 异常处理
                    }
                }
            }
        }
        
    }
    
    /// 清空配置
    ///
    /// - Parameter sender: 按钮
    fileprivate func emptyConfigAction() {
        let alert = NSAlert()
        alert.addButton(withTitle: "清空")
        alert.addButton(withTitle: "取消") // 默认为取消操作
        alert.messageText = "提示"
        alert.informativeText = "清空所有配置？"
        alert.alertStyle = .critical
        alert.beginSheetModal(for: self.view.window!) { (returnCode) in
            if returnCode.rawValue == NSApplication.ModalResponse.alertFirstButtonReturn.rawValue {
                // 清空
                HZUserConfig.shared.saveMapping([:])
                self.initData()
                self.tableView.reloadData()
            }
        }
    }
    
    /// 显示帮助
    ///
    /// - Parameter sender: 按钮
    @IBAction fileprivate func helpAction(_ sender: Any) {
        self.helpWindow.show(self)
    }
    
    // MARK: - Notification
    
    /// 菜单操作通知
    @objc private func enumNotification(_ notification: NSNotification) {
        if let notificationModel = notification.object as? HZEnumNotificationModel {
            switch notificationModel.type {
            case .import?: 
                importConfigListAction()
                break
                
            case .export?:
                exportConfigListAction()
                break
                
            case .empty?:
                emptyConfigAction()
                break
                
            case .help?:
                self.helpWindow.show(self)
                break
                
            default: break
            }
        }
    }
    
}

// MARK: - NSTableViewDataSource

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return dataModels.count
    }
}

// MARK: - NSTableViewDelegate

extension ViewController: NSTableViewDelegate {
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let tableView = notification.object as! NSTableView
        if (tableView.selectedRow < 0) {
            self.contentTextView.string = ""
            self.codeWebView.isHidden = false
            return
        }
        
        let item = dataModels[tableView.selectedRow]
        self.contentTextView.string = item.value
        self.codeWebView.isHidden = true
        
//        if let request = self.showCodeRequest {
//            if self.codeWebView.mainFrameURL != request.url?.absoluteString {
//                self.codeWebView.mainFrame.load(request)
//            }
//        }
//
//        let js = "showCode(\'\(item.value)\')"
//        self.codeWebView?.stringByEvaluatingJavaScript(from: js)
    }
    
    func tableView(_ tableView: NSTableView, typeSelectStringFor tableColumn: NSTableColumn?, row: Int) -> String? {
        debugPrint("typeSelectStringFor")
        
        return nil
    }
    
    func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
        let mapping: [String : String] = HZUserConfig.shared.mapping
        var keys: [String] = []
        if keywordDesc {
            keys = mapping.keys.sorted(by: >)
        } else {
            keys = mapping.keys.sorted(by: <)
        }
        
        keywordDesc = !keywordDesc
        
        dataModels.removeAll()
        for key in keys {
            let model = HZConfigModel.model(key, mapping[key] ?? "")
            dataModels.append(model)
        }
        
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellIdentifier = "Key"
        let text = dataModels[row].key
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier.init(cellIdentifier), owner: self) as? NSTableCellView{
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
}

// MARK: - HZConfigurationViewControllerProtocol

extension ViewController: HZConfigurationViewControllerProtocol {
    func modifyModel(model: HZConfigModel, isEdit: Bool) {
        if isEdit {
            if tableView.selectedRow >= 0 {
                if model.isEmpty() {
                    dataModels.remove(at: tableView.selectedRow)
                } else {
                    dataModels[tableView.selectedRow] = model
                }
            }
        } else {
            dataModels.append(model)
        }
        
        self.tableView.reloadData()
        saveConfig()
        self.configViewController.dismiss(nil)
    }
}
