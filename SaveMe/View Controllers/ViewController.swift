//
//  ViewController.swift
//  SaveMe
//
//  Created by STH on 2017/7/10.
//  Copyright © 2017年 STH. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var clockLabel: UILabel!
    
    var timer:Timer!
    var myTimeCoumnt: Int = 24
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.tickDown), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tickDown() {
        clockLabel.text = String(myTimeCoumnt)
        myTimeCoumnt = myTimeCoumnt - 1
        
        if ( myTimeCoumnt == -1 ) {
            timer.invalidate()
            self.saveMeButtonTapped(nil)
        }
    }

    @IBAction func saveMeButtonTapped(_ sender: Any?) {
        print("SaveMe button tapper")
    }

    @IBAction func setButtonTapped(_ sender: UIButton) {
        timer.invalidate()
        print("Setting button tapper")
    }
    
}

