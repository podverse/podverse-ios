//
//  Data+ResizeImageData.swift
//  Podverse
//
//  Created by Creon on 12/24/16.
//  Copyright © 2016 Podverse LLC. All rights reserved.
//

import Foundation
import UIKit

extension Data {
    func resizeImageData() -> Data? {
        guard let image = UIImage(data: self) else {
            return nil
        }
        
        var actualHeight: CGFloat = image.size.height
        var actualWidth: CGFloat = image.size.width
        let maxHeight: CGFloat = 400.0
        let maxWidth: CGFloat = 400.0
        var imgRatio: CGFloat = actualWidth / actualHeight
        let maxRatio: CGFloat = maxWidth / maxHeight
        //Half the compression
        let compressionQuality: CGFloat = 0.5
        if actualHeight > maxHeight || actualWidth > maxWidth {
            if imgRatio < maxRatio {
                //adjust width according to maxHeight
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            }
            else if imgRatio > maxRatio {
                //adjust height according to maxWidth
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            }
            else {
                actualHeight = maxHeight
                actualWidth = maxWidth
            }
        }
        let rect: CGRect = CGRect(x:0.0, y:0.0, width:actualWidth, height:actualHeight)
        UIGraphicsBeginImageContext(rect.size)
        
        defer {
            UIGraphicsEndImageContext()
        }
        
        image.draw(in: rect)
        if let img: UIImage = UIGraphicsGetImageFromCurrentImageContext(), let data = UIImageJPEGRepresentation(img, compressionQuality)  {
            return data
        }
        else {
            return nil
        }
    }
}
