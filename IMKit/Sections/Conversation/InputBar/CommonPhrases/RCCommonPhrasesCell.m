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
        self.backgroundColor = RCDYCOLOR(0xf5f6f9, 0x1c1c1c);
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
        _commonPhrasesLable.textColor = [RCKitUtility
            generateDynamicColor:[UIColor colorWithRed:51 / 255.0 green:51 / 255.0 blue:51 / 255.0 alpha:1 / 1.0]
                       darkColor:HEXCOLOR(0x9f9f9f)];
        _commonPhrasesLable.numberOfLines = 0;
    }
    return _commonPhrasesLable;
}

@end
