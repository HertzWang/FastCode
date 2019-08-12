//
//  HZConfigurationViewController.swift
//  FastCode
//
//  Created by Wang, Haizhou on 2019/8/12.
//  Copyright © 2019 zhengjiacheng. All rights reserved.
//

import Cocoa

protocol HZConfigurationViewControllerProtocol: NSObjectProtocol {
    
    /// 更新数据
    ///
    /// - Parameters:
    ///   - model: 数据Model（HZConfigModel）
    ///   - isEdit: 是否为添加
    func modifyModel(model: HZConfigModel, isEdit: Bool)
}

class HZConfigurationViewController: NSViewController {

    // MARK: - Property
    
    /// 背景视图
    @IBOutlet fileprivate weak var bgView: NSView!
    /// 关键字
    @IBOutlet fileprivate weak var keywordTextField: NSTextField!
    /// 内容
    @IBOutlet fileprivate var contentTextView: NSTextView!
    
    /// 更新操作Protocol
    weak var delegate: HZConfigurationViewControllerProtocol?
    /// 数据Model
    fileprivate var model: HZConfigModel!
    /// 修改标记
    fileprivate var isEdit: Bool = false
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func awakeFromNib() {
        // 设置背景色及圆角
        self.bgView.wantsLayer = true
        self.bgView.layer?.backgroundColor = NSColor.init(red: 227.0/255.0, green: 225.0/255.0, blue: 226.0/255.0, alpha: 1.0).cgColor
        self.bgView.layer?.cornerRadius = 4
        self.bgView.needsDisplay = true
        
        self.keywordTextField?.stringValue = self.model.key
        self.contentTextView?.string = self.model.value
    }
    
    // MARK: - Public
    
    /// 设置显示的Model
    ///
    /// - Parameter model: 数据，添加时传 HZConfigModel()
    func model(_ model: HZConfigModel) {
        self.model = model
        self.isEdit = (model.key.trimmingCharacters(in: .whitespacesAndNewlines).count > 0)
        self.keywordTextField?.stringValue = self.model.key
        self.contentTextView?.string = self.model.value
    }
    
    // MARK: - Action
    
    @IBAction fileprivate func cancelAction(_ sender: Any) {
        self.dismiss(nil)
    }
    
    @IBAction fileprivate func confirmAction(_ sender: Any) {
        guard self.keywordTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 else {
            return;
        }
        guard self.contentTextView.string.count > 0 else {
            return;
        }
        
        self.model.key = self.keywordTextField.stringValue
        self.model.value = self.contentTextView.string
        
        delegate?.modifyModel(model: self.model, isEdit: self.isEdit)
        
        if delegate == nil {
            self.dismiss(nil)
        }
    }
}
