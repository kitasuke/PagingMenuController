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
        return storyboard.instantiateViewController(withIdentifier: String(describing: self)) as! RepositoriesViewController
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: "https://api.github.com/repositories")
        let request = URLRequest(url: url!)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            let result = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [[String: AnyObject]]
            self?.repositories = result ?? []
            
            DispatchQueue.main.async(execute: { () -> Void in
                self?.tableView.reloadData()
            })
        }
        task.resume()
    }
}

extension RepositoriesViewController {
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositories.count
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) 
        
        let repository = repositories[(indexPath as NSIndexPath).row]
        cell.textLabel?.text = repository["name"] as? String
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}
