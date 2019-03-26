//
//  RecordDetailedTableViewController.swift
//  My University
//
//  Created by Yura Voevodin on 2/17/19.
//  Copyright © 2019 Yura Voevodin. All rights reserved.
//

import UIKit

class RecordDetailedTableViewController: UITableViewController {
    
    // MARK: - Types
    
    enum SectionType {
        case date(dateString: String)
        case pairName(name: String?, type: String?)
        case reason(reason: String)
        case auditorium(auditorium: AuditoriumEntity)
        case teacher(teacher: TeacherEntity)
        case groups(groups: NSSet)
        
        var name: String {
            switch self {
            case .auditorium:
                return NSLocalizedString("AUDITORIUM", comment: "")
            case .date(_):
                return NSLocalizedString("DATE", comment: "")
            case .groups(let groups):
                if groups.count > 1 {
                    return NSLocalizedString("GROUPS", comment: "")
                } else {
                    return NSLocalizedString("GROUP", comment: "")
                }
            case .pairName(_):
                return NSLocalizedString("NAME", comment: "")
            case .reason:
                return NSLocalizedString("DESCRIPTION", comment: "")
            case .teacher:
                return NSLocalizedString("TEACHER", comment: "")
            }
        }
    }
    
    // MARK: - Properties
    
    weak var record: RecordEntity?
    
    private var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        return dateFormatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = record?.name
        sections = generateSections()
    }
    
    // MARK: - Sections
    
    private var sections: [SectionType] = []
    
    private func generateSections() -> [SectionType] {
        guard let record = record else { return [] }
        var sections: [SectionType] = []
        
        // Date
        if let date = record.date {
            let dateString = dateFormatter.string(from: date)
            sections.append(.date(dateString: dateString))
        }
        
        // Name and type
        if record.name != nil || record.type != nil {
            sections.append(.pairName(name: record.name, type: record.type))
        }
        
        // Description
        if let description = record.reason, description.isEmpty == false {
            sections.append(.reason(reason: description))
        }
        
        // Auditorium
        if let auditorium = record.auditorium {
            sections.append(.auditorium(auditorium: auditorium))
        }
        
        // Teacher
        if let teacher = record.teacher {
            sections.append(.teacher(teacher: teacher))
        }
        
        // Groups
        if let groups = record.groups, groups.count != 0 {
            sections.append(.groups(groups: groups))
        }
        
        return sections
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        if case let SectionType.groups(groups) = section {
            return groups.count
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recordDetailed", for: indexPath)
        
        let row = sections[indexPath.section]
        
        switch row {
            
        case .date(let dateString):
            // Date
            cell.textLabel?.text = dateString
            
            // Name and time
            var detail = ""
            if let pairName = record?.pairName, let time = record?.time {
                detail += pairName + " (\(time))"
            } else if let time = record?.time {
                detail += "(\(time))"
            }
            cell.detailTextLabel?.text = detail
            
        case .pairName(let name, let type):
            if let name = name {
                cell.textLabel?.text = name
                cell.detailTextLabel?.text = type
            } else if let type = type {
                cell.textLabel?.text = type
            }
            
        case .reason(let reason):
            cell.textLabel?.text = reason
            cell.detailTextLabel?.text = nil
            
        case .auditorium(let auditorium):
            cell.textLabel?.text = auditorium.name
            cell.detailTextLabel?.text = nil
            
        case .teacher(let teacher):
            cell.textLabel?.text = teacher.name
            cell.detailTextLabel?.text = nil
            
        case .groups(let groups):
            let group = Array(groups)[indexPath.row] as? GroupEntity
            cell.textLabel?.text = group?.name
            cell.detailTextLabel?.text = nil
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].name
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let bgColorView = UIView()
        bgColorView.backgroundColor = .cellSelectionColor
        cell.selectedBackgroundView = bgColorView
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let section = sections[indexPath.section]
//
//        switch section {
//
//        case .auditorium(let auditorium):
//            performSegue(withIdentifier: "showAuditorium", sender: auditorium)
//
//        case .groups(let groups):
////            performSegue(withIdentifier: "showGroup", sender: auditorium)
//            break
//
//        case .teacher(let teacher):
//            performSegue(withIdentifier: "showTeacher", sender: teacher)
//
//        default:
//            break
//        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
            
        case "showAuditorium":
            if let destination = segue.destination as? AuditoriumScheduleTableViewController {
                destination.auditorium = sender as? AuditoriumEntity
            }
            
        case "showTeacher":
            if let destination = segue.destination as? TeacherScheduleTableViewController {
                destination.teacher = sender as? TeacherEntity
            }
            
        default:
            break
        }
    }
}