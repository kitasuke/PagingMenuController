//
//  UsersViewController.swift
//  PagingMenuControllerDemo
//
//  Created by Yusuke Kita on 5/10/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

class UsersViewController: UITableViewController {
    var users = [[String: AnyObject]]()
    
    class func instantiateFromStoryboard() -> UsersViewController {
        let storyboard = UIStoryboard(name: "MenuViewController", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: String(describing: self)) as! UsersViewController
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: "https://api.github.com/users")
        let request = URLRequest(url: url!)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            let result = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [[String: AnyObject]]
            self?.users = result ?? []
            
            DispatchQueue.main.async(execute: { () -> Void in
                self?.tableView.reloadData()
            })
        }
        task.resume()
    }
}

extension UsersViewController {
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) 
        
        let user = users[(indexPath as NSIndexPath).row]
        cell.textLabel?.text = user["login"] as? String
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}
