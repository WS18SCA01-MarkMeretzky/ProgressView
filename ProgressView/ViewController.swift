//
//  ViewController.swift
//  ProgressView
//
//  Created by Mark Meretzky on 3/14/19.
//  Copyright © 2019 New York University School of Professional Studies. All rights reserved.
//
//  See "Fetching Website Data into Memory",
//  https://developer.apple.com/documentation/foundation/url_loading_system/fetching_website_data_into_memory
//

/*
 21 response headers:
 
 x-cache: cp1086 hit/30, cp1076 pass
 timing-allow-origin: *
 x-trans-id: tx5d0bf41a3bc74c83ab676-005c8a46ba
 Access-Control-Allow-Origin: *
 server-timing: cache;desc="hit-local"
 access-control-expose-headers: Age, Date, Content-Length, Content-Range, X-Content-Duration, X-Cache, X-Varnish
 Content-Length: 65150402
 x-cache-status: hit-local
 Via: 1.1 varnish (Varnish/5.1), 1.1 varnish (Varnish/5.1)
 Age: 0
 x-varnish: 32077786 1631575, 667148293
 Last-Modified: Fri, 17 Oct 2014 19:16:58 GMT
 Accept-Ranges: bytes
 x-analytics: https=1;nocookies=1
 x-object-meta-sha1base36: 7gp5u3a0zprd8vxsm334dw3omr7icug
 x-client-ip: 66.108.88.87
 Strict-Transport-Security: max-age=106384710; includeSubDomains; preload
 x-timestamp: 1413573417.88948
 Content-Type: image/jpeg
 Date: Thu, 14 Mar 2019 20:02:57 GMT
 Etag: d30768abfb7397ca0b6e3fd8113f4ead
*/

import UIKit;

class ViewController: UIViewController, URLSessionDataDelegate {
    var session: URLSession?
    var receivedData: Data? = Data(); //for all downloaded data, initially empty
    var expectedContentLength: Int64 = -1;
    
    @IBOutlet weak var imageView: UIImageView!;
    @IBOutlet weak var progressView: UIProgressView!;
    
    override func viewDidLoad() {
        super.viewDidLoad();

        // Do any additional setup after loading the view, typically from a nib.

        let configuration: URLSessionConfiguration = URLSessionConfiguration.default;
        configuration.waitsForConnectivity = true;
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil);
        
        // https://en.wikipedia.org/wiki/Pinwheel_Galaxy
        // Content length 65,150,402; 15,852 × 12,392 pixels.
        let string: String = "https://upload.wikimedia.org/wikipedia/commons/c/c5/M101_hires_STScI-PRC2006-10a.jpg";
        
        guard let url: URL = URL(string: string) else {
            fatalError("could not create URL from string \"\(string)\"");
        }
        print("url = \(url)");
        
        let task: URLSessionTask = session!.dataTask(with: url); //only 1 argument, no closure
        task.resume();
    }
    
    // MARK: - Protocol URLSessionDataDelegate
    // This method is called once, at start of download.
    // Must pass either .cancel, .allow, or .becomeDownload to the completionHandler.
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        guard let response: HTTPURLResponse = response as? HTTPURLResponse else {
            print("urlSession(_:dataTask:didReceive:completionHandler) did not receive HTTPURLResponse");
            completionHandler(.cancel);
            return;
        }
        
        print("urlSession(_:dataTask:didReceive:completionHandler) received \(response.allHeaderFields.count) response headers:");
        response.allHeaderFields.forEach {print("\t\($0.key): \($0.value)");}
        print();
        
        //Two ways to find the content length:
        
        if let contentLength: String = response.allHeaderFields["Content-Length"] as? String {
            print("contentLength = \(contentLength)");
        }
        expectedContentLength = response.expectedContentLength;
        print("response.expectedContentLength = \(response.expectedContentLength)");
        
        guard (200 ..< 300).contains(response.statusCode) else {
            print("urlSession(_:dataTask:didReceive:completionHandler) received statusCode \(response.statusCode)");
            completionHandler(.cancel);
            return;
        }
        print("response.statusCode = \(response.statusCode)");
        
        guard let mimeType: String = response.mimeType else {
            print("urlSession(_:dataTask:didReceive:completionHandler) received no mimeType");
            completionHandler(.cancel);
            return;
        }
        print("mimeType = \(mimeType)");
        print()
        
        completionHandler(.allow);
    }
    
    // This method may be called more than once, during download.

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receivedData?.append(data);
        DispatchQueue.main.async {
            self.progressView.progress = Float(self.receivedData!.count) / Float(self.expectedContentLength);
        }

        print("urlSession(_:dataTask:didReceive:) received another \(data.count) bytes, bringing the total to \(receivedData!.count) out of \(expectedContentLength)");
    }
    
    // MARK: - Protocol URLSessionTaskDelegate
    // This method is called once, at end of download.
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if let error: Error = error {
            fatalError("urlSession(_:task:didCompleteWithError:), error = \(error)");
        }
        
        guard let receivedData: Data = receivedData else {
            fatalError("urlSession(_:task:didCompleteWithError:), receivedData is nil");
        }
        
        print("urlSession(_:task:didCompleteWithError:), received a total of \(receivedData)");
        
        guard let image: UIImage = UIImage(data: receivedData) else {
            fatalError("could not create UIImage");
        }

        DispatchQueue.main.async {
            self.progressView.isHidden = true;
            self.imageView.isHidden = false;
            self.imageView.image = image;
        }
    }

}
