//
//  RCPublicServiceSearchHintCell.m
//  RongIMKit
//
//  Created by litao on 15/4/21.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCPublicServiceSearchHintCell.h"
#import "RCSearchItemView.h"

@interface RCPublicServiceSearchHintCell ()
@property (nonatomic, strong) RCSearchItemView *item;
@end

@implementation RCPublicServiceSearchHintCell

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.item = [[RCSearchItemView alloc] initWithFrame:self.bounds];
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setSearchKey:(NSString *)key {
    if (key) {
        [self.item setKeyContent:key];
    }
}
@end
