//
//  RCCSLeaveMsgCell.m
//  RongIMKit
//
//  Created by 张改红 on 2016/12/7.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCCSPullLeaveMessageCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCKitConfig.h"
@interface RCCSPullLeaveMessageCell () <RCAttributedLabelDelegate>
@end

@implementation RCCSPullLeaveMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.baseContentView addSubview:self.contentLabel];
    }
    return self;
}

#pragma mark - Super Methods

+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat height = [self getTextLabelSize:model].height;
    height += extraHeight;
    return CGSizeMake(collectionViewWidth, height);
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
   
    CGSize labelSize = [RCCSPullLeaveMessageCell getTextLabelSize:self.model];
    self.contentLabel.frame = CGRectMake((self.baseContentView.bounds.size.width - labelSize.width) / 2.0f - 5, 0, labelSize.width , labelSize.height);
    NSString *text = [RCKitUtility formatMessage:model.content];
    NSTextCheckingResult *textCheckingResult = [NSTextCheckingResult linkCheckingResultWithRange:[text rangeOfString:@"留言"] URL:[NSURL URLWithString:@""]];
    self.contentLabel.text = text;
    [self.contentLabel.attributedStrings addObject:textCheckingResult];
    [self.contentLabel setTextHighlighted:YES atPoint:CGPointMake(0, 3)];
}

#pragma mark - RCAttributedLabelDelegate

- (void)attributedLabel:(RCAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
        [self.delegate didTapMessageCell:self.model];
    }
}

#pragma mark - Private Methods
+ (CGSize)getTextLabelSize:(RCMessageModel *)model{
    RCMessageContent *notification = model.content;
    NSString *localizedMessage = [RCKitUtility formatMessage:notification];
    CGFloat maxMessageLabelWidth = SCREEN_WIDTH - 30 * 2;
    CGSize textSize = [RCKitUtility getTextDrawingSize:localizedMessage
                                                  font:[[RCKitConfig defaultConfig].font fontOfFourthLevel]
                                       constrainedSize:CGSizeMake(maxMessageLabelWidth, MAXFLOAT)];
    textSize = CGSizeMake(ceilf(textSize.width), ceilf(textSize.height));
    CGSize labelSize = CGSizeMake(textSize.width + 10, textSize.height + 6);
    return labelSize;
}

#pragma mark - Getter
- (RCAttributedLabel *)contentLabel{
    if(!_contentLabel){
        _contentLabel = [[RCAttributedLabel alloc] init];
        _contentLabel.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
        _contentLabel.numberOfLines = 0;
        _contentLabel.lineBreakMode = NSLineBreakByCharWrapping;
        _contentLabel.textAlignment = NSTextAlignmentCenter;
        _contentLabel.textColor = RCDYCOLOR(0xffffff, 0x707070);
        _contentLabel.layer.masksToBounds = YES;
        _contentLabel.layer.cornerRadius = 5.f;
        _contentLabel.backgroundColor = RCDYCOLOR(0xc9c9c9, 0x232323);
        _contentLabel.delegate = self;
        _contentLabel.userInteractionEnabled = YES;
    }
    return _contentLabel;
}
@end
