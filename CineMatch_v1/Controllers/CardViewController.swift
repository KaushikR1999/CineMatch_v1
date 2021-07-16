//
//  CardViewController.swift
//  CineMatch_v1
//
//  Created by Kaushik Kumar on 16/7/21.
//

import UIKit
import Koloda
import Kingfisher
import Firebase

class CardViewController: UIViewController {

    @IBOutlet weak var kolodaView: KolodaView!
    
    let databaseManager = DatabaseManager()
    
    var cards = [MovieCard]()
    var totalCardIndex = 0
    var pageNumber = 0
    
    

    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()

        //Do any additional setup after loading the view.
        
        databaseManager.currentUserDetails.getDocument { (snapshot, error) in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            
            guard let tci = data["totalCardIndex"] as? Int else {
                return
            }
            
            self.totalCardIndex = tci
            let totalCardNumber = self.totalCardIndex + 1
            self.pageNumber = (totalCardNumber / 20) + 1
            let cardNumberOnPage = self.totalCardIndex % 20
            

            
            self.loadMovieCards(page: self.pageNumber) { movieCardDetails in
                self.cards = movieCardDetails
    
                self.cards.removeFirst(cardNumberOnPage)
                print(self.cards)
                self.kolodaView.reloadData()
            }
        }
        
        

        kolodaView.layer.cornerRadius = 20
        kolodaView.clipsToBounds = true
        
        kolodaView.dataSource = self
        kolodaView.delegate = self
        

 
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = false
        
    }
    
    

    
    private func loadMovieCards(page: Int, completion: @escaping (([MovieCard]) ->Void )) {
        CardViewModel.shared.fetchMovieCards(page: page) { movieCardDetails in
            completion(movieCardDetails)
        }
    }
}


extension CardViewController: KolodaViewDelegate, KolodaViewDataSource {
    
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        
        let movieCard = cards[index]
        
        let movieCardPoster = UIImageView()
        
        guard let posterString = movieCard.poster_path else {
            return movieCardPoster
            
        }
        
        let urlString = "https://image.tmdb.org/t/p/w780" + posterString
        
        guard let posterImageURL = URL(string: urlString) else {
            return movieCardPoster
        }
        

        movieCardPoster.kf.setImage(with: posterImageURL)
        movieCardPoster.contentMode = .scaleAspectFill
        
        
        return movieCardPoster
    }
    
    func kolodaNumberOfCards(_ koloda: KolodaView) -> Int {
        return cards.count
    }
    
    
    func koloda(_ koloda: KolodaView, didSelectCardAt index: Int) {
        
        let movieCard = cards[index]
        CardViewModel.shared.fetchMovieDetails(id: movieCard.id!) { movieDetails in
            let rootVC = self.storyboard?.instantiateViewController(identifier: "MovieDetailsViewController") as! MovieDetailsViewController
            
            rootVC.movieDetails = movieDetails

            self.navigationController?.pushViewController(rootVC, animated: true)
        }

    }
    
    func kolodaShouldTransparentizeNextCard(_ koloda: KolodaView) -> Bool {
        return false
    }
    
    
    
    func koloda(_ koloda: KolodaView, didSwipeCardAt index: Int, in direction: SwipeResultDirection) {
        
        
        totalCardIndex += 1
        databaseManager.currentUserDetails.updateData(["totalCardIndex": totalCardIndex])
        
        
        if direction == .right {
            databaseManager.currentUserDetails.updateData([
            "LikedMovieIDs": FieldValue.arrayUnion([cards[index].id])
            ]
            )
        }
        
        
    }
    
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
        pageNumber += 1
        print(pageNumber)
        DispatchQueue.main.async {
            self.loadMovieCards(page: self.pageNumber) { movieCardDetails in
                self.cards = movieCardDetails
                koloda.resetCurrentCardIndex()
            }
        }

    }
    
    
    func kolodaShouldApplyAppearAnimation(_ koloda: KolodaView) -> Bool {
        return false
    }
    
//
//    func printCards(_ cards: [MovieCard]) {
//        var s = ""
//        for card in cards {
//            s += "\(card.id) + , "
//        }
//        print(s)
//
//    }
    
}
