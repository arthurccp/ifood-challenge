//
//  Parser.swift
//  ifood-challenge
//
//  Created by Arthur Silva on 14/10/26.
//

import Foundation

struct Parser {
    
    func parse(comp : @escaping ([Result]) -> ()){
        let api = URL(string: "https://rickandmortyapi.com/api/character/")
        
        URLSession.shared.dataTask(with: api!){
            data,response,error in
            if error != nil {
                print(error?.localizedDescription ?? 0 )
                return
            }
            do{
                let resultOne = try JSONDecoder().decode(ApiRest.self, from: data!)
                comp(resultOne.results)
            }catch{
                
            }
            
        }.resume()
    }
    
}
