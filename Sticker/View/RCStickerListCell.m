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

@property (nonatomic, strong) UIImageView *headImage;

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) UIButton *deleteBtn;

@end

@implementation RCStickerListCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                        darkColor:[HEXCOLOR(0x1c1c1e) colorWithAlphaComponent:0.4]];
        [self.contentView addSubview:self.headImage];
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.deleteBtn];

        self.headImage.frame = CGRectMake(15, 5, 40, 40);
        self.nameLabel.frame = CGRectMake(CGRectGetMaxX(self.headImage.frame) + 15, 12.5, 200, 25);
        self.deleteBtn.frame = CGRectMake(ScreenWidth - 57.5 - 15, 11.5, 57.5, 27);
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

- (UIImageView *)headImage {
    if (_headImage == nil) {
        _headImage = [[UIImageView alloc] init];
        _headImage.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _headImage;
}

- (UILabel *)nameLabel {
    if (_nameLabel == nil) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:18];
        _nameLabel.textColor = RCDYCOLOR(0x000000, 0x9f9f9f);
        _nameLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _nameLabel;
}

- (UIButton *)deleteBtn {
    if (_deleteBtn == nil) {
        _deleteBtn = [[UIButton alloc] init];
        _deleteBtn.layer.borderWidth = 0.5f;
        _deleteBtn.layer.borderColor =
            [RCKitUtility generateDynamicColor:HEXCOLOR(0xCECECE)
                                     darkColor:[HEXCOLOR(0x808080) colorWithAlphaComponent:0.3]]
                .CGColor;
        _deleteBtn.backgroundColor = RCDYCOLOR(0xF8F8F8, 0x1a1a1a);
        _deleteBtn.layer.cornerRadius = 4.f;
        _deleteBtn.layer.masksToBounds = YES;
        _deleteBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        [_deleteBtn setTitleColor:RCDYCOLOR(0x333333, 0x999999) forState:UIControlStateNormal];
        [_deleteBtn setTitle:RongStickerString(@"delete_title") forState:UIControlStateNormal];
        [_deleteBtn addTarget:self action:@selector(deletePackage) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteBtn;
}

@end
