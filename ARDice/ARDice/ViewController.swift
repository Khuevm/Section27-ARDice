//
//  ViewController.swift
//  ARDice
//
//  Created by Khue on 28/02/2024.
//

import ARKit
import SceneKit
import UIKit

class ViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet var sceneView: ARSCNView!
    
    private var dices: [SCNNode] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        sceneView.debugOptions = .showFeaturePoints
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard  let touch = touches.first else { return }
        
        let touchLocation = touch.location(in: sceneView)
        let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        if let hitTest = results.first {
            let diceScence = SCNScene(named: "art.scnassets/diceCollada.scn")!
            // recursively = true để bảo gồm tất cả những childNode trong Dice
            if let diceNode = diceScence.rootNode.childNode(withName: "Dice", recursively: true) {
                // boundingSphere: mặt cầu ngoại tiếp object
                diceNode.position = SCNVector3(hitTest.worldTransform.columns.3.x,
                                               hitTest.worldTransform.columns.3.y + diceNode.boundingSphere.radius,
                                               hitTest.worldTransform.columns.3.z)
                
                sceneView.scene.rootNode.addChildNode(diceNode)
                dices.append(diceNode)
                roll(dice: diceNode)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // Roll all when shake
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            rollAll()
        }
    }
    
    @IBAction func rollAllButtonTap(_ sender: Any) {
        rollAll()
    }
    
    @IBAction func clearButtonTap(_ sender: Any) {
        for dice in dices {
            dice.removeFromParentNode()
        }
    }
    
    private func rollAll() {
        for dice in dices {
            roll(dice: dice)
        }
    }
    
    private func roll(dice: SCNNode) {
        let randomX = Float(Int.random(in: 0..<4)) * Float.pi / 2
        let randomZ = Float(Int.random(in: 0..<4)) * Float.pi / 2
        
        dice.runAction(
            SCNAction.rotateBy(x: CGFloat(randomX * 5),
                               y: 0,
                               z: CGFloat(randomZ * 5),
                               duration: 0.5)
        )
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let plane = SCNPlane(width: CGFloat(planeAnchor.planeExtent.width), height: CGFloat(planeAnchor.planeExtent.height))
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
        
        plane.materials = [gridMaterial]
        node.addChildNode(planeNode)
    }
}
