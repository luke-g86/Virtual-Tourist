//
//  CollectionViewFlow.swift
//  Udacity-virtual-tourist
//
//  Created by Łukasz Gajewski on 26/7/19.
//  Copyright © 2019 Lukasz. All rights reserved.
//

import Foundation
import UIKit

class CollectionViewFlow: UICollectionViewFlowLayout {
    
    private var firstSetupDone = false
    override func prepare() {
        super.prepare()
        if !firstSetupDone {
            setup()
            firstSetupDone = true
        }
    }
    private func setup() {
        scrollDirection = .vertical
        minimumInteritemSpacing = 1
        minimumLineSpacing = 4
        
        let width = (UIScreen.main.bounds.width - 32) / 3
        
        itemSize = CGSize(width: width, height: width)
        

    }
    

    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {

        let layoutAttributes = layoutAttributesForElements(in: collectionView!.bounds)
        let centerOffset = collectionView!.bounds.size.height / 2
        let offsetWithCenter = proposedContentOffset.y + centerOffset

        let closesAttribute = layoutAttributes!
            .sorted { abs($0.center.y - offsetWithCenter) < abs($1.center.y - offsetWithCenter)}
            .first ?? UICollectionViewLayoutAttributes()

        return CGPoint(x: 0, y: closesAttribute.center.y - centerOffset)
    }

}
    

