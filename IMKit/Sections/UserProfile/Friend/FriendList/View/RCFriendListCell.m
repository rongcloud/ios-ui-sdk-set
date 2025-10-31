//
//  RCFriendListCell.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/20.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCFriendListCell.h"
#import "RCloudImageView.h"
#import "RCKitCommonDefine.h"
NSString  * const RCFriendListCellIdentifier = @"RCFriendListCellIdentifier";

@interface RCFriendListCell()
@property (nonatomic, strong) UIView *line;
@end

@implementation RCFriendListCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setupView {
    [super setupView];
    self.line = [UIView new];
    self.line.backgroundColor = RCDYCOLOR(0xE3E5E6, 0x272727);;
//    [self.contentView addSubview:self.line];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.contentView.bounds.size.width;
    CGFloat height = self.contentView.bounds.size.height;
    self.line.frame = CGRectMake(CGRectGetMaxX(self.portraitImageView.frame),
                                 height-1,
                                 width-CGRectGetMaxX(self.portraitImageView.frame),
                                 1);
}

- (void)showPortrait:(NSString *)url {
    if (url.length) {
        [self.portraitImageView setImageURL:[NSURL URLWithString:url]];
    } else {
        [self.portraitImageView setImage:RCDynamicImage(@"conversation-list_cell_portrait_msg_img",@"default_portrait_msg")];
    }
}

@end
