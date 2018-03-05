//
//  ViewController.swift
//  CodingTestLevi
//
//  Created by Deron Calbert  on 1/9/18.
//  This Coding Challenge 
//

import UIKit
import WebKit


class ViewController: UIViewController {
    @IBOutlet weak var webView: WKWebView!
    var product = ProductModel()
    var messageParse: String?
    let htmlFile: String = "confirm.html"
    let orderAcceptance:String = "Your order has been accepted"
    override func viewDidLoad() {
        super.viewDidLoad()
        webViewSetup()

        
       
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    func webViewSetup() {
        webView.navigationDelegate = self
        webView.configuration.userContentController.add(self, name: "callbackHandler")
        webView.configuration.userContentController.add(self, name: "getImage")
        webView.configuration.userContentController.add(self, name: "getTitle")
        let myURL = URL(string: "http://m.levi.com/US/en_US/categories/category~men~jeans~all/products")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func Alert() {
        let alert = UIAlertController(title: "Credit Card", message: String(), preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)
        let okAction = UIAlertAction(title: "ok", style: .default, handler: {(d) in
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let path = dir.appendingPathComponent(self.htmlFile)
                let thisRequest = URLRequest(url: path)
                self.webView.load(thisRequest)
            
            }
        })
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
        }
    func makeHtml() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="UTF-8">
        <title>title</title>
        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
        </head>
        <body>        <img src = \"\(self.product.imageSrc ?? "")\">
        <br>
        \(self.product.name   ?? "")
        <h2>\(self.product.price ?? "" ) </h2>
        <br>
        <h2>\(orderAcceptance)</h2>
        </body>
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
        <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>
        </html>
        


"""
    }
    func MakeComfirmationPage() {
       
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let path = dir.appendingPathComponent(self.htmlFile)
            do {
                try makeHtml().write(to: path, atomically: false, encoding:  String.Encoding.utf8)
            } catch let writeError {
                print(writeError)
            }
        
    }
    }
}

extension ViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()",
                                   completionHandler: { (html: Any?, error: Error?) in
                                    if let htmlString = html as? String {
                                        
                                        if htmlString.range(of: "product-container") != nil {
                                            print("found product")
                                            if (htmlString.range(of: "title=\"Add to Bag\"") != nil) {
                                                print("button found")
                                                webView.evaluateJavaScript("document.getElementsByClassName(\"btn primary full-width add-to-cart-btn\")[1].innerHTML = \"Pay Now\"", completionHandler: nil)
                                                let contentController = WKUserContentController();
                                                
                                                
                                                webView.configuration.userContentController = contentController
                                                
                                                webView.evaluateJavaScript("document.getElementsByClassName(\"btn primary full-width add-to-cart-btn\")[1].setAttribute('id','payNow')", completionHandler: nil)
                                                
                                                let js:String = "document.getElementsByClassName(\"btn primary full-width add-to-cart-btn\")[1].onclick = function(){ var x = targetPageParams(); window.webkit.messageHandlers.callbackHandler.postMessage(JSON.stringify(x)); window.webkit.messageHandlers.getImage.postMessage(document.getElementsByClassName(\"product-image\")[0].src); window.webkit.messageHandlers.getTitle.postMessage(document.getElementsByClassName(\"product-header\")[0].innerHTML)}"
                                                //let userScript = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
                                              //  webView.configuration.userContentController.addUserScript(userScript)
                                                webView.evaluateJavaScript("document.getElementsByClassName(\"product-image\")[0].src", completionHandler: nil )
                                                webView.evaluateJavaScript(js, completionHandler: nil )
                                                }
                                            }
                                        }
                                        })
    }
}
extension ViewController: WKScriptMessageHandler {
   
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if(message.name == "callbackHandler") {
           
            messageParse = message.body as? String
            let price:String.SubSequence = (messageParse?.split(separator: ",")[5]) ?? "not priced"
            var realPrice:String.SubSequence = price.split(separator: ":")[1]
            realPrice.removeFirst()
            realPrice.removeLast()
            self.product.price = "\(realPrice)"
            
            print(product.price as Any )
        }
        if message.name == "getImage" {
            //print(message.body as? String)
            product.imageSrc = String( describing: message.body)
            print(product.imageSrc as Any)
            
        }
        if message.name == "getTitle" {
            print(message.body)
            self.product.name = String(describing: message.body)
            MakeComfirmationPage()
            Alert()
        }
        
}
}
