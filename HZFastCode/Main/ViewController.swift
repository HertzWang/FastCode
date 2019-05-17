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
    @IBOutlet weak var tableView: NSTableView!
    
    var keywordDesc: Bool = false
    var dataModels: [HZConfigModel] = []
    lazy var configWindow: HZConfigViewController = {
        let configWindow = HZConfigViewController(windowNibName: NSNib.Name.init("HZConfigViewController"))
        configWindow.delegate = self
        
        return configWindow
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
            self.configWindow.showWindow(self)
            self.configWindow.updateViewWith(model: item, isAdd: false)
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
        self.configWindow.showWindow(self)
        self.configWindow.updateViewWith(model: HZConfigModel(), isAdd: true)
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
            print("url \(panel.urls)")
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
        savePanel.nameFieldStringValue = "FastCode配置文件"
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
        alert.addButton(withTitle: "取消") // 默认为取消操作
        alert.addButton(withTitle: "清空")
        alert.messageText = "提示"
        alert.informativeText = "清空所有配置？"
        alert.alertStyle = .warning
        alert.beginSheetModal(for: self.view.window!) { (returnCode) in
            if returnCode.rawValue == NSApplication.ModalResponse.alertSecondButtonReturn.rawValue {
                // 清空
                HZUserConfig.shared.saveMapping([:])
                self.initData()
                self.tableView.reloadData()
            }
        }

    }
    
    /// 显示帮助
    @objc private func showHelpWindow() {
        print("show help window")
        self.helpWindow.showWindow(self)
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

// MARK: - HZConfigViewControllerProtocol
extension ViewController: HZConfigViewControllerProtocol {
    func modelUpdated(model: HZConfigModel, isAdd: Bool) {

        if isAdd {
            dataModels.append(model)
        } else {
            if tableView.selectedRow >= 0 {
                if model.isEmpty() {
                    dataModels.remove(at: tableView.selectedRow)
                } else {
                    dataModels[tableView.selectedRow] = model
                }
            }
        }
        
        self.tableView.reloadData()
        saveConfig()
    }
}
