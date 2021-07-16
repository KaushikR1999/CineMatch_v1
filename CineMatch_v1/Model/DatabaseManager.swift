import Foundation
import Firebase
import FirebaseStorage

struct DatabaseManager {
    
    let storageRef = Storage.storage().reference(forURL: "gs://cinematch-3cb3b.appspot.com")
    let metadata = StorageMetadata()
    
    let currentUserDetails = Firestore.firestore()
        .collection("User Details").document(Auth.auth().currentUser!.uid)
    let usernames = Firestore.firestore()
        .collection("Usernames")
    
    let currentUser = Auth.auth().currentUser
    
    
    func getFriends(callback: @escaping (_ friends: [String]) -> Void) {
        
        currentUserDetails.getDocument { (document, error) in
            if let document = document, document.exists {
                if let friends = document.data()!["Friends"] as? [String] {
                    callback(friends)

                }
            }
        }
    }
    
    
    func getSharedMovieIDS(friend: String, completion: @escaping ([Int]) -> Void) {
        
        currentUserDetails.getDocument { (document, error) in
            if let document = document, document.exists {
                if let movieIDs = document.data()!["LikedMovieIDs"] as? [Int] {
                    
                    let searchUserDetails = Firestore.firestore()
                        .collection("User Details").document(friend)
                    
                    searchUserDetails.getDocument { (document, error) in
                        if let document = document, document.exists {
                            if let friendMovieIDS = document.data()!["LikedMovieIDs"] as? [Int] {
                                
                                let sharedMovieIDS: [Int] = Set(movieIDs).filter(Set(friendMovieIDS).contains)
                                completion(sharedMovieIDS)
                                
                            }
                        }
                    }
                    
                }
            }
        }
        
    }
    
    func deleteFriend(_ SearchUserUID: String) {
        
        if currentUser != nil {
            currentUserDetails.updateData(
                ["Friends": FieldValue.arrayRemove([SearchUserUID])])
            { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    // print("Document successfully updated")
                }
            }
        }
        
        let searchUserDetails = Firestore.firestore()
            .collection("User Details").document(SearchUserUID)
        
        searchUserDetails.updateData(
            ["Friends": FieldValue.arrayRemove([currentUser!.uid])])
        { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                // print("Document successfully updated")
            }
        }
    }
    
    func getFriendRequests(callback: @escaping (_ friendRequests: [String]) -> Void) {
        
        currentUserDetails.getDocument { (document, error) in
            if let document = document, document.exists {
                if let friendRequests = document.data()!["FriendRequestsReceived"] as? [String] {
                    callback(friendRequests)

                }
            }
        }
    }
    

    func checkIfFriends(_ SearchUserUID: String, callback: @escaping (_ status: Bool) -> Void) {
        
        var friendArray: [String]?
        
        currentUserDetails.getDocument { (document, error) in
            if let document = document, document.exists {
                friendArray = document.data()!["Friends"] as? [String]
                callback(friendArray!.contains(SearchUserUID))
                
            }
        }
        
    }
    
    func checkForFriendReqButton (_ SearchUserUID: String, callback: @escaping (_ status: Bool) -> Void) {
        
        var friendReqSentArray: [String]?
        var friendReqReceivedArray: [String]?
        
        currentUserDetails.getDocument { (document, error) in
            if let document = document, document.exists {
                friendReqSentArray = document.data()!["FriendRequestsSent"] as? [String]
                friendReqReceivedArray = document.data()!["FriendRequestsReceived"] as? [String]
                callback(friendReqSentArray!.contains(SearchUserUID) || friendReqReceivedArray!.contains(SearchUserUID))
            }
        }

    }
    
                    
            
    func checkIfFriendReqSent(_ SearchUserUID: String) -> Bool {
        
        var friendReqSentArray: [String]?
        
        currentUserDetails.getDocument { (document, error) in
            if let document = document, document.exists {
                friendReqSentArray = document.data()!["FriendRequestsSent"] as? [String]
            }
        }
        
        if let friendReqsSent = friendReqSentArray {
            return friendReqsSent.contains(SearchUserUID)
        }
        
        return false

    }
    

    func checkIfFriendReqReceived(_ SearchUserUID: String) -> Bool {
        
        var friendReqReceivedArray: [String]?
        
        currentUserDetails.getDocument { (document, error) in
            if let document = document, document.exists {
                friendReqReceivedArray = document.data()!["FriendRequestsReceived"] as? [String]
            }
        }
        
        if let friendReqsReceived = friendReqReceivedArray {
            return friendReqsReceived.contains(SearchUserUID)
        }
        
        return false

    }
    

    func sendFriendReq(_ SearchUserUID: String) {
        
        if !checkIfFriendReqSent(SearchUserUID) && !checkIfFriendReqReceived(SearchUserUID) {
            
            if currentUser != nil {
                currentUserDetails.updateData(
                    ["FriendRequestsSent": FieldValue.arrayUnion([SearchUserUID])])
                { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        // print("Document successfully updated")
                    }
                }
            }
            
            let searchUserDetails = Firestore.firestore()
                .collection("User Details").document(SearchUserUID)
            
            searchUserDetails.updateData(
                ["FriendRequestsReceived": FieldValue.arrayUnion([currentUser!.uid])])
            { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    // print("Document successfully updated")
                }
            }
        }
        
        
    }
    
    func acceptFriendReq(_ SearchUserUID: String, callback: @escaping () -> Void) {
   
            if currentUser != nil {
                currentUserDetails.updateData(
                    ["Friends": FieldValue.arrayUnion([SearchUserUID]),
                     "FriendRequestsReceived": FieldValue.arrayRemove([SearchUserUID])])
                { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        let searchUserDetails = Firestore.firestore()
                            .collection("User Details").document(SearchUserUID)
                        
                        searchUserDetails.updateData(
                            ["Friends": FieldValue.arrayUnion([currentUser!.uid]),
                             "FriendRequestsSent": FieldValue.arrayRemove([currentUser!.uid])])
                        { err in
                            if let err = err {
                                print("Error updating document: \(err)")
                            } else {
                                callback()
                            }
                        }
                    }
                }
            }
            

    
        
        }
    
    func declineFriendReq(_ SearchUserUID: String, callback: @escaping () -> Void) {
        
        if currentUser != nil {
            currentUserDetails.updateData(
                ["FriendRequestsReceived": FieldValue.arrayRemove([SearchUserUID])])
            { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    let searchUserDetails = Firestore.firestore()
                        .collection("User Details").document(SearchUserUID)
                    
                    searchUserDetails.updateData(
                        ["FriendRequestsSent": FieldValue.arrayRemove([currentUser!.uid])])
                    { err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            callback()
                        }
                    }
                    
                }
            }
            
            
        }
        
    }
    

    func updateRegion(_ selectedCountry: String) {
        if currentUser != nil {
            currentUserDetails.updateData(
                ["Region": selectedCountry])
            { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    // print("Document successfully updated")
                }
            }
        }
    }
    
    func updateProfileImageURL(_ imageURL: String) {
        if currentUser != nil {
            currentUserDetails.updateData(
                ["profileImageURL": imageURL])
            { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    // print("Document successfully updated")
                }
            }
        }
    }
    
    func storeProfilePic(_ imageData: Data) {
        
        let storageProfileRef = storageRef.child("profile").child(Auth.auth().currentUser!.uid)
        metadata.contentType = "image/jpg"
        
        storageProfileRef.putData(imageData, metadata: metadata, completion:
                                    { (storageMetaData, error) in
                                        if error != nil {
                                            print(error?.localizedDescription ?? "Error!")
                                            return
                                        }
                                        
                                        // if no error, save url under profileImageURL in User Details collection
                                        storageProfileRef.downloadURL(completion: { (url, error) in
                                            if let metaImageURL = url?.absoluteString {
                                                updateProfileImageURL(metaImageURL)
                                            }
                                        })
                                        
                                    })
    }
    
    func setProfilePic(profilePicture: UIImageView!, profileURLString: String?){
        if let profileURL = URL(string: profileURLString!) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: profileURL) {
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            profilePicture.image = image
                        }
                    }
                }
            }
        }
    }
    
    
    func retrieveProfilePic(_ profileURLString: String) -> UIImage {
        
        if let profileURL = URL(string: profileURLString) {
            if let data = try? Data(contentsOf: profileURL) {
                if let image = UIImage(data: data) {
                    return image
                }
            }
        }
        
        return #imageLiteral(resourceName: "default pic")
    }
    
}


