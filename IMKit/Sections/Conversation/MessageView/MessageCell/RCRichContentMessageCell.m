//
//  RCRichContentMessageCell.m
//  RongIMKit
//
//  Created by xugang on 15/2/2.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCRichContentMessageCell.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCloudImageView.h"
#import "RCMessageCellTool.h"
#import "RCKitConfig.h"

#define RICH_CONTENT_TITLE_PADDING_TOP 10.5
#define RICH_CONTENT_TITLE_CONTENT_PADDING 7.5
#define RICH_CONTENT_PADDING_LEFT 12
#define RICH_CONTENT_PADDING_RIGHT 19.5
#define RICH_CONTENT_PADDING_BOTTOM 12
#define RICH_CONTENT_THUMBNAIL_CONTENT_PADDING 6
#define RICH_CONTENT_THUMBNAIL_WIDTH 45
#define RICH_CONTENT_THUMBNAIL_HIGHT 45
#define RICH_TITLE_MAX_HEIGHT 36
@implementation RCRichContentMessageCell

#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }

    return self;
}

#pragma mark - Super Methods

+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat __messagecontentview_height = [self getMessageContentHeight:model];

    if (__messagecontentview_height < RCKitConfigCenter.ui.globalMessagePortraitSize.height) {
        __messagecontentview_height = RCKitConfigCenter.ui.globalMessagePortraitSize.height;
    }

    __messagecontentview_height += extraHeight;

    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    RCRichContentMessage *richContentMsg = (RCRichContentMessage *)model.content;
    self.titleLabel.text = richContentMsg.title;
    self.digestLabel.text = richContentMsg.digest;
    [self.richContentImageView setImageURL:[NSURL URLWithString:richContentMsg.imageURL]];
    
    CGSize titleLabelSize = [RCRichContentMessageCell getTitleContentSize:model];
    CGSize digestLabelSize = [self getDigestContentSize:model];
    self.messageContentView.contentSize = CGSizeMake([RCMessageCellTool getMessageContentViewMaxWidth], [RCRichContentMessageCell getMessageContentHeight:model]);
    self.titleLabel.frame = CGRectMake(RICH_CONTENT_PADDING_LEFT , RICH_CONTENT_TITLE_PADDING_TOP, self.messageContentView.frame.size.width - RICH_CONTENT_PADDING_LEFT - RICH_CONTENT_PADDING_RIGHT, titleLabelSize.height);
    self.digestLabel.frame = CGRectMake( RICH_CONTENT_PADDING_LEFT, CGRectGetMaxY(self.titleLabel.frame) + RICH_CONTENT_TITLE_CONTENT_PADDING, [RCMessageCellTool getMessageContentViewMaxWidth] - 6 - RICH_CONTENT_PADDING_LEFT - RICH_CONTENT_PADDING_RIGHT - RICH_CONTENT_THUMBNAIL_WIDTH - RICH_CONTENT_THUMBNAIL_CONTENT_PADDING, digestLabelSize.height);
    self.richContentImageView.frame = CGRectMake(self.messageContentView.frame.size.width - 12.5 - 45, CGRectGetMinY(self.digestLabel.frame) - 2,RICH_CONTENT_THUMBNAIL_WIDTH,RICH_CONTENT_THUMBNAIL_HIGHT);
    if(self.model.messageDirection == MessageDirection_RECEIVE){
        [self.titleLabel setTextColor:[RCKitUtility generateDynamicColor:HEXCOLOR(0x262626) darkColor:RCMASKCOLOR(0xffffff, 0.8)]];
        self.digestLabel.textColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0x888888) darkColor:RCMASKCOLOR(0xffffff, 0.4)];
    }else{
        [self.titleLabel setTextColor:RCDYCOLOR(0x262626, 0x040A0F)];
        self.digestLabel.textColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0x888888) darkColor:RCMASKCOLOR(0x040A0F, 0.4)];
    }
}

- (void)didTapMessageContentView{
    RCRichContentMessage *richContentMsg = (RCRichContentMessage *)self.model.content;
    DebugLog(@"%s, URL > %@", __FUNCTION__, richContentMsg.imageURL);
    if (nil != richContentMsg.url) {
        if ([self.delegate respondsToSelector:@selector(didTapUrlInMessageCell:model:)]) {
            [self.delegate didTapUrlInMessageCell:richContentMsg.url model:self.model];
        }
    } else if (nil != richContentMsg.imageURL) {
        if ([self.delegate respondsToSelector:@selector(didTapUrlInMessageCell:model:)]) {
            [self.delegate didTapUrlInMessageCell:richContentMsg.imageURL model:self.model];
        }
    }else{
        [super didTapMessageContentView];
    }
}

#pragma mark - Private Methods
+ (CGFloat)getMessageContentHeight:(RCMessageModel *)model{
    CGFloat messageContentViewHeight = RICH_CONTENT_TITLE_PADDING_TOP + [self getTitleContentSize:model].height +
    RICH_CONTENT_TITLE_CONTENT_PADDING + RICH_CONTENT_THUMBNAIL_HIGHT +
    RICH_CONTENT_PADDING_BOTTOM - 3;
    return messageContentViewHeight;
}

+ (CGSize)getTitleContentSize:(RCMessageModel *)model{
    RCRichContentMessage *richContentMsg = (RCRichContentMessage *)model.content;
    CGSize titleLabelSize = [RCKitUtility getTextDrawingSize:richContentMsg.title
                                    font:[[RCKitConfig defaultConfig].font fontOfFourthLevel]
                         constrainedSize:CGSizeMake([RCMessageCellTool getMessageContentViewMaxWidth] - RICH_CONTENT_PADDING_LEFT - RICH_CONTENT_PADDING_RIGHT, MAXFLOAT)];
    if (titleLabelSize.height > RICH_CONTENT_THUMBNAIL_HIGHT) {
        titleLabelSize.height = RICH_CONTENT_THUMBNAIL_HIGHT;
    }
    return titleLabelSize;
}

- (CGSize)getDigestContentSize:(RCMessageModel *)model{
    RCRichContentMessage *richContentMsg = (RCRichContentMessage *)model.content;
    CGSize digestLabelSize = [RCKitUtility getTextDrawingSize:richContentMsg.digest
                      font:[[RCKitConfig defaultConfig].font fontOfAnnotationLevel]
           constrainedSize:CGSizeMake([RCMessageCellTool getMessageContentViewMaxWidth] - RICH_CONTENT_THUMBNAIL_WIDTH -
                                          RICH_CONTENT_PADDING_LEFT - 6 - RICH_CONTENT_THUMBNAIL_CONTENT_PADDING -
                                          RICH_CONTENT_PADDING_RIGHT, MAXFLOAT)];
    if (digestLabelSize.height > RICH_CONTENT_THUMBNAIL_HIGHT) {
        digestLabelSize.height = RICH_CONTENT_THUMBNAIL_HIGHT;
    }
    return digestLabelSize;
}

- (void)initialize {
    [self showBubbleBackgroundView:YES];
    [self.messageContentView addSubview:self.titleLabel];
    [self.messageContentView addSubview:self.richContentImageView];
    [self.messageContentView addSubview:self.digestLabel];
}


#pragma mark - Getter
- (RCloudImageView *)richContentImageView{
    if (!_richContentImageView) {
        _richContentImageView = [[RCloudImageView alloc] initWithPlaceholderImage:RCResourceImage(@"rc_richcontentmsg_placeholder")];
        _richContentImageView.layer.cornerRadius = 5.0f;
        _richContentImageView.layer.masksToBounds = YES;
        _richContentImageView.contentMode = UIViewContentModeScaleAspectFill;
        _richContentImageView.frame = CGRectMake(0, 0, RICH_CONTENT_THUMBNAIL_WIDTH, RICH_CONTENT_THUMBNAIL_HIGHT);
    }
    return _richContentImageView;
}

- (RCAttributedLabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[RCAttributedLabel alloc] init];
        [_titleLabel setFont:[[RCKitConfig defaultConfig].font fontOfFourthLevel]];
        [_titleLabel setNumberOfLines:2];
    }
    return _titleLabel;
}

- (RCAttributedLabel *)digestLabel{
    if (!_digestLabel) {
        _digestLabel = [[RCAttributedLabel alloc] init];
        [_digestLabel setFont:[[RCKitConfig defaultConfig].font fontOfAnnotationLevel]];
        [_digestLabel setNumberOfLines:3];
    }
    return _digestLabel;
}
@end
