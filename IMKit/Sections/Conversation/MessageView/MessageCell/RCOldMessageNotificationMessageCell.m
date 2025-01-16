//
//  RCOldMessageNotificationMessageCell.m
//  RongIMKit
//
//  Created by 杜立召 on 15/8/24.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCOldMessageNotificationMessageCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCKitConfig.h"

@interface RCOldMessageNotificationMessageCell ()
@property (nonatomic, strong) UIView *leftView;
@property (nonatomic, strong) UIView *rightView;
@end

@implementation RCOldMessageNotificationMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        RCTipLabel *tip = [[RCTipLabel alloc] init];
        tip.marginInsets = UIEdgeInsetsMake(5.f, 5.f, 5.f, 5.f);
        tip.textColor = RCDYCOLOR(0xBBBBBB, 0x666666);
        tip.numberOfLines = 0;
        tip.lineBreakMode = NSLineBreakByCharWrapping;
        tip.textAlignment = NSTextAlignmentCenter;
        tip.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
        tip.layer.masksToBounds = YES;
        tip.layer.cornerRadius = 5.f;
        self.tipMessageLabel = tip;
        [self.baseContentView addSubview:self.tipMessageLabel];
        self.tipMessageLabel.marginInsets = UIEdgeInsetsMake(0.5f, 0.5f, 0.5f, 0.5f);
        self.leftView = [[UIView alloc] init];
        self.leftView.backgroundColor = RCDYCOLOR(0xBBBBBB, 0x666666);
        self.leftView.alpha = 0.5;
        [self.baseContentView addSubview:self.leftView];
        self.rightView = [[UIView alloc] init];
        self.rightView.backgroundColor = RCDYCOLOR(0xBBBBBB, 0x666666);
        self.rightView.alpha = 0.5;
        [self.baseContentView addSubview:self.rightView];
    }
    return self;
}

#pragma mark - Super Methods

+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat height = 37.f;
    return CGSizeMake(collectionViewWidth, height);
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    CGFloat maxMessageLabelWidth = [self labelWiden:self.tipMessageLabel];
    NSString *__text = RCLocalizedString(@"HistoryMessageTip");
    CGSize __textSize = [RCKitUtility getTextDrawingSize:__text
                                                    font:[[RCKitConfig defaultConfig].font fontOfAnnotationLevel]
                                         constrainedSize:CGSizeMake(maxMessageLabelWidth, MAXFLOAT)];
    __textSize = CGSizeMake(ceilf(__textSize.width), ceilf(__textSize.height));
    CGSize __labelSize = CGSizeMake(__textSize.width + 10, __textSize.height + 6);
    self.tipMessageLabel.text = __text;
    self.tipMessageLabel.frame = CGRectMake((self.baseContentView.bounds.size.width - __labelSize.width) / 2.0f, 0,
                                            __labelSize.width, __labelSize.height);

    [self.leftView setFrame:CGRectMake(10, CGRectGetMidY(self.tipMessageLabel.frame) - 0.5,
                                       CGRectGetMinX(self.tipMessageLabel.frame) - 17, 1)];

    [self.rightView
        setFrame:CGRectMake(CGRectGetMaxX(self.tipMessageLabel.frame) + 7, CGRectGetMinY(self.leftView.frame),
                            CGRectGetWidth(self.baseContentView.frame) - 7 - CGRectGetMaxX(self.tipMessageLabel.frame) -
                                10,
                            1)];
}

#pragma mark - Private Methods

- (CGFloat)labelWiden:(UILabel *)sender {
    CGRect rect = [sender.text boundingRectWithSize:CGSizeMake(2000, sender.frame.size.height)
                                            options:(NSStringDrawingUsesLineFragmentOrigin)
                                         attributes:@{
                                             NSFontAttributeName : [[RCKitConfig defaultConfig].font fontOfFourthLevel]
                                         }
                                            context:nil];
    return rect.size.width;
}

@end
