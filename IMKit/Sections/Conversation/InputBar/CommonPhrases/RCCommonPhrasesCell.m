//
//  RCCommonPhrasesCell.m
//  RongExtensionKit
//
//  Created by liyan on 2019/7/9.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCCommonPhrasesCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
#define CPLeadingEdges 22

@interface RCCommonPhrasesCell ()

@property (nonatomic, strong) UILabel *commonPhrasesLable;
@property (nonatomic, strong) UIView *containerView;
@end

@implementation RCCommonPhrasesCell

+ (CGFloat)heightForCommonPhrasesCell:(NSString *)text width:(CGFloat)width {
    return [self sizeToLabel:text width:width].height + 30;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self.contentView addSubview:self.containerView];
        [self.contentView addSubview:self.commonPhrasesLable];
        self.backgroundColor = RCDynamicColor(@"common_background_color", @"0xFFFFFF", @"0x2D2D32");
    }
    return self;
}

- (void)setLableText:(NSString *)lableText {
    if (!lableText) {
        return;
    }
    self.commonPhrasesLable.text = lableText;
    [self setNeedsLayout];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = CGRectGetWidth(self.contentView.bounds);
    CGSize textSize = [RCCommonPhrasesCell sizeToLabel:self.commonPhrasesLable.text width:width];
    self.containerView.frame = UIEdgeInsetsInsetRect(self.contentView.bounds, UIEdgeInsetsMake(4, 16, 4, 16));
    self.commonPhrasesLable.frame =
        CGRectMake(CPLeadingEdges,
                   15,
                   MAX(0, width - CPLeadingEdges * 2),
                   textSize.height);
}
+ (CGSize)sizeToLabel:(NSString *)lableText width:(CGFloat)width {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    attrs[NSFontAttributeName] = [[RCKitConfig defaultConfig].font fontOfThirdLevel];
    CGSize size = [lableText boundingRectWithSize:CGSizeMake(MAX(0, width - CPLeadingEdges * 2), CGFLOAT_MAX)
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:attrs
                                          context:nil].size;
    return CGSizeMake(ceilf(size.width), ceilf(size.height));
}

- (UILabel *)commonPhrasesLable {
    if (!_commonPhrasesLable) {
        _commonPhrasesLable = [[UILabel alloc] initWithFrame:CGRectZero];
        _commonPhrasesLable.font = [[RCKitConfig defaultConfig].font fontOfThirdLevel];
        UIColor *textColor = RCDynamicColor(@"text_primary_color", @"0x333333", @"0x9f9f9f");
        _commonPhrasesLable.textColor = textColor;
        _commonPhrasesLable.numberOfLines = 0;
    }
    return _commonPhrasesLable;
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [UIView new];
        _containerView.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xE1F0FF", @"0x191A1F");
        _containerView.layer.cornerRadius = 6;
        _containerView.layer.masksToBounds = YES;
    }
    return _containerView;
}

@end
