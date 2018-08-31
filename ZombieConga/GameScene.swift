//
//  GameScene.swift
//  ZombieConga
//
//  Created by Selina Kröcker on 24.08.18.
//  Copyright © 2018 Selina Piper. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    //--------------------------------------------------
    // MARK: - Properties
    //--------------------------------------------------
    
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    let zombieMovePointsPerSec: CGFloat = 480.0
    let zombieRotateRadiansPerSec: CGFloat = 4.0 * π
    let zombieAnimation: SKAction
    var zombieIsInvincible = false
    
    let catsMovePointsPerSec: CGFloat = 480.0
    
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    var velocity = CGPoint.zero
    
    let background = SKSpriteNode(imageNamed: "background1")
    let playableRect: CGRect
    let cameraNode = SKCameraNode()
    let cameraMovePointsPerSec : CGFloat = 200.0
    var cameraRect: CGRect {
        let x = cameraNode.position.x - size.width/2
            + (size.width - playableRect.width)/2
        let y = cameraNode.position.y - size.height/2
            + (size.height - playableRect.height)/2
        return CGRect(
            x: x,
            y: y,
            width: playableRect.width,
            height: playableRect.height)
    }
    
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false)
    
    var lives = 5
    var gameOver = false
    
    let livesLabel = SKLabelNode(fontNamed: "Chalkduster")
    let catsLabel = SKLabelNode(fontNamed: "Chalkduster")
    
    //--------------------------------------------------
    // MARK: - Lifecycle
    //--------------------------------------------------
    
    // Die Boundaries an den standartbildschirm der IPhones 16:9 anpassen (Schritt 1-6)
    override init (size: CGSize) {
        let maxAspectRatio: CGFloat = 16.0/9.0 //1
        let playableHeight = size.width / maxAspectRatio //2
        let playableMargin = (size.height-playableHeight)/2 //3
        playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight) //4
        
        var textures: [SKTexture] = []
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        textures.append(textures[2])
        textures.append(textures[3])
        
        zombieAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)
        super.init(size: size) //5
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented") //6
    }
        
    override func didMove(to view: SKView) {
        for i in 0...1 {
        let background = backgroundNode()
        background.anchorPoint = CGPoint.zero
            background.position = CGPoint(x: CGFloat(i)*background.size.width, y: 0)
        background.name = "background"
        background.zPosition = -1
        addChild(background)
        }
        
        zombie.position = CGPoint(x: 400, y: 400)
        zombie.zPosition = 100
        //  zombie.setScale(2.0)
        addChild(zombie)
        //zombie.run(SKAction.repeatForever(zombieAnimation))
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run() { [weak self] in self?.spawnEnemy()
                },
                SKAction.wait(forDuration: 2.0)])))
        
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run() { [weak self] in self?.spawnCat()
                },
                SKAction.wait(forDuration: 1.0)])))
        
        let mySize = background.size
        print("Size: \(mySize)")
        //debugDrawPlayableArea()
        playBackgroundMusic(filename: "backgroundMusic.mp3")
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width/2, y: size.height/2)
        
        self.updateLivesLabel()
        livesLabel.fontColor = SKColor.black
        livesLabel.fontSize = 100
        livesLabel.zPosition = 150
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.verticalAlignmentMode = .bottom
        //die CGFloat(20) sorgt dafür, dass noch Platz zwischen der Schrift und den Kanten ist
        livesLabel.position = CGPoint(x: -playableRect.size.width/2 + CGFloat(20), y: -playableRect.size.height/2 + CGFloat(20))
        cameraNode.addChild(livesLabel)
        
        self.updateCatsLabel(trainCount: 0)
        catsLabel.fontColor = SKColor.black
        catsLabel.fontSize = 100
        catsLabel.zPosition = 150
        catsLabel.horizontalAlignmentMode = .right
        catsLabel.verticalAlignmentMode = .bottom
        //die CGFloat(20) sorgt dafür, dass noch Platz zwischen der Schrift und den Kanten ist
        catsLabel.position = CGPoint(x: playableRect.size.width/2 - CGFloat(20), y: -playableRect.size.height/2 + CGFloat(20))
        cameraNode.addChild(catsLabel)
    }
    
    func updateLivesLabel() {
        livesLabel.text = "Lives: \(lives)"
    }
    
    func updateCatsLabel(trainCount: Int) {
        catsLabel.text = "Cats: \(trainCount)"
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        move(sprite: zombie, velocity: velocity)
        boundsCheckZombie()
        rotateZombie(sprite: zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
        //checkCollisions()
        self.moveTrain()
        self.moveCamera()
        
        if lives <= 0 && !gameOver {
            gameOver = true
            print("You lose!")
            backgroundMusicPlayer.stop()
        
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
        //cameraNode.position = zombie.position
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
    
    override func didEvaluateActions() {
        checkCollisions()
    }
    
    //--------------------------------------------------
    // MARK: - Methods
    //--------------------------------------------------
    
    func sceneTouched(touchLocation: CGPoint) {
        moveZombieToward(location: touchLocation)
    }
    
    func move(sprite: SKSpriteNode, velocity: CGPoint) {
        //1.
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dt), y: velocity.y * CGFloat(dt))
        
        //2.
        sprite.position = CGPoint(x: sprite.position.x + amountToMove.x, y: sprite.position.y + amountToMove.y)
    }
    
    func moveZombieToward(location: CGPoint) {
        startZombieAnimation()
        let offset = CGPoint(x: location.x - zombie.position.x, y: location.y - zombie.position.y)
        let lenght = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
        let direction = CGPoint(x: offset.x / CGFloat(lenght), y: offset.y / CGFloat(lenght))
        velocity = CGPoint(x: direction.x * zombieMovePointsPerSec, y: direction.y * zombieMovePointsPerSec)
    }
    
    func boundsCheckZombie() {
        let bottomLeft = CGPoint(x: cameraRect.minX, y: cameraRect.minY)
        let topRight = CGPoint(x: cameraRect.maxX, y: cameraRect.maxY)
        
        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x
            velocity.x = abs(velocity.x)
        }
        if zombie.position.x >= topRight.x {
            zombie.position.x = topRight.x
            velocity.x = -velocity.x
        }
        if zombie.position.y <= bottomLeft.y {
            zombie.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        if zombie.position.y >= topRight.y {
            zombie.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }
    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode(rect: playableRect)
        shape.strokeColor = SKColor.black
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
    func rotateZombie(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocity.angle)
        let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
        sprite.zRotation += shortest.sign() * amountToRotate
    }
    
    func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        
        enemy.position = CGPoint(
            x: cameraRect.maxX + enemy.size.width/2,
            y: CGFloat.random(
                min: cameraRect.minY + enemy.size.height/2,
                max: cameraRect.maxY - enemy.size.height/2))
        enemy.zPosition = 50
        addChild(enemy)
        
        let actionMove = SKAction.moveBy(x: -(size.width + enemy.size.width), y: 0, duration: 2.5)
        let actionRemove = SKAction.removeFromParent()
        enemy.run(SKAction.sequence([actionMove, actionRemove]))
    }
    
    func startZombieAnimation() {
        if zombie.action(forKey: "animation") == nil {
            zombie.run(
                SKAction.repeatForever(zombieAnimation), withKey: "animation")
        }
    }
    
    func stopZombieAnimation() {
        zombie.removeAction(forKey: "animation")
    }
    
    func spawnCat() {
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        
        cat.position = CGPoint(
            x: CGFloat.random(min: cameraRect.minX, max: cameraRect.maxX),
            y: CGFloat.random(min: cameraRect.minY, max: cameraRect.maxY))
        cat.zPosition = 50
        cat.setScale(0)
        addChild(cat)
        
        let appear = SKAction.scale(to: 1.0, duration: 0.5)
        
        cat.zRotation = -π / 16.0
        let leftWiggle = SKAction.rotate(byAngle: π/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversed()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeat(group, count: 10)
        let disappear = SKAction.scale(to: 0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, groupWait, disappear, removeFromParent]
        cat.run(SKAction.sequence(actions))
    }
    
    func zombieHit(cat: SKSpriteNode) {
        run(catCollisionSound)
        cat.name = "train"
        cat.removeAllActions()
        cat.zRotation = 0
        cat.setScale(1)
        let colorAction = SKAction.colorize(with: SKColor.green, colorBlendFactor: 1.0, duration: 0.2)
        cat.run(colorAction)
    }
    
    func zombieHit(enemy: SKSpriteNode) {
        zombieIsInvincible = true
        let blinkAction = self.createBlinkAction(duration: 3.0, blinkTimes: 10)
        zombie.run(blinkAction) {
            self.zombie.isHidden = false
            self.zombieIsInvincible = false
        }
        run(enemyCollisionSound)
        loseCats()
        lives -= 1
        self.updateLivesLabel()
    }
    
    func createBlinkAction(duration: Double, blinkTimes: Double) -> SKAction {
        let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime).truncatingRemainder(dividingBy: slice)
            node.isHidden = remainder > slice / 2
        }
        return blinkAction
    }
    
    func checkCollisions() {
        var hitCats: [SKSpriteNode] = []
        enumerateChildNodes(withName: "cat") { node, _ in
            let cat = node as! SKSpriteNode
            if cat.frame.intersects(self.zombie.frame) {
                hitCats.append(cat)
            }
        }
        for cat in hitCats {
            zombieHit(cat: cat)
        }
        
        guard !zombieIsInvincible else { return }
        
        var hitEnemies: [SKSpriteNode] = []
        enumerateChildNodes(withName: "enemy") { node, _ in
            let enemy = node as! SKSpriteNode
            if node.frame.insetBy(dx: 20, dy: 20).intersects(self.zombie.frame) {
                hitEnemies.append(enemy)
            }
            for enemy in hitEnemies {
                self.zombieHit(enemy: enemy)
            }
        }
    }
    
    func moveTrain() {
        var trainCount = 0
        var targetPosition = zombie.position
        
        enumerateChildNodes(withName: "train") { node, stop in
            trainCount += 1
            if !node.hasActions() {
                let actionDuration = 0.3
                let offset = targetPosition - node.position
                let direction = offset.normalized()
                let amountToMovePerSec = direction * self.catsMovePointsPerSec
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
                let moveAction = SKAction.moveBy(x: amountToMove.x, y: amountToMove.y, duration: actionDuration)
                node.run(moveAction)
            }
            targetPosition = node.position
        }
        self.updateCatsLabel(trainCount: trainCount)
        if trainCount >= 15 && !gameOver {
            gameOver = true
            print("You win!")
            backgroundMusicPlayer.stop()
            
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func loseCats() {
        var loseCount = 0
        enumerateChildNodes(withName: "train") { node, stop in
            var randomSpot = node.position
            randomSpot.x += CGFloat.random(min: -100, max: 100)
            randomSpot.y += CGFloat.random(min: -100, max: 100)
            
            node.name = ""
            node.run(
                SKAction.sequence([SKAction.group([
                    SKAction.rotate(byAngle: π*4, duration: 1.0),
                    SKAction.move(to: randomSpot, duration: 1.0),
                    SKAction.scale(to: 0, duration: 1.0)
                    ]),
                    SKAction.removeFromParent()
                    ]))
            
                loseCount += 1
            if loseCount >= 2 {
                stop[0] = true
            }
        }
    }
    
    func backgroundNode() -> SKSpriteNode {
        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.name = "background"
        
        let background1 = SKSpriteNode(imageNamed: "background1")
        background1.anchorPoint = CGPoint.zero
        background1.position = CGPoint(x: 0, y: 0)
        backgroundNode.addChild(background1)
        
        let background2 = SKSpriteNode(imageNamed: "background2")
        background2.anchorPoint = CGPoint.zero
        background2.position = CGPoint(x: background1.size.width, y: 0)
        backgroundNode.addChild(background2)
        
        backgroundNode.size = CGSize(
            width: background1.size.width + background2.size.width,
            height: background1.size.height)
        return backgroundNode
    }
    
    func moveCamera() {
        let backgroundVelocity = CGPoint(x: cameraMovePointsPerSec, y: 0)
        let amountToMove = backgroundVelocity * CGFloat(dt)
        cameraNode.position += amountToMove
        
        enumerateChildNodes(withName: "background") { node, _ in
            let background = node as! SKSpriteNode
            if background.position.x + background.size.width < self.cameraRect.origin.x {
                background.position = CGPoint(
                    x: background.position.x + background.size.width*2,
                    y: background.position.y)
            }
        }
    }
}
