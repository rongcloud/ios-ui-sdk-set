//
//  RCStreamMessageTextCellViewModel.m
//  RongIMKit
//
//  Created by zgh on 2025/3/5.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCStreamTextContentViewModel.h"
#import "RCStreamMessageCellViewModel+internal.h"
#import "RCKitConfig.h"
#import "RCMessageCellTool.h"
#import "RCMMMarkdown.h"
#import "RCKitCommonDefine.h"
#import "RCStreamTextContentView.h"
@interface RCStreamTextContentViewModel ()

@property (nonatomic, copy) NSAttributedString *attributedContent;

@end

@implementation RCStreamTextContentViewModel

#pragma mark -- RCStreamViewModelProtocol

- (CGSize)calculateContentSize {
    self.contentSize = [self coreText];
    return self.contentSize;
}

- (void)streamContentDidUpdate:(nonnull NSString *)content {
    if ([self.content isEqualToString:content]) {
        return;
    }
    self.content = content;
    self.attributedContent = [self coverAttributedContent];
    if ([self.delegate respondsToSelector:@selector(streamContentLayoutWillUpdate)]) {
        [self.delegate streamContentLayoutWillUpdate];
    }
}

- (RCStreamContentView *)streamContentView{
    return [RCStreamTextContentView new];
}

#pragma mark -- private

- (CGSize)coreText {
    CGFloat maxWidth = [self contentMaxWidth];
    CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX); // 最大高度为无限大
    
    // 使用 boundingRectWithSize 计算所需的高度
    CGRect textRect = [self.attributedContent boundingRectWithSize:maxSize
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                   context:nil];
    return CGSizeMake(maxWidth, ceilf(textRect.size.height));
}

- (NSAttributedString *)coverAttributedContent {
    NSString *content = self.content;
    if (!content) {
        return nil;
    }
    UIColor *color = RCDynamicColor(@"text_primary_color", @"0x262626", @"0xffffffcc");
    if (!color) {
        color = [RCKitUtility generateDynamicColor:HEXCOLOR(0x262626) darkColor:RCMASKCOLOR(0xffffff, 0.8)];
    }
    NSAttributedString *attributedStr =
    [[NSAttributedString alloc] initWithString:self.content
                                    attributes:@{NSFontAttributeName: [[RCKitConfig defaultConfig].font fontOfSecondLevel],
                                                 NSForegroundColorAttributeName: color}];
    return attributedStr;
}

@end
