//
//  InboxViewController.swift
//  Sample
//
//  Created by 1amageek on 2018/07/27.
//  Copyright © 2018年 1amageek. All rights reserved.
//

import UIKit
import Pring
import FirebaseAuth

extension Muni {
    open class InboxViewController: UITableViewController {

        public let dataSource: DataSource<RoomType>

        public let userID: String

        public let limit: Int

        public init(userID: String, limit: Int = 20) {
            self.userID = userID
            self.limit = limit
            let options: Options = Options()
            options.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: true)]
            self.dataSource = RoomType.where("members.\(userID)", isEqualTo: true)
                .order(by: "updatedAt", descending: false)
                .limit(to: limit)
                .dataSource(options: options)
            super.init(nibName: nil, bundle: nil)
        }

        public required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        open override func loadView() {
            super.loadView()
            self.tableView.register(UINib(nibName: "InboxViewCell", bundle: nil), forCellReuseIdentifier: "InboxViewCell")
        }

        open override func viewDidLoad() {
            super.viewDidLoad()
            self.dataSource
                .on(parse: { (_, room, done) in
                    room.configs.get(self.userID) { (config, error) in
                        done(room)
                    }
                })
                .on({ [weak self] (snapshot, changes) in
                    guard let tableView: UITableView = self?.tableView else { return }
                    switch changes {
                    case .initial:
                        tableView.reloadData()
                    case .update(let deletions, let insertions, let modifications):
                        tableView.beginUpdates()
                        tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                        tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                        tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                        tableView.endUpdates()
                    case .error(let error):
                        print(error)
                    }
                }).listen()
        }

        open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return self.dataSource.count
        }

        open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let room: RoomType = self.dataSource[indexPath.item]
            let cell: InboxViewCell = tableView.dequeueReusableCell(withIdentifier: "InboxViewCell", for: indexPath) as! InboxViewCell

            if let name: String = room.name {
                cell.nameLabel.text = name
            } else {
                room.configs.get(self.userID) { (config, error) in
                    cell.nameLabel.text = config?.name
                    cell.setNeedsLayout()
                }
            }

            if let text: String = room.recentTranscript["text"] as? String {
                cell.messageLabel?.text = text
            }
            return cell
        }

        open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let room: RoomType = self.dataSource[indexPath.item]
            let viewController: MessageViewController = MessageViewController(roomID: room.id)
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
