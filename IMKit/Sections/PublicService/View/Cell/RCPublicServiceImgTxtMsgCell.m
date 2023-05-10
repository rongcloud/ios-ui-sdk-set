//
//  RCPublicServiceImgTxtMsgCell.m
//  RongIMKit
//
//  Created by litao on 15/4/15.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCPublicServiceImgTxtMsgCell.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCPublicServiceViewConstants.h"
#import "RCloudImageView.h"
#import "RCKitConfig.h"
#import <RongPublicService/RongPublicService.h>
@interface RCPublicServiceImgTxtMsgCell ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) RCloudImageView *imageView;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UILabel *readallLabel;
@property (nonatomic, strong) UIView *container;
@property (nonatomic, strong) UIView *line;
@property (nonatomic, strong) UIImageView *arrow;
@end

@implementation RCPublicServiceImgTxtMsgCell
+ (CGSize)sizeForMessageModel:(RCMessageModel *)model
      withCollectionViewWidth:(CGFloat)collectionViewWidth
         referenceExtraHeight:(CGFloat)extraHeight {

    CGFloat yOffset = 0;
    CGRect frame;
    RCPublicServiceRichContentMessage *content = (RCPublicServiceRichContentMessage *)model.content;

    yOffset += RCPublicServiceSingleCellContentPaddingTop;
    frame = [RCPublicServiceImgTxtMsgCell getTitleFrame:content withWidth:collectionViewWidth];
    yOffset += frame.size.height;

    yOffset += RCPublicServiceSingleCellPadding1;
    frame = [RCPublicServiceImgTxtMsgCell getImageFrameWithWidth:collectionViewWidth];
    yOffset += frame.size.height;

    yOffset += RCPublicServiceSingleCellPadding2;
    frame = [RCPublicServiceImgTxtMsgCell getContentFrame:content withWidth:collectionViewWidth];
    yOffset += frame.size.height;

    yOffset += RCPublicServiceSingleCellPadding3;
    yOffset += 0.5;
    yOffset += RCPublicServiceSingleCellPadding4;
    NSString *readAll = RCLocalizedString(@"ReadAll");
    frame = [RCPublicServiceImgTxtMsgCell getReadAllFrame:readAll withWidth:collectionViewWidth];
    yOffset += frame.size.height;

    yOffset += RCPublicServiceSingleCellContentPaddingBottom;
    //由于extraHeight为SDK中固定的20而RCE中给的标注图中这里只需要15(container顶部与baseContentView的顶部距离为9底部与baseContentView的底部距离为6)的额外高度
    // ypf 修改距离底部距离14像素(-5)
    yOffset = yOffset + extraHeight;

    return CGSizeMake(collectionViewWidth, yOffset);
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        self.allowsSelection = YES;
        UILongPressGestureRecognizer *longGesture =
            [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressed:)];
        [self addGestureRecognizer:longGesture];
    }

    return self;
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    CGFloat yOffset = 0;
    RCPublicServiceRichContentMessage *content = (RCPublicServiceRichContentMessage *)model.content;

    yOffset += RCPublicServiceSingleCellContentPaddingTop;
    CGRect titleframe = [RCPublicServiceImgTxtMsgCell getTitleFrame:content withWidth:self.frame.size.width];
    titleframe.origin.y += yOffset;
    self.titleLabel.frame = titleframe;
    // UILabel *titleLabel = [[UILabel alloc] initWithFrame:titleframe];
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.font = [[RCKitConfig defaultConfig].font fontOfFirstLevel];
    
    self.titleLabel.textColor = RGBCOLOR(38, 38, 38);
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    self.titleLabel.text = content.richContent.title;
    yOffset += titleframe.size.height;

    yOffset += RCPublicServiceSingleCellPadding1;
    CGRect imageframe = [RCPublicServiceImgTxtMsgCell getImageFrameWithWidth:self.frame.size.width];
    imageframe.origin.y += yOffset;
    yOffset += imageframe.size.height;
    self.imageView.frame = imageframe;
    self.imageView.layer.masksToBounds = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    //    RCloudImageView *imageView = [[RCloudImageView alloc]initWithFrame:imageframe];
    [self.imageView setImageURL:[NSURL URLWithString:content.richContent.imageURL]];

    yOffset += RCPublicServiceSingleCellPadding2;
    CGRect contentframe = [RCPublicServiceImgTxtMsgCell getContentFrame:content withWidth:self.frame.size.width];
    contentframe.origin.y += yOffset;
    yOffset += contentframe.size.height;

    self.contentLabel.frame = contentframe;
    //    UILabel *contentLabel = [[UILabel alloc] initWithFrame:contentframe];
    self.contentLabel.numberOfLines = 0;
    self.contentLabel.font = [[RCKitConfig defaultConfig].font fontOfThirdLevel];
    
    self.contentLabel.textColor = RGBCOLOR(127, 127, 127);
    self.contentLabel.textAlignment = NSTextAlignmentLeft;
    self.contentLabel.text = content.richContent.digest;

    yOffset += RCPublicServiceSingleCellPadding3;

    self.line.frame =
        CGRectMake(0, yOffset, self.contentView.frame.size.width - RCPublicServiceSingleCellPaddingLeft * 2, 0.5);
    for (CALayer *layer in self.line.layer.sublayers) {
        [layer removeFromSuperlayer];
    }
    UIBezierPath *linePath = [UIBezierPath bezierPath];
    [linePath moveToPoint:CGPointMake(0, 0)];
    [linePath addLineToPoint:CGPointMake(self.line.frame.size.width, 0)];
    CAShapeLayer *lineLayer = [CAShapeLayer layer];
    lineLayer.lineWidth = self.line.frame.size.height;
    lineLayer.strokeColor = [UIColor colorWithRed:229 / 255.0 green:229 / 255.0 blue:229 / 255.0 alpha:1].CGColor;
    lineLayer.path = linePath.CGPath;
    lineLayer.fillColor = nil;
    [self.line.layer addSublayer:lineLayer];

    yOffset += 0.5;

    yOffset += RCPublicServiceSingleCellPadding4;
    NSString *readAll = RCLocalizedString(@"ReadAll");
    CGRect readallframe = [RCPublicServiceImgTxtMsgCell getReadAllFrame:readAll withWidth:self.frame.size.width];
    readallframe.origin.y += yOffset;
    yOffset += readallframe.size.height;
    self.readallLabel.frame = readallframe;
    //    UILabel *readallLabel = [[UILabel alloc] initWithFrame:readallframe];
    self.readallLabel.numberOfLines = 0;
    self.readallLabel.font = [[RCKitConfig defaultConfig].font fontOfThirdLevel];
    self.readallLabel.textColor = RGBCOLOR(38, 38, 38);
    self.readallLabel.textAlignment = NSTextAlignmentLeft;
    self.readallLabel.text = readAll;
    self.arrow.frame =
        CGRectMake(self.frame.size.width - RCPublicServiceSingleCellPaddingRight -
                       RCPublicServiceSingleCellPaddingLeft - RCPublicServiceSingleCellImagePaddingRight - 8,
                   readallframe.origin.y, 8, 15);

    yOffset += RCPublicServiceSingleCellContentPaddingBottom;

    self.container.frame = CGRectMake(
        RCPublicServiceSingleCellPaddingLeft, RCPublicServiceSingleCellPaddingTop,
        self.frame.size.width - RCPublicServiceSingleCellPaddingLeft - RCPublicServiceSingleCellPaddingRight, yOffset);
    [self.container setBackgroundColor:[UIColor whiteColor]];

    self.container.layer.cornerRadius = 4;
    self.container.layer.masksToBounds = YES;

    if (content.richContent.url) {
        UITapGestureRecognizer *tapGesture =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTaped:)];
        [self addGestureRecognizer:tapGesture];
    }

    CGRect messageTimeLabelFrame = self.messageTimeLabel.frame;
    messageTimeLabelFrame.origin.y = 12;
    self.messageTimeLabel.frame = messageTimeLabelFrame;
}

#pragma mark – Private Methods

+ (CGRect)getTitleFrame:(RCPublicServiceRichContentMessage *)content withWidth:(CGFloat)width {
    width = width - RCPublicServiceSingleCellPaddingLeft - RCPublicServiceSingleCellPaddingRight;
    CGSize size = CGSizeMake(
        width - RCPublicServiceSingleCellContentPaddingLeft - RCPublicServiceSingleCellContentPaddingRight, 2000);
    CGSize labelsize = [RCKitUtility getTextDrawingSize:content.richContent.title
                                                   font:[[RCKitConfig defaultConfig].font fontOfFirstLevel]
                                        constrainedSize:size];
    return CGRectMake(RCPublicServiceSingleCellContentPaddingLeft, 0, labelsize.width, labelsize.height);
}

+ (CGRect)getDateFrame:(RCMessageModel *)model withWidth:(CGFloat)width {
    width = width - RCPublicServiceSingleCellPaddingLeft - RCPublicServiceSingleCellPaddingRight;
    CGSize size = CGSizeMake(
        width - RCPublicServiceSingleCellContentPaddingLeft - RCPublicServiceSingleCellContentPaddingRight, 2000);

    NSDateFormatter *formatter = [self getDateFormatter];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:model.sentTime / 1000];
    NSString *dateString = [formatter stringFromDate:date];
    CGSize labelsize = [RCKitUtility getTextDrawingSize:dateString
                                                   font:[[RCKitConfig defaultConfig].font fontOfThirdLevel]
                                        constrainedSize:size];
    return CGRectMake(RCPublicServiceSingleCellContentPaddingLeft, 0, labelsize.width, labelsize.height);
}

+ (NSDateFormatter *)getDateFormatter {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        // formatter.timeZone = [NSTimeZone timeZoneWithName:@"shanghai"];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        [formatter setDateFormat:RCLocalizedString(@"DateFormat")];
    });
    return formatter;
}

+ (CGRect)getImageFrameWithWidth:(CGFloat)width {
    width = width - RCPublicServiceSingleCellPaddingLeft - RCPublicServiceSingleCellPaddingRight;
    return CGRectMake(RCPublicServiceSingleCellImagePaddingLeft, 0,
                      width - RCPublicServiceSingleCellImagePaddingLeft - RCPublicServiceSingleCellImagePaddingRight,
                      (width - RCPublicServiceSingleCellImagePaddingLeft - RCPublicServiceSingleCellImagePaddingRight) *
                          5 / 9);
}

+ (CGRect)getContentFrame:(RCPublicServiceRichContentMessage *)content withWidth:(CGFloat)width {
    width = width - RCPublicServiceSingleCellPaddingLeft - RCPublicServiceSingleCellPaddingRight;
    CGSize size = CGSizeMake(
        width - RCPublicServiceSingleCellContentPaddingLeft - RCPublicServiceSingleCellContentPaddingRight, 2000);
    CGSize labelsize = [RCKitUtility getTextDrawingSize:content.richContent.digest
                                                   font:[[RCKitConfig defaultConfig].font fontOfThirdLevel]
                                        constrainedSize:size];
    return CGRectMake(RCPublicServiceSingleCellContentPaddingLeft, 0, labelsize.width, labelsize.height);
}

+ (CGRect)getReadAllFrame:(NSString *)content withWidth:(CGFloat)width {
    width = width - RCPublicServiceSingleCellPaddingLeft - RCPublicServiceSingleCellPaddingRight;
    CGSize size =
        CGSizeMake(width - RCPublicServiceSingleCellContentPaddingLeft - RCPublicServiceSingleCellPaddingRight, 2000);
    CGSize labelsize = [RCKitUtility getTextDrawingSize:content
                                                   font:[[RCKitConfig defaultConfig].font fontOfThirdLevel]
                                        constrainedSize:size];
    return CGRectMake(RCPublicServiceSingleCellContentPaddingLeft, 0, labelsize.width, labelsize.height);
}

- (void)onTaped:(id)sender {
    RCPublicServiceRichContentMessage *content = (RCPublicServiceRichContentMessage *)self.model.content;
    [self.publicServiceDelegate didTapUrlInPublicServiceMessageCell:content.richContent.url model:self.model];
}

- (void)onLongPressed:(id)sender {
    UILongPressGestureRecognizer *press = (UILongPressGestureRecognizer *)sender;
    if (press.state == UIGestureRecognizerStateEnded) {
        return;
    } else if (press.state == UIGestureRecognizerStateBegan) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didLongTouchMessageCell:inView:)]) {
            [self.delegate didLongTouchMessageCell:self.model inView:self];
        }
    }
}

#pragma mark – Getters and Setters
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        [self.container addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (UIView *)line {
    if (!_line) {
        _line = [UIView new];
        [self.container addSubview:_line];
    }
    return _line;
}

- (UIImageView *)arrow {
    if (!_arrow) {
        _arrow = [UIImageView new];
        [_arrow setImage:RCResourceImage(@"right_arrow")];
        [self.container addSubview:_arrow];
    }
    return _arrow;
}

- (RCloudImageView *)imageView {
    if (!_imageView) {
        _imageView = [RCloudImageView new];
        [self.container addSubview:_imageView];
    }
    return _imageView;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [UILabel new];
        [self.container addSubview:_contentLabel];
    }
    return _contentLabel;
}

- (UILabel *)readallLabel {
    if (!_readallLabel) {
        _readallLabel = [UILabel new];
        [self.container addSubview:_readallLabel];
    }
    return _readallLabel;
}

- (UIView *)container {
    if (!_container) {
        _container = [UIView new];
        [self.baseContentView addSubview:_container];
    }
    return _container;
}
@end
