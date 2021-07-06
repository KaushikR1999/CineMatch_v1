import UIKit
import Firebase

class HomeViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var friendRequestsIcon: UIBarButtonItem!
    
    let db = Firestore.firestore()
    let databaseManager = DatabaseManager()
    
    var friends: [SearchUser] = []
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//    }
    
//    override func viewWillAppear(_ animated: Bool) {
    override func viewDidLoad() {
        super.viewDidLoad()
//        super.viewWillAppear(true)
        // Do any additional setup after loading the view.
        
        tableView.dataSource = self
        
//        var friendsUID: [String] = []
//        friends = []
//        let userDetails = db.collection("User Details")
        
//        if Auth.auth().currentUser != nil {
//            userDetails.document(Auth.auth().currentUser!.uid)
//                .addSnapshotListener () { documentSnapshot, error in
//                    guard let document = documentSnapshot else {
//                        print("Error fetching document: \(error!)")
//                        return
//                    }
//                    DispatchQueue.global().async {
//                        friendsUID = document.data()!["Friends"] as! [String]
//                        print ("Before \(friendsUID.count)")
//                        print ("Before \(self.friends.count)")
//                        for friendUID in friendsUID {
//
//                            userDetails.document(friendUID).addSnapshotListener () { documentSnapshot, error in
//                                guard let document = documentSnapshot else {
//                                    print("Error fetching document: \(error!)")
//                                    return
//                                }
//                                    let profileURLString = document.data()?["profileImageURL"] as? String
//                                    self.friends.append(SearchUser(
//                                                            searchUserName: (document.data()!["Username"] as? String)!,
//                                                            searchUserImage: self.databaseManager.retrieveProfilePic(profileURLString!),
//                                                            searchUserUID: document.documentID))
//                                    print ("During \(friendsUID.count)")
//                                    print ("During \(self.friends.count)")
//                            }
//                        }
//                        DispatchQueue.main.async {
//                            self.tableView.reloadData()
//                        }
//                    }
//                    print ("After \(friendsUID.count)")
//                    print ("After \(self.friends.count)")
//                }
//        }
        
//        DispatchQueue.main.async {
//            self.tableView.reloadData()
//        }

        
        databaseManager.getFriendRequests(callback: { (friendRequestsReceived) in
            
            if friendRequestsReceived.count > 0 {
                self.friendRequestsIcon.image = UIImage(systemName: "person.crop.circle.badge.exclamationmark")
            } else {
                self.friendRequestsIcon.image = UIImage(systemName: "person.2.fill")
            }
        })

        
        // friends = []
        let userDetails = db.collection("User Details")
        databaseManager.getFriends(callback: { (friendArray) in
            for friend in friendArray {
                userDetails.document(friend).getDocument { (document, error) in
                    if let document = document, document.exists {
                        let profileURLString = document.data()!["profileImageURL"] as? String
                        self.friends.append(SearchUser(
                                                searchUserName: (document.data()!["Username"] as? String)!,
                                                searchUserImage: self.databaseManager.retrieveProfilePic(profileURLString!),
                                                searchUserUID: document.documentID))
                    }

                    self.friends = self.friends.sorted(by: { $0.searchUserName < $1.searchUserName })
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }

            }

        }
        )
        
        tableView.register(UINib(nibName: "FriendSessionCell", bundle: nil), forCellReuseIdentifier: "ReusableCell")
    }
}

// MARK: - TableView DataSource Methods

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReusableCell", for: indexPath) as! SearchUserSessionCell
        cell.searchUserName.text = friends[indexPath.row].searchUserName
        cell.searchUserImage.image = friends[indexPath.row].searchUserImage
 
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            databaseManager.deleteFriend(friends[indexPath.row].searchUserUID)
            tableView.beginUpdates()
            friends.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
            
        }
    }
}
