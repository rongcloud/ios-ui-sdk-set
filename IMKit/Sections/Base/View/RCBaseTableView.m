//
//  RCBaseTableView.m
//  RongIMKit
//
//  Created by zgh on 2023/1/31.
//  Copyright © 2023 RongCloud. All rights reserved.
//

#import "RCBaseTableView.h"
#import "RCSemanticContext.h"

@implementation RCBaseTableView
- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style{
    self = [super initWithFrame:frame style:style];
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
