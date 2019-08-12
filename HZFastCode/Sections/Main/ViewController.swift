//
//  ViewController.swift
//  HZFastCode
//
//  Created by HertzWang on 2019/3/25.
//  Copyright © 2018年 HertzWang. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    // MARK: - Property
    
    @IBOutlet weak var exportConfigButton: NSButton!
    @IBOutlet weak var emptyConfigButton: NSButton!
    @IBOutlet weak var importConfigButton: NSButton!
    @IBOutlet weak var addConfigButton: NSButton!
    @IBOutlet weak var helpButton: NSButton!
    @IBOutlet weak var tableView: NSTableView!
    
    var keywordDesc: Bool = false
    var dataModels: [HZConfigModel] = []
    
    lazy var configViewController: HZConfigurationViewController = {
        let configViewController = HZConfigurationViewController.init(nibName: NSNib.Name.init("HZConfigurationViewController"), bundle: Bundle.main)
        configViewController.delegate = self
        return configViewController
    }()
    
    lazy var helpWindow: HZHelpWindowController = {
        let helpWindow = HZHelpWindowController(windowNibName: NSNib.Name.init("HZHelpWindowController"))
        
        return helpWindow
    }()
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initData()
        initView()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(showHelpWindow),
                                               name: NSNotification.Name.init(HZShowHelpWindowNotification),
                                               object: nil)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    override func awakeFromNib() {
        // 更新按钮样式
        if let iconfont = NSFont.init(name: "iconfont", size: 30) {
            
            let buttons = [(HZIconFontStringExportConfig, self.exportConfigButton, "导出"),
                           (HZIconFontStringEmpty, self.emptyConfigButton, "清空"),
                           (HZIconFontStringImportConfig, self.importConfigButton, "导入")]
            for (iconfontString, button, titleString) in buttons {
                let attr = NSMutableAttributedString.init(string: "\(iconfontString)\n" + titleString)
                attr.addAttributes([NSAttributedStringKey.font : iconfont],
                                   range: NSMakeRange(0, iconfontString.count))
                attr.addAttributes([NSAttributedStringKey.font : NSFont.systemFont(ofSize: 11)],
                                   range: NSMakeRange(iconfontString.count+1, attr.string.count - iconfontString.count - 1))
                button?.attributedTitle = attr
            }
        }
        
        // 隐藏 zoomButton
        if let zoomButton = NSApplication.shared.keyWindow?.standardWindowButton(.zoomButton) {
            zoomButton.isHidden = true
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
        tableView.doubleAction = #selector(tableViewDoubleClick(_:))
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
    func refreshTable(_ map: [String : String]) {
        initData(map: map)
        self.tableView.reloadData()
    }
    
    // MARK: -  Action
    
    /// 双击列表处理
    ///
    /// - Parameter sender: NSTableView
    @objc func tableViewDoubleClick(_ sender: NSTableView) {
        if sender.clickedRow >= 0 { // 点击item，编辑配置
            let item = dataModels[tableView.selectedRow]
            self.configViewController.model(item)
            self.presentViewControllerAsSheet(self.configViewController)
        } else if sender.clickedColumn == 0 { // 关键字排序
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
        } else if sender.clickedColumn == 1 { // 内容排序
            // TODO: 后期完善
        }
    }
    
    /// 添加配置信息
    ///
    /// - Parameter sender: 添加按钮
    @IBAction func addConfigAction(_ sender: NSButton) {
        self.configViewController.model(HZConfigModel())
        self.presentViewControllerAsSheet(self.configViewController)
    }
    
    /// 删除配置信息
    ///
    /// - Parameter sender: 删除按钮
    @IBAction func removeConfigAction(_ sender: NSButton) {
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
    
    /// 导入配置
    ///
    /// - Parameter sender: 按钮
    @IBAction func importConfigListAction(_ sender: NSButton) {
        
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
    @IBAction func exportConfigListAction(_ sender: NSButton) {

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
    @IBAction func removeAllConfigAction(_ sender: Any) {
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
    @IBAction func helpAction(_ sender: Any) {
        showHelpWindow()
    }
    
    /// 显示帮助
    @objc private func showHelpWindow() {
        self.helpWindow.show(self)
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
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let key = dataModels[row].key
        let value = dataModels[row].value
        
        let cellIdentifier = tableColumn == tableView.tableColumns[0] ? "Key" : "Value"
        let text = tableColumn == tableView.tableColumns[0] ? key : value
        
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
