//
//  HeadPictureAction.swift
//  myOpenGLTest
//
//  Created by sinyilin on 2020/4/30.
//  Copyright © 2020 sinyilin. All rights reserved.
//

import UIKit
class HeadPictureAction {
    private var delegation:ChangeHeadPicture!
    func setDelegate(delegate:ChangeHeadPicture)
    {
        delegation = delegate
    }
    func selectPicture()
    {
        if delegation != nil
        {
            delegation.changeHeadAction?()
        }
    }
}
