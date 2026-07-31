//
//  RCBaseTableViewCell.m
//  RongIMKit
//
//  Created by zgh on 2023/1/31.
//  Copyright © 2023 RongCloud. All rights reserved.
//

#import "RCBaseTableViewCell.h"

@implementation RCBaseTableViewCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self){
        [self setupView];
        [self setupConstraints];
    }
    return self;
}

- (void)setupView {
    
}

- (void)setupConstraints {
    
}

@end
