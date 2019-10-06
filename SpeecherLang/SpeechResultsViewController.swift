//
//  SpeechResultsViewController.swift
//  SpeecherLang
//
//  Created by Alfian Losari on 06/10/19.
//  Copyright © 2019 Alfian Losari. All rights reserved.
//

import UIKit
import NaturalLanguage

enum SpeechResultItem {
    
    case text(String)
    case token([String])
    case error(NSError)
    
}

class SpeechResultsViewController: UITableViewController {

    
    private var result: String?
    private var isFinal = false
    private var items: [SpeechResultItem] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(UINib(nibName: "TokenTableViewCell", bundle: nil), forCellReuseIdentifier: "TokenCell")
    }
    
    func update(_ result: String?, isFinal: Bool) {
        self.result = result
        self.isFinal = isFinal
        self.items = generateItems()
        self.tableView.reloadData()
    }
    
    func update(_ error: NSError) {
        self.items = [.error(error)]
        self.tableView.reloadData()
    }
    
    private func generateItems() -> [SpeechResultItem] {
        guard let result = self.result else { return [] }
        var items = [SpeechResultItem]()
        items.append(.text(result))
        
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = result
        
        var tokens = [String]()

        tokenizer.enumerateTokens(in: result.startIndex..<result.endIndex) { tokenRange, _ in
            let text = String(result[tokenRange])
            tokens.append(text)
            return true
        }
        
        if tokens.count > 0 {
            items.append(.token(tokens))
        }

        
        return items
    }
    
}


extension SpeechResultsViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.items[indexPath.section]
        
        switch item {
        case .text(let text):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
            cell.textLabel?.text = text
            cell.textLabel?.numberOfLines = 0
            cell.selectionStyle = .none
            return cell
            
        case .error(let error):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
            cell.textLabel?.text = error.localizedDescription
            cell.textLabel?.numberOfLines = 0
            cell.selectionStyle = .none
            return cell
            
        
        case .token(let results):
            let cell = tableView.dequeueReusableCell(withIdentifier: "TokenCell", for: indexPath) as! TokenTableViewCell
            cell.update(texts: results, tableView: self.tableView)
            return cell
            
        }
                
    }
    
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let item = self.items[section]
        
        switch item {
        case .text(_):
            return "Transcription"
            
            
        case .token(_):
            return "Word Tokens"
            
        case .error(_):
            return "Error"
            
        }
        
        
    }
    
}
