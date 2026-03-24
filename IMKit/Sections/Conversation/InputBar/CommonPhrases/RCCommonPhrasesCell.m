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
#define CPLableHeight 44
#define CPScreenSize [UIScreen mainScreen].bounds.size

@interface RCCommonPhrasesCell ()

@property (nonatomic, strong) UILabel *commonPhrasesLable;
@property (nonatomic, strong) UIView *containerView;
@end

@implementation RCCommonPhrasesCell

+ (CGFloat)heightForCommonPhrasesCell:(NSString *)text{
    return [self sizeToLabel:text].height + 30;
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
    self.commonPhrasesLable.text = nil;
    self.commonPhrasesLable.text = lableText;
    CGSize textSize = [RCCommonPhrasesCell sizeToLabel:lableText];
    self.commonPhrasesLable.bounds =
        CGRectMake(0, 0, CPScreenSize.width-CPLeadingEdges * 2, textSize.height);
    
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.containerView.frame = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(4, 16, 4, 16));
    self.commonPhrasesLable.frame =
        CGRectMake(CPLeadingEdges,
                   15,
                   self.commonPhrasesLable.bounds.size.width,
                   self.commonPhrasesLable.bounds.size.height);
}
+ (CGSize)sizeToLabel:(NSString *)lableText {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    attrs[NSFontAttributeName] = [UIFont systemFontOfSize:15];
    CGSize size = [lableText boundingRectWithSize:CGSizeMake(CPScreenSize.width - CPLeadingEdges * 2,8000)
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:attrs
                                          context:nil].size;
    return CGSizeMake(ceilf(size.width), ceilf(size.height));
}

- (UILabel *)commonPhrasesLable {
    if (!_commonPhrasesLable) {
        _commonPhrasesLable = [[UILabel alloc]
            initWithFrame:CGRectMake(CPLeadingEdges, 0, CPScreenSize.width - CPLeadingEdges * 2, CPLableHeight)];
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
