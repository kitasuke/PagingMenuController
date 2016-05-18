//
//  GistsViewController.swift
//  PagingMenuControllerDemo
//
//  Created by Yusuke Kita on 5/10/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

class GistsViewController: UITableViewController {
    var gists = [[String: AnyObject]]()
    
    class func instantiateFromStoryboard() -> GistsViewController {
        let storyboard = UIStoryboard(name: "MenuViewController", bundle: nil)
        return storyboard.instantiateViewControllerWithIdentifier(String(self)) as! GistsViewController
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = NSURL(string: "https://api.github.com/gists/public")
        let request = NSURLRequest(URL: url!)
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        
        let task = session.dataTaskWithRequest(request) { [weak self] data, response, error in
            let result = try? NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! [[String: AnyObject]]
            self?.gists = result ?? []
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self?.tableView.reloadData()
            })
        }
        task.resume()
    }
}

extension GistsViewController {
    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gists.count
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) 
        
        let gist = gists[indexPath.row]
        cell.textLabel?.text = gist["description"] as? String
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
}
