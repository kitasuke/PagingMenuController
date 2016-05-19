//
//  RepositoriesViewController.swift
//  PagingMenuControllerDemo
//
//  Created by Yusuke Kita on 5/10/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

class RepositoriesViewController: UITableViewController {
    var repositories = [[String: AnyObject]]()
    
    class func instantiateFromStoryboard() -> RepositoriesViewController {
        let storyboard = UIStoryboard(name: "MenuViewController", bundle: nil)
        return storyboard.instantiateViewControllerWithIdentifier(String(self)) as! RepositoriesViewController
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = NSURL(string: "https://api.github.com/repositories")
        let request = NSURLRequest(URL: url!)
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        
        let task = session.dataTaskWithRequest(request) { [weak self] data, response, error in
            let result = try? NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! [[String: AnyObject]]
            self?.repositories = result ?? []
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self?.tableView.reloadData()
            })
        }
        task.resume()
    }
}

extension RepositoriesViewController {
    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositories.count
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) 
        
        let repository = repositories[indexPath.row]
        cell.textLabel?.text = repository["name"] as? String
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
}