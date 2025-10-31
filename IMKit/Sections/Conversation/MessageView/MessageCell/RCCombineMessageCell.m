//
//  RCCombineMessageCell.m
//  RongIMKit
//
//  Created by liyan on 2019/8/13.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCCombineMessageCell.h"
#import "RCKitCommonDefine.h"
#import "RCCombineMessageUtility.h"
#import "RCMessageCellTool.h"
#import "RCKitConfig.h"
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
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    if([RCKitUtility isRTL]){
        paragraphStyle.alignment = NSTextAlignmentRight;
    }else{
        paragraphStyle.alignment = NSTextAlignmentLeft;
    }
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
        // 当使用 boundingRect(with:options:context:) 方法计算富文本的高度时，已经通过传递 .usesLineFragmentOrigin 选项告知文本布局引擎使用换行布局。这意味着文本将根据给定的宽度进行自动换行，而不需要显式设置 lineBreakMode。
        // paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
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
        [self.titleLabel setTextColor: RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0xffffffcc")];
        self.lineLable.backgroundColor = RCDynamicColor(@"line_background_color", @"0xe3e5e6", @"0x383838");
        self.contentLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0xa0a5ab", @"0xffffff66");
        self.historyLabel.textColor =
        RCDynamicColor(@"text_secondary_color", @"0xa0a5ab", @"0xffffffb2");
    }else{
        [self.titleLabel setTextColor:RCDynamicColor(@"text_primary_color", @"0x111f2c", @"0x040A0F")];
        self.lineLable.backgroundColor = RCDynamicColor(@"line_background_color", @"0xe3e5e6", @"0x8EC4E9");
        self.contentLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0xa0a5ab", @"0x040a0f7f");
        self.historyLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0xa0a5ab", @"0x040a0fb2");
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
- (RCBaseView *)backView {
    if (!_backView) {
        _backView = [[RCBaseView alloc] initWithFrame:CGRectZero];
        _backView.userInteractionEnabled = NO;
        _backView.backgroundColor = [UIColor clearColor];
    }
    return _backView;
}

- (RCBaseLabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[RCBaseLabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];
        _titleLabel.numberOfLines = 1;
        _titleLabel.backgroundColor = [UIColor clearColor];
    }
    return _titleLabel;
}

- (RCBaseLabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[RCBaseLabel alloc] initWithFrame:CGRectZero];
        _contentLabel.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
        _contentLabel.numberOfLines = 0;
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

- (RCBaseLabel *)historyLabel {
    if (!_historyLabel) {
        _historyLabel = [[RCBaseLabel alloc] initWithFrame:CGRectZero];
        _historyLabel.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
        _historyLabel.numberOfLines = 1;
        _historyLabel.backgroundColor = [UIColor clearColor];
        _historyLabel.text = RCLocalizedString(@"ChatHistory");
    }
    return _historyLabel;
}
@end
