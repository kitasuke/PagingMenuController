//
//  OrganizationsViewController.swift
//  PagingMenuControllerDemo
//
//  Created by Yusuke Kita on 5/10/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

class OrganizationsViewController: UITableViewController {
    var organizations = [[String: AnyObject]]()
    
    class func instantiateFromStoryboard() -> OrganizationsViewController {
        let storyboard = UIStoryboard(name: "MenuViewController", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: String(describing: self)) as! OrganizationsViewController
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: "https://api.github.com/organizations")
        let request = URLRequest(url: url!)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            let result = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [[String: AnyObject]]
            self?.organizations = result ?? []
            
            DispatchQueue.main.async(execute: { () -> Void in
                self?.tableView.reloadData()
            })
        }
        task.resume()
    }
}

extension OrganizationsViewController {
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return organizations.count
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) 
        
        let organization = organizations[(indexPath as NSIndexPath).row]
        cell.textLabel?.text = organization["login"] as? String
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}
