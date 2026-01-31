//
//  blinkTrainingViewController.swift
//  Lucid
//
//  Created by Abhinav Barthwal on 1/31/26.
//

import UIKit
import ARKit
import SceneKit
class blinkTrainingViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var leftEyeLabel: UILabel!

    @IBOutlet var rightEyeLabel: UILabel!
    
    
    @IBOutlet var sceneView: ARSCNView!

    

        // Blink detection state
        private var leftBlinkCount: Int = 0
        private var rightBlinkCount: Int = 0
        private var isLeftEyeClosed: Bool = false
        private var isRightEyeClosed: Bool = false

        // Tunable threshold for deciding if an eye is considered closed (0.0 - 1.0)
        private let blinkThreshold: Float = 0.6



        override func viewDidLoad() {
            super.viewDidLoad()
            leftEyeLabel.text = "left eye blink = 0"
            sceneView.delegate = self
            sceneView.automaticallyUpdatesLighting = true
            rightEyeLabel.text = "right eye blink = 0"


            // Ensure device supports face tracking
            guard ARFaceTrackingConfiguration.isSupported else {
                print("ARFaceTracking is not supported on this device.")
                return
            }

            let configuration = ARFaceTrackingConfiguration()
            configuration.isLightEstimationEnabled = true
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
    override func viewDidDisappear(_ animated: Bool) {
        leftBlinkCount = 0
        rightBlinkCount = 0
        isLeftEyeClosed = false
        isRightEyeClosed = false
        DispatchQueue.main.async { [weak self] in
            self?.leftEyeLabel.text = "0"
            self?.rightEyeLabel.text = "0"
        }
        super.viewDidDisappear(animated)
    }
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            guard ARFaceTrackingConfiguration.isSupported else { return }
            let configuration = ARFaceTrackingConfiguration()
            configuration.isLightEstimationEnabled = true
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            sceneView.session.pause()
        }

        // MARK: - ARSCNViewDelegate
        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let faceAnchor = anchor as? ARFaceAnchor else { return }

            // Extract blink values (0.0 open -> 1.0 closed)
            let left = (faceAnchor.blendShapes[.eyeBlinkLeft] as? NSNumber)?.floatValue ?? 0.0
            let right = (faceAnchor.blendShapes[.eyeBlinkRight] as? NSNumber)?.floatValue ?? 0.0

            // Determine closed/open state based on threshold
            let leftClosedNow = left > blinkThreshold
            let rightClosedNow = right > blinkThreshold

            // Edge detection: count when an eye goes from open -> closed -> open
            // We'll increment on the transition from closed to open (blink completed)
            if isLeftEyeClosed && !leftClosedNow {
                leftBlinkCount += 1
                DispatchQueue.main.async { [weak self] in
                    // Changed "Right" to "Left"
                    self?.leftEyeLabel.text = "Left eye blink = \(self?.leftBlinkCount ?? 0)"
                }
            }
            if isRightEyeClosed && !rightClosedNow {
                rightBlinkCount += 1
                DispatchQueue.main.async { [weak self] in
                    // Changed "Left" to "Right"
                    self?.rightEyeLabel.text = "Right eye blink = \(self?.rightBlinkCount ?? 0)"
                }
            }

            // Update the current closed state for next frame
            isLeftEyeClosed = leftClosedNow
            isRightEyeClosed = rightClosedNow
        }

        deinit {
            sceneView?.session.pause()
        }
        

        /*
        // MARK: - Navigation

        // In a storyboard-based application, you will often want to do a little preparation before navigation
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            // Get the new view controller using segue.destination.
            // Pass the selected object to the new view controller.
        }
        */

    }

