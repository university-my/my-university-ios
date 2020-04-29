//
//  GroupsTableViewController.swift
//  My University
//
//  Created by Yura Voevodin on 4/18/19.
//  Copyright © 2019 Yura Voevodin. All rights reserved.
//

import UIKit

class GroupsTableViewController: SearchableTableViewController {
    
    // MARK: - Properties
    
    var universityID: Int64?
    private var dataSource: GroupsDataSource?
    
    // MARK: - Notification
    
    @IBOutlet weak var statusButton: UIBarButtonItem!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // For notifications
        configureNotificationLabel()
        statusButton.customView = notificationLabel
        
        // Configure table
        tableView.rowHeight = UITableView.automaticDimension
        
        // Sear Bar and Search Results Controller
        configureSearchControllers()
        searchController.searchResultsUpdater = self
        
        // Always visible search bar
        navigationItem.hidesSearchBarWhenScrolling = false
        
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // This is for reloading data when the favorites are changed
        if let datasource = dataSource {
            datasource.performFetch()
            tableView.reloadData()
        }
        
        // Hide toolbar
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    func setup() {
        if let id = universityID {
            // Loading groups
            dataSource = GroupsDataSource(universityID: id)
            tableView.dataSource = dataSource
            loadGroups()
        }
    }
    
    // MARK: - Groups
    
    private func loadGroups() {
        guard let dataSource = dataSource else { return }
        dataSource.performFetch()
        
        let groups = dataSource.fetchedResultsController?.fetchedObjects ?? []
        if groups.isEmpty {
            importGroups()
        } else if needToUpdateGroups() {
            // Update groups once in a day
            importGroups()
        } else {
            tableView.reloadData()
            refreshControl?.endRefreshing()
            hideNotification()
        }
    }
    
    func importGroups() {
        guard let dataSource = dataSource else { return }
        
        dataSource.importGroups { (error) in

            if let error = error {
                self.showNotification(text: error.localizedDescription)
            } else {
                self.hideNotification()
                
                // Save date of last update
                if let id = self.universityID {
                    UpdateHelper.updated(at: Date(), universityID: id, type: .group)
                }
            }
            
            dataSource.performFetch()
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
    }
    
    /// Check last updated date of groups
    private func needToUpdateGroups() -> Bool {
        guard let id = universityID else { return false }
        let lastSynchronization = UpdateHelper.lastUpdated(for: id, type: .group)
        return UpdateHelper.needToUpdate(from: lastSynchronization)
    }
    
    // MARK: - Pull to refresh
    
    @IBAction func refresh(_ sender: Any) {
        guard !searchController.isActive else {
            refreshControl?.endRefreshing()
            return
        }
        importGroups()
    }
    
    // MARK - Table delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "groupDetailed", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
            
        case "groupDetailed":
            if let detailTableViewController = segue.destination as? GroupViewController {
                if searchController.isActive {
                    if let indexPath = resultsTableController.tableView.indexPathForSelectedRow {
                        let selectedGroup = resultsTableController.filteredGroups[safe: indexPath.row]
                        detailTableViewController.groupID = selectedGroup?.id
                    }
                } else {
                    if let indexPath = tableView.indexPathForSelectedRow {
                        let selectedGroup = dataSource?.fetchedResultsController?.object(at: indexPath)
                        detailTableViewController.groupID = selectedGroup?.id
                    }
                }
            }
            
        default:
            break
        }
    }
}

// MARK: - UISearchResultsUpdating

extension GroupsTableViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        // Strip out all the leading and trailing spaces.
        guard let text = searchController.searchBar.text else { return }
        let searchString = text.trimmingCharacters(in: .whitespaces)
        
        // Name field matching.
        let nameExpression = NSExpression(forKeyPath: "name")
        let searchStringExpression = NSExpression(forConstantValue: searchString)
        
        let nameSearchComparisonPredicate = NSComparisonPredicate(leftExpression: nameExpression, rightExpression: searchStringExpression, modifier: .direct, type: .contains, options: .caseInsensitive)
        
        // Update the filtered array based on the search text.
        guard let searchResults = dataSource?.fetchedResultsController?.fetchedObjects else { return }
        
        let filteredResults = searchResults.filter { nameSearchComparisonPredicate.evaluate(with: $0) }
        
        // Hand over the filtered results to our search results table.
        if let resultsController = searchController.searchResultsController as? SearchResultsTableViewController {
            resultsController.filteredGroups = filteredResults
            resultsController.dataSourceType = .groups
            resultsController.tableView.reloadData()
        }
    }
}
