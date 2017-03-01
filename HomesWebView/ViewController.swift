//
//  ViewController.swift
//  HomesWebView
//
//  Created by UQ Times on 3/1/17.
//  Copyright © 2017 UQ Times. All rights reserved.
//

import UIKit
import Foundation
import Fuzi

class ViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    
    @IBOutlet weak var pricesView: UIView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var administrationCostLabel: UILabel!
    @IBOutlet weak var monthsLabel: UILabel!
    @IBOutlet weak var renewalCostLabel: UILabel!
    @IBOutlet weak var otherCostLabel: UILabel!
    @IBOutlet weak var totalCostLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.register(defaults: ["UserAgent" : "Mozilla/5.0 (iPhone; CPU iPhone OS 9_0 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13A344 Safari/601.1"])
        
        let url = "http://www.homes.co.jp"
        
        pricesView.isHidden = true
        webView.loadRequest(URLRequest(url: URL(string: url)!))
        webView.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onTouchBackButton(_ sender: UIButton) {
        webView.goBack()
    }
    
    @IBAction func onTouchForwardButton(_ sender: UIButton) {
        webView.goForward()
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        pricesView.isHidden = true
        return true
    }
    
    
    func webViewDidStartLoad(_ webView: UIWebView) {
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        let url = webView.stringByEvaluatingJavaScript(from: "document.URL")
        let html = webView.stringByEvaluatingJavaScript(from: "document.documentElement.outerHTML")
        
        do {
            let document = try HTMLDocument(string: html!, encoding: String.Encoding.utf8)
            let price = findPrice(document: document)
            let administrationCost = findAdministrationCost(document: document)
            let months = findDepositAndKeyMoney(document: document)
            let renewalCost = findRenewalCost(document: document)
            let otherCost = findOtherCost(document: document)
            
            priceLabel.text = String(format: "家賃: %.1f万円", Double(price) / 10000)
            administrationCostLabel.text = String(format: "管理費: %.1f万円", Double(administrationCost) / 10000)
            monthsLabel.text = String(format:"敷金: %.1f万円 / 礼金: %.1f万円", Double(months[0] * price) / 10000, Double(months[1] * price) / 10000)
            renewalCostLabel.text = String(format:"更新料: %.1f万円", Double(renewalCost * price) / 10000)
            otherCostLabel.text = String(format: "その他: %.1f万円", Double(otherCost) / 10000)
            let totalPrice = (price + administrationCost + (months[0] * price) + (months[1] * price) + (renewalCost * price) + otherCost)
            totalCostLabel.text = String(format: "合計: %.1f万円", Double(totalPrice) / 10000)
            
            pricesView.isHidden = (price == 0) ? true : false
            self.view.bringSubview(toFront: backButton)
            self.view.bringSubview(toFront: forwardButton)
        } catch let error {
            print(error)
        }
    }
    
    func findPrice(document: HTMLDocument) -> Int {
        if let element = document.firstChild(xpath: "//*[@id='contents']/div[1]/div[3]/table/tbody/tr[1]/td[1]/span/text()") {
            return toPrice(str: element.stringValue)
        }
        return 0
    }
    
    func findAdministrationCost(document: HTMLDocument) -> Int {
        if let element = document.firstChild(xpath: "//*[@id='contents']/div[1]/div[3]/table/tbody/tr[2]/td[1]/text()") {
            return toPrice(str: element.stringValue)
        }
        return 0
    }
    
    func findDepositAndKeyMoney(document: HTMLDocument) -> [Int] {
        if let element = document.firstChild(xpath: "//*[@id='contents']/div[1]/div[3]/table/tbody/tr[3]/td[1]/text()") {
            let arr:[String] = element.stringValue.components(separatedBy: "/")
            let deposit = toMonth(str: arr[0])
            let keymoney = toMonth(str: arr[1])
            
            return [deposit, keymoney]
            
        }
        return [0, 0]
    }
    
    func findRenewalCost(document: HTMLDocument) -> Int {
        if let element = document.firstChild(xpath: "//*[@data-chk='bkd-moneykoushin']/text()") {
            return toRenewalCost(str: element.stringValue)
        }
        return 0
    }
    
    func findOtherCost(document: HTMLDocument) -> Int {
        if let element = document.firstChild(xpath: "//*[@data-chk='bkd-moneyother']/text()") {
            return toOtherCost(str: element.stringValue)
        }
        return 0
    }
    
    
    func toPrice(str: String) -> Int {
        let priceString = str.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        let normalizedPriceString = priceString.replacingOccurrences(of: ",",
                                                                     with: "",
                                                                     options: .regularExpression,
                                                                     range: priceString.range(of: priceString))
        if normalizedPriceString.hasSuffix("万円") {
            if let price = Double(normalizedPriceString.replacingOccurrences(of: "万円",
                                                                             with: "",
                                                                             options: .regularExpression,
                                                                             range: normalizedPriceString.range(of: normalizedPriceString))) {
                return Int(price * 10000.0)
            }
        } else if normalizedPriceString.hasSuffix("千円") {
            if let price = Double(normalizedPriceString.replacingOccurrences(of: "千円",
                                                                             with: "",
                                                                             options: .regularExpression,
                                                                             range: normalizedPriceString.range(of: normalizedPriceString))) {
                return Int(price)
            }
        } else {
            if let price = Double(normalizedPriceString.replacingOccurrences(of: "円",
                                                                             with: "",
                                                                             options: .regularExpression,
                                                                             range: normalizedPriceString.range(of: normalizedPriceString))) {
                return Int(price)
            }
        }
        return 0
    }
    
    func toMonth(str: String) -> Int {
        let spanString = str.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if spanString.hasPrefix("-") {
            return 0
        }
        if (spanString.hasSuffix("ヶ月")) {
            if let span = Double(spanString.replacingOccurrences(of: "ヶ月",
                                                                 with: "",
                                                                 options: .regularExpression,
                                                                 range: spanString.range(of: spanString))) {
                return Int(span)
            }
        }
        return 0
    }
    
    func toRenewalCost(str: String) -> Int {
        let costString = str.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if (costString.hasSuffix("ヶ月分")) {
            let cost = costString.replacingOccurrences(of: "^.*賃料の(.+)ヶ月分$",
                                                       with: "$1",
                                                       options: .regularExpression,
                                                       range: costString.range(of: costString))
            return Int(cost)!
        }
        return 0
    }
    
    func toOtherCost(str: String) -> Int {
        var otherCost:Int = 0
        let normalizedCostString = str.replacingOccurrences(of: ",",
                                                            with: "",
                                                            options: .regularExpression,
                                                            range: str.range(of: str))
        for costStr in normalizedCostString.components(separatedBy: "、") {
            let s = costStr.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            if s.hasSuffix("円") {
                let cost = s.replacingOccurrences(of: "^.*?([0-9]+)円$",
                                                  with: "$1",
                                                  options: .regularExpression,
                                                  range: s.range(of: s))
                otherCost += Int(cost)!
            }
        }
        return otherCost
    }
    
}

