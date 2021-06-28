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
    @IBOutlet fileprivate weak var codeWebView: WebView!
    @IBOutlet fileprivate weak var sortArrowButon: NSButton!
    fileprivate weak var searchField: NSSearchField?
    fileprivate weak var publishButton: NSButton?
    
    fileprivate var dataModels: [HZConfigModel] = []
    fileprivate var dataArray: [HZConfigModel] = []
    fileprivate var helpRequest: URLRequest? {
        if let filePath = Bundle.main.path(forResource: "help_html/help", ofType: "html") {
            let url = URL.init(fileURLWithPath: filePath)
            let request = URLRequest.init(url: url)
            return request
        }
        return nil
    }
    fileprivate var showCodeFilePath: String? = Bundle.main.path(forResource: "code_html/code", ofType: "html")
    fileprivate var showCodeRequest: URLRequest? {
        if let filePath = self.showCodeFilePath {
            let url = URL.init(fileURLWithPath: filePath)
            let request = URLRequest.init(url: url)
            return request
        }
        return nil
    }
    fileprivate var htmlCode : String? {
        if let filePath = self.showCodeFilePath {
            return try? String.init(contentsOfFile: filePath)
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
                                               name: NSNotification.Name.init(kFCEnumNotification),
                                               object: nil)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        initSearchField()
        initCodeWebView()
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // MARK: - Private
    
    /// 初始化数据
    private func initData(map: [String : HZConfigModel]? = nil) {
        let mapping = map ?? HZUserConfig.shared.mapping
        var arr: [HZConfigModel] = []
        for (key, value) in mapping {
            let model = HZConfigModel.model(key, value.contents)
            arr.append(model)
        }
        
        self.dataModels = arr
        self.dataArray = self.dataModels
        HZUserConfig.shared.cleanOldData()
    }
    
    /// 初始化界面
    private func initView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.doubleAction = NSSelectorFromString("editConfigAction:")
    }
    
    /// 初始化搜索
    private func initSearchField() {
        guard self.searchField == nil else {
            return;
        }
        if let items = NSApp.windows.first?.toolbar?.items {
            for item in items {
                if item.itemIdentifier.rawValue.elementsEqual("HZToolbarItemSearch"),
                    let searchField = item.view as? NSSearchField {
                    // 搜索
                    self.searchField = searchField
                    self.searchField?.delegate = self
                } else if item.itemIdentifier.rawValue.elementsEqual("HZToolbarItemPublish"),
                    let publishButton = item.view as? NSButton {
                    // 发布
                    self.publishButton = publishButton
                    self.publishButton?.target = self
                    self.publishButton?.action = #selector(publishAction)
                }
            }
        }
    }
    
    /// 初始化预览Web
    private func initCodeWebView() {
        guard self.codeWebView?.mainFrameURL == nil else {
            return
        }
        if let request = self.helpRequest {
            self.codeWebView?.mainFrame.load(request)
        }
    }
    
    /// 保存数据
    private func saveConfig() {
        var dic = [String : HZConfigModel]()
        for model in self.dataModels {
            if !model.prefix.isEmpty,  !model.contents.isEmpty {
                dic[model.prefix] = model
            }
        }
        HZUserConfig.shared.saveMapping(dic)
    }
    
    /// 刷新列表
    fileprivate func reloadData() {
        self.tableView.reloadData()
        self.codeWebView.mainFrame.load(self.helpRequest!)
    }
    
    // MARK: -  Action
    
    /// 添加配置信息
    ///
    /// - Parameter sender: 添加按钮
    @IBAction fileprivate func addConfigAction(_ sender: NSButton) {
        self.configViewController.model(nil)
        self.presentAsSheet(self.configViewController)
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
                let selectedRow = self.tableView.selectedRow
                let removeKey = self.dataArray[selectedRow].prefix
                self.dataModels.removeAll(where: { (configModel) -> Bool in
                    return (configModel.prefix.elementsEqual(removeKey))
                })
                self.saveConfig()
                self.dataArray.remove(at: selectedRow)
                self.reloadData()
            }
        }
    }
    
    /// 编辑配置信息
    ///
    /// - Parameter sender: 编辑按钮/双击的TableView
    @IBAction func editConfigAction(_ sender: Any) {
        guard self.tableView.selectedRow >= 0 else {
            return
        }
        
        let item = self.dataArray[self.tableView.selectedRow]
        self.configViewController.model(item)
        self.presentAsSheet(self.configViewController)
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
                    initData(map: map)
                    self.reloadData()
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
                    
                    let mapping = HZUserConfig.shared.stringMapping(nil)
                    do {
                        let data = try JSONSerialization.data(withJSONObject: mapping, options: .prettyPrinted)
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
                self.reloadData()
            }
        }
    }
    
    /// 显示帮助
    ///
    /// - Parameter sender: 按钮
    @IBAction fileprivate func helpAction(_ sender: Any) {
        self.helpWindow.show(self)
    }
    
    /// 发布
    @objc fileprivate func publishAction() {
        let alert = NSAlert()
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消") // 默认为取消操作
        alert.messageText = "提示"
        alert.informativeText = "应用所有配置？"
        alert.alertStyle = .critical
        alert.beginSheetModal(for: self.view.window!) { (returnCode) in
            if returnCode.rawValue == NSApplication.ModalResponse.alertFirstButtonReturn.rawValue {
                HZUserConfig.shared.outputXMLFile()
            }
        }
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
        return self.dataArray.count
    }
}

// MARK: - NSTableViewDelegate

extension ViewController: NSTableViewDelegate {
    
    // 显示详情
    func tableViewSelectionDidChange(_ notification: Notification) {
        let tableView = notification.object as! NSTableView
        if (tableView.selectedRow < 0) {
            self.codeWebView.mainFrame.load(self.helpRequest!)
            return
        }
        let item = self.dataArray[self.tableView.selectedRow]
        if let html = self.htmlCode?.replacingOccurrences(of: kFCShowPlaceholderText, with: item.contents) {
            self.codeWebView.mainFrame.loadHTMLString(html, baseURL: URL.init(fileURLWithPath: self.showCodeFilePath!))
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 20
    }
    
    // 排序
    func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
        let mapping: [String : HZConfigModel] = HZUserConfig.shared.mapping
        var keys: [String] = []
        if self.sortArrowButon.state == .off {
            self.sortArrowButon.state = .on
            keys = mapping.keys.sorted(by: >)
        } else {
            self.sortArrowButon.state = .off
            keys = mapping.keys.sorted(by: <)
        }
        self.dataModels.removeAll()
        for key in keys {
            let model = mapping[key] ?? HZConfigModel()
            self.dataModels.append(model)
        }
        self.dataArray = self.dataModels
        self.reloadData()
    }
    
    // Cell
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellIdentifier = "Key"
        let text = self.dataArray[row].prefix
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier.init(cellIdentifier), owner: self) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
}

// MARK: - NSSearchFieldDelegate

extension ViewController: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        if let searchField = obj.object as? NSSearchField {
            let keyword = searchField.stringValue
            if (keyword.count == 0) {
                initData(map: nil)
                self.reloadData()
                return
            }
            
            self.dataArray.removeAll()
            for model in self.dataModels {
                if (model.prefix.contains(keyword)) {
                    self.dataArray.append(model)
                }
            }
            self.reloadData()
        }
    }
}

// MARK: - WebUIDelegate

extension ViewController: WebUIDelegate {
    // 禁用右键
    func webView(_ sender: WebView!, contextMenuItemsForElement element: [AnyHashable : Any]!, defaultMenuItems: [Any]!) -> [Any]! {
        return []
    }
}

// MARK: - HZConfigurationViewControllerProtocol

extension ViewController: HZConfigurationViewControllerProtocol {
    func modifyModel(model: HZConfigModel, isEdit: Bool) {
        self.configViewController.dismiss(nil)
        if isEdit {
            self.dataArray[tableView.selectedRow] = model
            self.dataModels.removeAll { (configModel) -> Bool in
                return (configModel.prefix.elementsEqual(model.prefix))
            }
        } else {
            if self.searchField!.stringValue.isEmpty {
                self.dataArray.append(model)
            } else if model.prefix.contains(self.searchField!.stringValue) {
                self.dataArray.append(model)
            }
        }
        self.dataModels.append(model)
        
        self.reloadData()
        saveConfig()
    }
}
