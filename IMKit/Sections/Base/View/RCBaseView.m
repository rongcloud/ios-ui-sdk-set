//
//  RCBaseView.m
//  RongIMKit
//
//  Created by zgh on 2023/1/31.
//  Copyright © 2023 RongCloud. All rights reserved.
//

#import "RCBaseView.h"
#import "RCSemanticContext.h"
@implementation RCBaseView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self updateRTLUI];
    }
    return self;
}

- (instancetype)init{
    self = [super init];
    if(self){
        [self updateRTLUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    if(self){
        [self updateRTLUI];
    }
    return self;
}

- (void)updateRTLUI{
    if ([RCSemanticContext isRTL]) {
        self.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    }else{
        self.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    }
}
@end
