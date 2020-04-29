//
//  CIColorInvert.swift
//  myOpenGLTest
//
//  Created by sinyilin on 2020/4/28.
//  Copyright © 2020 sinyilin. All rights reserved.
//

import UIKit

class CIColorInvert:CIFilter{
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var inputImage: CIImage!
    override var outputImage:  CIImage! {
        get {
            return CIFilter(name: "CIColorMatrix" ,parameters: [
                kCIInputImageKey : inputImage ,
                "inputRVector" : CIVector (x: -1 , y:  0 , z:  0 ),
                "inputGVector" : CIVector (x:  0 , y: -1 , z:  0 ),
                "inputBVector" : CIVector (x:  0 , y:  0 , z: -1 ),
                "inputBiasVector" : CIVector (x:  1 , y:  1 , z:  1 ),
                ])?.outputImage
        }
    }
}
