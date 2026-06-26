//
//  RCPublicServiceMultiImgTxtCellContentCell.m
//  RongIMKit
//
//  Created by litao on 15/4/15.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCPublicServiceMultiImgTxtCellContentCell.h"
#import "RCKitUtility.h"
#import "RCPublicServiceViewConstants.h"
#import "RCloudImageView.h"
#import "RCKitConfig.h"
#import "RCKitCommonDefine.h"

@interface RCPublicServiceMultiImgTxtCellContentCell ()
@property (nonatomic, strong) RCloudImageView *rightImageView;
@property (nonatomic, strong) UILabel *leftLabel;
@end

@implementation RCPublicServiceMultiImgTxtCellContentCell

- (instancetype)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width,
                                RCPublicServiceCellContentExtraHeight + RCPublicServiceCellContentCellImageHeight);
        self.rightImageView = [[RCloudImageView alloc]
            initWithFrame:CGRectMake(self.frame.size.width - RCPublicServiceCellContentPaddingRight -
                                         RCPublicServiceCellContentCellImageWidth,
                                     RCPublicServiceCellContentExtraHeight / 2,
                                     RCPublicServiceCellContentCellImageWidth,
                                     RCPublicServiceCellContentCellImageHeight)];

        self.rightImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.rightImageView.clipsToBounds = YES;

        self.leftLabel = [UILabel new];
        self.leftLabel.textAlignment = NSTextAlignmentLeft;
        self.leftLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.leftLabel.numberOfLines = 2;
        self.leftLabel.font = [[RCKitConfig defaultConfig].font fontOfFirstLevel];

        [self.contentView addSubview:self.rightImageView];
        [self.contentView addSubview:self.leftLabel];

        if (self) {
            UILongPressGestureRecognizer *longGesture =
                [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressed:)];
            [self addGestureRecognizer:longGesture];
            UITapGestureRecognizer *tapGesture =
                [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTaped:)];
            [self addGestureRecognizer:tapGesture];
        }
    }
    return self;
}

+ (CGFloat)getContentCellHeight:(RCRichContentMessage *)richContent {
    return RCPublicServiceCellContentCellImageHeight + RCPublicServiceCellContentExtraHeight;
}

#pragma mark – Private Methods

- (CGSize)getTextSize:(RCRichContentMessage *)richContent withWidth:(CGFloat)width {
    //设置一个行高上限
    CGSize size = CGSizeMake(width - RCPublicServiceCellContentPaddingLeft - RCPublicServiceCellContentPaddingRight -
                                 RCPublicServiceCellContentCellImageWidth - RCPublicServiceCellContentPadding,
                             2000);
    CGSize labelSize =
        [RCKitUtility getTextDrawingSize:richContent.title
                                    font:[[RCKitConfig defaultConfig].font fontOfFirstLevel]
                         constrainedSize:size];
    if (labelSize.height > RCPublicServiceCellContentCellImageWidth - 12) {
        labelSize.height = RCPublicServiceCellContentCellImageWidth - 12;
    }
    return labelSize;
}

- (void)setRichContent:(RCRichContentMessage *)richContent {
    _richContent = richContent;
    [self.rightImageView setImageURL:[NSURL URLWithString:_richContent.imageURL]];

    CGSize labelsize = [self getTextSize:_richContent withWidth:self.frame.size.width];

    self.leftLabel.frame = CGRectMake(RCPublicServiceCellContentPaddingLeft, 16, labelsize.width, labelsize.height);
    self.separatorInset = UIEdgeInsetsMake(0, CGRectGetMinX(self.leftLabel.frame), 0,
                                           self.bounds.size.width - CGRectGetMinX(self.rightImageView.frame) + 17.5);

    self.leftLabel.text = _richContent.title;
}

- (void)onTaped:(id)sender {
    DebugLog(@"ontaped:");
    [self.publicServiceDelegate didTapUrlInPublicServiceMessageCell:self.richContent.url model:nil];
}

- (void)onLongPressed:(id)sender {
    UILongPressGestureRecognizer *press = (UILongPressGestureRecognizer *)sender;
    if (press.state == UIGestureRecognizerStateEnded) {
        return;
    } else if (press.state == UIGestureRecognizerStateBegan) {
        [self.delegate longPressAction:self];
    }
}
@end
