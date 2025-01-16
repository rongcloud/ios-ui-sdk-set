//
//  RCBaseCollectionView.m
//  RongIMKit
//
//  Created by zgh on 2023/2/1.
//  Copyright © 2023 RongCloud. All rights reserved.
//

#import "RCBaseCollectionView.h"
#import "RCSemanticContext.h"
@implementation RCBaseCollectionView
- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout{
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if(self){
        if ([RCSemanticContext isRTL]) {
            self.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        }else{
            self.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }
    }
    return self;
}


@end
