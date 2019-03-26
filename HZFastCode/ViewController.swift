//
//  ViewController.swift
//  HZFastCode
//
//  Created by HertzWang on 2019/3/25.
//  Copyright © 2018年 HertzWang. All rights reserved.
//

import Cocoa

class HZConfigModel {
    var key: String = ""
    var value: String = ""
}

class ViewController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    
    var configViewConfig: HZConfigViewController!
    var dataModels: [HZConfigModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initData()
        configViewConfig = HZConfigViewController(windowNibName: NSNib.Name.init("HZConfigViewController"))
        configViewConfig.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.doubleAction = #selector(tableViewDoubleClick(_:))
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func initData(){
        var arr: [HZConfigModel] = []
        for (key, value) in HZUserConfig.shared.mapping {
            let m = HZConfigModel()
            m.key = key
            m.value = value
            arr.append(m)
        }
        self.dataModels = arr
    }
    
    func save(){
        var dic: [String: String] = [:]
        for model in self.dataModels {
            if !model.key.isEmpty,  !model.value.isEmpty {
                dic[model.key] = model.value
            }
        }
        HZUserConfig.shared.saveMapping(dic: dic)
    }
    
    @objc func tableViewDoubleClick(_ sender:AnyObject) {
        let item = dataModels[tableView.selectedRow]
        self.configViewConfig.showWindow(self)
        self.configViewConfig.updateViewWith(model: item, isAdd: false)
    }

    /// 添加配置信息
    ///
    /// - Parameter sender: 添加p按钮
    @IBAction func addConfigAction(_ sender: NSButton) {
        self.configViewConfig.showWindow(self)
        self.configViewConfig.updateViewWith(model: HZConfigModel(), isAdd: true)
    }
    
    @IBAction func importConfigListAction(_ sender: NSButton) {
        
        let alert = NSAlert()
        alert.addButton(withTitle: "确定")
        alert.messageText = "提示"
        alert.informativeText = "功能开发中..."
        alert.alertStyle = .warning
        alert.beginSheetModal(for: self.view.window!) { (returnCode) in

        }
    }
    
    @IBAction func exportConfigListAction(_ sender: NSButton) {
        
        let alert = NSAlert()
        alert.addButton(withTitle: "确定")
        alert.messageText = "提示"
        alert.informativeText = "功能开发中..."
        alert.alertStyle = .warning
        alert.beginSheetModal(for: self.view.window!) { (returnCode) in
            
        }
        
    }
    
    
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return dataModels.count
    }
}

extension ViewController: HZConfigViewControllerProtocol{
    func modelUpdated(model: HZConfigModel, isAdd: Bool){

        if isAdd {
            dataModels.append(model)
        } else {
            if tableView.selectedRow >= 0{
                dataModels[tableView.selectedRow] = model
            }
        }
        self.tableView.reloadData()
        save()
    }
}

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




