//
//  RCCombineMessageCell.m
//  RongIMKit
//
//  Created by liyan on 2019/8/13.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCCombineMessageCell.h"
#import "RCIM.h"
#import "RCKitCommonDefine.h"
#import "RCCombineMessageUtility.h"
#import "RCMessageCellTool.h"
#import "RCKitConfig.h"
#import "RCResendManager.h"
#define RCCOMBINECELLWIDTH 230.0f
#define RCCOMBINEBACKVIEWLEFT 12.0f
#define RCCOMBINETITLELABLETOP 6.0f
#define RCCOMBINETITLELABLEHEIGHT 24.0f
#define RCCOMBINECONTENTLABELTOPSPACE 4.0f
#define RCCOMBINECONTENTLABELSINGLEHEIGHT 18.5f
#define RCCOMBINELINEVIEWTOPSPACE 10.0f
#define RCCOMBINELINEVIEWHEIGHT 0.5f
#define RCCOMBINEHISTORYLABELTOPSPACE 4.0f
#define RCCOMBINEHISTORYLABELHEIGHT 16.5f
#define RCCOMBINEHISTORYLABELBOTTOMSPACE 6.0f
#define RCCOMBINECELLHEIGHTOVERCONTENTLABEL (RCCOMBINETITLELABLETOP + RCCOMBINETITLELABLEHEIGHT + RCCOMBINECONTENTLABELTOPSPACE + RCCOMBINELINEVIEWTOPSPACE + RCCOMBINELINEVIEWHEIGHT + RCCOMBINEHISTORYLABELTOPSPACE + RCCOMBINEHISTORYLABELHEIGHT + RCCOMBINEHISTORYLABELBOTTOMSPACE)
#define CONTENTLINESPACE 5
@interface RCCombineMessageCell ()

@property (nonatomic, strong) UILabel *lineLable;

@end

@implementation RCCombineMessageCell

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

- (void)prepareForReuse {
    [super prepareForReuse];
}

#pragma mark - Super Methods

+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {
    CGFloat __messagecontentview_height;
    RCCombineMessage *combineMessage = (RCCombineMessage *)model.content;
    __messagecontentview_height = [RCCombineMessageCell calculateCellHeight:combineMessage];
    if (__messagecontentview_height < RCKitConfigCenter.ui.globalMessagePortraitSize.height) {
        __messagecontentview_height = RCKitConfigCenter.ui.globalMessagePortraitSize.height;
    }
    __messagecontentview_height += extraHeight;
    return CGSizeMake(collectionViewWidth, __messagecontentview_height);
}

- (void)setDataModel:(RCMessageModel *)model {
    if (!model) {
        return;
    }
    [super setDataModel:model];
    [self resetSubViews];
    RCCombineMessage *combineMessage = (RCCombineMessage *)model.content;
    [self calculateContenViewSize:combineMessage];
    NSString *title = [RCCombineMessageUtility getCombineMessageSummaryTitle:combineMessage];
    self.titleLabel.text = title;
    NSString *summaryContent = [RCCombineMessageUtility getCombineMessageSummaryContent:combineMessage];
    NSMutableAttributedString *attriString =
    [[NSMutableAttributedString alloc] initWithString:summaryContent];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:CONTENTLINESPACE];//设置行间距
    paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
    [attriString addAttribute:NSParagraphStyleAttributeName
                        value:paragraphStyle
                        range:NSMakeRange(0, [summaryContent length])];
    self.contentLabel.attributedText = attriString;
    [self updateStatusContentView:self.model];
    [self setDestructViewLayout];
}

#pragma mark - Private Methods

+ (CGFloat)calculateCellHeight:(RCCombineMessage *)combineMessage {
    CGFloat height = RCCOMBINECELLHEIGHTOVERCONTENTLABEL;
    NSString *summary = [RCCombineMessageUtility getCombineMessageSummaryContent:combineMessage];
    CGSize size = [self getTextDrawingSize:summary
                                      font:[[RCKitConfig defaultConfig].font fontOfAnnotationLevel]
                           constrainedSize:CGSizeMake(RCCOMBINECELLWIDTH - 25, 9999) lineSpace:CONTENTLINESPACE];
    height += ceilf(size.height);
    if (height > RCCOMBINECELLHEIGHTOVERCONTENTLABEL + RCCOMBINECONTENTLABELSINGLEHEIGHT * 4) {
        height = RCCOMBINECELLHEIGHTOVERCONTENTLABEL + RCCOMBINECONTENTLABELSINGLEHEIGHT * 4;
    }
    return height;
}

+ (CGSize)getTextDrawingSize:(NSString *)text font:(UIFont *)font constrainedSize:(CGSize)constrainedSize lineSpace:(NSInteger)lineSpace{
    if (text.length <= 0) {
        return CGSizeZero;
    }

    if ([text respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        paragraphStyle.lineSpacing = lineSpace;
        NSDictionary *attributes = @{NSFontAttributeName : font, NSParagraphStyleAttributeName : paragraphStyle};

        return [text boundingRectWithSize:constrainedSize
                                  options:(NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                               attributes:attributes
                                  context:nil].size;
    }
    return CGSizeZero;
}


- (void)initialize {
    [self showBubbleBackgroundView:YES];
    [self.messageContentView addSubview:self.backView];
    [self.backView addSubview:self.titleLabel];
    [self.backView addSubview:self.contentLabel];
    [self.backView addSubview:self.lineLable];
    [self.backView addSubview:self.historyLabel];
}

- (void)resetSubViews {
    self.titleLabel.text = nil;
    self.contentLabel.text = nil;
}

- (void)calculateContenViewSize:(RCCombineMessage *)combineMessage {
    CGFloat messageContentViewHeight = [RCCombineMessageCell calculateCellHeight:combineMessage];
    self.messageContentView.contentSize = CGSizeMake(RCCOMBINECELLWIDTH, messageContentViewHeight);
    [self autoLayoutSubViews];
}

- (void)autoLayoutSubViews {
    if(self.model.messageDirection == MessageDirection_RECEIVE){
        [self.titleLabel setTextColor:[RCKitUtility generateDynamicColor:HEXCOLOR(0x111f2c) darkColor:RCMASKCOLOR(0xffffff, 0.8)]];
        self.lineLable.backgroundColor = RCDYCOLOR(0xe3e5e6,0x383838);
        self.contentLabel.textColor =
            [RCKitUtility generateDynamicColor:HEXCOLOR(0xa0a5ab) darkColor:RCMASKCOLOR(0xffffff, 0.4)];
        self.historyLabel.textColor =
            [RCKitUtility generateDynamicColor:HEXCOLOR(0xa0a5ab) darkColor:RCMASKCOLOR(0xffffff, 0.7)];
    }else{
        [self.titleLabel setTextColor:RCDYCOLOR(0x111f2c, 0x040A0F)];
        self.lineLable.backgroundColor = RCDYCOLOR(0xe3e5e6,0x8EC4E9);
        self.contentLabel.textColor =
            [RCKitUtility generateDynamicColor:HEXCOLOR(0xa0a5ab) darkColor:RCMASKCOLOR(0x040a0f, 0.5)];
        self.historyLabel.textColor =
            [RCKitUtility generateDynamicColor:HEXCOLOR(0xa0a5ab) darkColor:RCMASKCOLOR(0x040a0f, 0.7)];
    }
    self.backView.frame = CGRectMake(RCCOMBINEBACKVIEWLEFT, 0,
                                     self.messageContentView.frame.size.width - RCCOMBINEBACKVIEWLEFT * 2,
                                     self.messageContentView.frame.size.height);
    self.titleLabel.frame = CGRectMake(0, RCCOMBINETITLELABLETOP, self.backView.frame.size.width, RCCOMBINETITLELABLEHEIGHT);
    self.contentLabel.frame = CGRectMake(0, CGRectGetMaxY(self.titleLabel.frame)+RCCOMBINECONTENTLABELTOPSPACE, self.backView.frame.size.width, self.messageContentView.frame.size.height - RCCOMBINECELLHEIGHTOVERCONTENTLABEL);
    self.lineLable.frame = CGRectMake(0, CGRectGetMaxY(self.contentLabel.frame) + RCCOMBINELINEVIEWTOPSPACE, self.backView.frame.size.width, RCCOMBINELINEVIEWHEIGHT);
    self.historyLabel.frame = CGRectMake(0, CGRectGetMaxY(self.lineLable.frame) + RCCOMBINEHISTORYLABELTOPSPACE, self.backView.frame.size.width, RCCOMBINEHISTORYLABELHEIGHT);
}

- (void)longPressed:(id)sender {
    UILongPressGestureRecognizer *press = (UILongPressGestureRecognizer *)sender;
    if (press.state == UIGestureRecognizerStateEnded) {
        DebugLog(@"long press end");
        return;
    } else if (press.state == UIGestureRecognizerStateBegan) {
        if ([self.delegate respondsToSelector:@selector(didLongTouchMessageCell:inView:)]) {
            [self.delegate didLongTouchMessageCell:self.model inView:self.backView];
        }
    }
}

#pragma mark - Getters and Setters
- (UIView *)backView {
    if (!_backView) {
        _backView = [[UIView alloc] initWithFrame:CGRectZero];
        _backView.userInteractionEnabled = NO;
        _backView.backgroundColor = [UIColor clearColor];
    }
    return _backView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
        _titleLabel.numberOfLines = 1;
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.backgroundColor = [UIColor clearColor];
    }
    return _titleLabel;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _contentLabel.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
        _contentLabel.numberOfLines = 0;
        _contentLabel.textAlignment = NSTextAlignmentLeft;
        [_contentLabel sizeToFit];
        _contentLabel.backgroundColor = [UIColor clearColor];
    }
    return _contentLabel;
}

- (UILabel *)lineLable {
    if (!_lineLable) {
        _lineLable = [[UILabel alloc] initWithFrame:CGRectZero];
    }
    return _lineLable;
}

- (UILabel *)historyLabel {
    if (!_historyLabel) {
        _historyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _historyLabel.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
        _historyLabel.numberOfLines = 1;
        _historyLabel.textAlignment = NSTextAlignmentLeft;
        _historyLabel.backgroundColor = [UIColor clearColor];
        _historyLabel.text = RCLocalizedString(@"ChatHistory");
    }
    return _historyLabel;
}
@end
