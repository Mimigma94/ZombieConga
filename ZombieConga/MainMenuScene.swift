//
//  MainMenuScene.swift
//  ZombieConga
//
//  Created by Selina Kröcker on 29.08.18.
//  Copyright © 2018 Selina Piper. All rights reserved.
//

import Foundation
import SpriteKit

class MainMenuScene: SKScene {
    
    override func didMove(to view: SKView) {
        let backgroundScene = SKSpriteNode(imageNamed: "MainMenu")
        backgroundScene.position = CGPoint(x: size.width/2, y: size.height/2)
        self.addChild(backgroundScene)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        sceneTapped()
    }
    
    func sceneTapped() {
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = scaleMode
        
        let reveal = SKTransition.doorway(withDuration: 1.5)
        
        view?.presentScene(gameScene, transition: reveal)
    }
}
