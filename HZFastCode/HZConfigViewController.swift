//
//  HZConfigViewController.swift
//  HZFastCode
//
//  Created by HertzWang on 2019/3/25.
//  Copyright © 2018年 HertzWang. All rights reserved.
//

import Cocoa

protocol HZConfigViewControllerProtocol: NSObjectProtocol {
    func modelUpdated(model: HZConfigModel, isAdd: Bool)
}

class HZConfigViewController: NSWindowController {
    
    var model: HZConfigModel!
    weak var delegate: HZConfigViewControllerProtocol?
    var isAdd: Bool = false
    
    @IBOutlet weak var keyText: NSTextField!
    @IBOutlet weak var valueText: NSTextField!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        
        self.window!.delegate = self;
        self.window?.title = "FastCode 配置"
    }
    
    func updateViewWith(model: HZConfigModel, isAdd: Bool){
        self.isAdd = isAdd
        self.model = model
        self.keyText.stringValue = ""
        if !model.key.isEmpty {
            self.keyText.stringValue = model.key
        }
        self.valueText.stringValue = ""
        if !model.value.isEmpty {
            self.valueText.stringValue = model.value
        }

        self.keyText.delegate = self
        self.valueText.delegate = self
            
        self.valueText.becomeFirstResponder()
    }
}

extension HZConfigViewController: NSWindowDelegate{
    func windowWillClose(_ notification: Notification) {
        delegate?.modelUpdated(model: self.model, isAdd: self.isAdd)
    }
}

extension HZConfigViewController: NSTextFieldDelegate, NSControlTextEditingDelegate{
    override func controlTextDidChange(_ obj: Notification){
        guard let textField = obj.object as? NSTextField else{
            return
        }
        if textField == self.keyText {
            model.key = textField.stringValue
        } else if textField == self.valueText {
            model.value = textField.stringValue
        }
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        var result = false
        if control == self.valueText {
            if commandSelector == #selector(insertNewline(_:)) {
                textView.insertNewlineIgnoringFieldEditor(self)
                result = true
            }else if commandSelector == #selector(insertTab(_:)){
                textView.insertTabIgnoringFieldEditor(self)
            }
        }
        return result
    }
}
