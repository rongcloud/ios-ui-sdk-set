//
//  RCStickerListCell.m
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/20.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStickerListCell.h"
#import "RCStickerUtility.h"
#import "RCStickerDataManager.h"
#import "RongStickerAdaptiveHeader.h"
#define ScreenWidth [UIScreen mainScreen].bounds.size.width

@interface RCStickerListCell ()

@property (nonatomic, strong) RCStickerPackage *package;

@property (nonatomic, strong) RCBaseImageView *headImage;

@property (nonatomic, strong) RCBaseLabel *nameLabel;

@property (nonatomic, strong) RCBaseButton *deleteBtn;

@end

@implementation RCStickerListCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = RCDynamicColor(@"common_background_color", @"0xffffff", @"0x1c1c1e66");
        [self.contentView addSubview:self.headImage];
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.deleteBtn];

        if([RCKitUtility isRTL]) {
            self.headImage.frame = CGRectMake(ScreenWidth - 40 - 15, 5, 40, 40);
            self.nameLabel.frame = CGRectMake(CGRectGetMinX(self.headImage.frame) - 200 - 15, 12.5, 200, 25);
            self.deleteBtn.frame = CGRectMake(15, 11.5, 57.5, 27);
        } else {
            self.headImage.frame = CGRectMake(15, 5, 40, 40);
            self.nameLabel.frame = CGRectMake(CGRectGetMaxX(self.headImage.frame) + 15, 12.5, 200, 25);
            self.deleteBtn.frame = CGRectMake(ScreenWidth - 57.5 - 15, 11.5, 57.5, 27);
        }
    
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    //    [super setSelected:selected animated:animated];
    //    [self setSelected:NO animated:NO];
    // Configure the view for the selected state
}

- (void)configWithModel:(RCStickerPackage *)package {
    self.package = package;
    NSData *imageData = [[RCStickerDataManager sharedManager] packageCoverById:package.packageId];
    self.headImage.image = [UIImage imageWithData:imageData];
    self.nameLabel.text = package.name;
}

- (void)deletePackage {
    if (self.delegate && [self.delegate respondsToSelector:@selector(onDeletePackage:)]) {
        [self.delegate onDeletePackage:self.package.packageId];
    }
}

- (RCBaseImageView *)headImage {
    if (_headImage == nil) {
        _headImage = [[RCBaseImageView alloc] init];
        _headImage.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _headImage;
}

- (RCBaseLabel *)nameLabel {
    if (_nameLabel == nil) {
        _nameLabel = [[RCBaseLabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:18];
        _nameLabel.textColor = RCDynamicColor(@"text_primary_color", @"0x000000", @"0x9f9f9f");
    }
    return _nameLabel;
}

- (RCBaseButton *)deleteBtn {
    if (_deleteBtn == nil) {
        _deleteBtn = [[RCBaseButton alloc] init];
        _deleteBtn.layer.borderWidth = 0.5f;
        _deleteBtn.layer.borderColor =
        RCDynamicColor(@"disabled_color", @"0xCECECE", @"0x8080804c").CGColor;
        _deleteBtn.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xF8F8F8", @"0x1a1a1a");
        _deleteBtn.layer.cornerRadius = 4.f;
        _deleteBtn.layer.masksToBounds = YES;
        _deleteBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        [_deleteBtn setTitleColor:RCDynamicColor(@"text_primary_color", @"0x333333", @"0x999999") forState:UIControlStateNormal];
        [_deleteBtn setTitle:RongStickerString(@"delete_title") forState:UIControlStateNormal];
        [_deleteBtn addTarget:self action:@selector(deletePackage) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteBtn;
}

@end
