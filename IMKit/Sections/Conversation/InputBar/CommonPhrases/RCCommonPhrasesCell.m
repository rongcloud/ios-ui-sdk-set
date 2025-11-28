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
#define CPLeadingEdges 16
#define CPLableHeight 44
#define CPScreenSize [UIScreen mainScreen].bounds.size

@interface RCCommonPhrasesCell ()

@property (nonatomic, strong) UILabel *commonPhrasesLable;

@end

@implementation RCCommonPhrasesCell

+ (CGFloat)heightForCommonPhrasesCell:(NSString *)text{
    return [self sizeToLabel:text].height + 26;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self.contentView addSubview:self.commonPhrasesLable];
        self.backgroundColor = RCDynamicColor(@"auxiliary_background_1_color", @"0xF5F6F9", @"0x1c1c1c");
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
    self.commonPhrasesLable.frame =
        CGRectMake(10, 13, CPScreenSize.width-20, textSize.height);
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
        _commonPhrasesLable.textAlignment = NSTextAlignmentCenter;
        UIColor *textColor = RCDynamicColor(@"text_primary_color", @"0x333333", @"0x9f9f9f");
        _commonPhrasesLable.textColor = textColor;
        _commonPhrasesLable.numberOfLines = 0;
    }
    return _commonPhrasesLable;
}

@end
