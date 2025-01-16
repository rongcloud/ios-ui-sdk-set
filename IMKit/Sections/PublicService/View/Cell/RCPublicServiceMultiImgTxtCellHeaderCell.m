//
//  RCPublicServiceMultiImgTxtCellHeaderCell.m
//  RongIMKit
//
//  Created by litao on 15/4/15.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCPublicServiceMultiImgTxtCellHeaderCell.h"
#import "RCKitUtility.h"
#import "RCPublicServiceViewConstants.h"
#import "RCloudImageView.h"
#import "RCKitConfig.h"
#import "RCKitCommonDefine.h"

@interface RCPublicServiceMultiImgTxtCellHeaderCell ()
@property (nonatomic, strong) RCloudImageView *headerImageView;
@property (nonatomic, strong) UIView *headerGradientView;
@property (nonatomic, strong) UILabel *headerLabel;
@end

@implementation RCPublicServiceMultiImgTxtCellHeaderCell

- (instancetype)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];

    if (self) {
        self.frame = frame;
        self.frame =
            CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width,
                       [RCPublicServiceMultiImgTxtCellHeaderCell getHeaderCellHeightWithWidth:self.frame.size.width]);
        self.headerImageView = [[RCloudImageView alloc] init];
        self.layer.masksToBounds = YES;
        self.headerImageView.layer.masksToBounds = YES;
        self.headerImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.headerImageView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);

        self.headerGradientView = [[UIView alloc]
            initWithFrame:CGRectMake(0, self.frame.size.height - RCPublicServiceMultiImgTxtCellHeaderCellGradientHeight,
                                     self.frame.size.width, RCPublicServiceMultiImgTxtCellHeaderCellGradientHeight)];
        [self.headerGradientView.layer
            insertSublayer:[self getGradientLayerWithFrame:CGRectMake(
                                                               0, 0, self.frame.size.width,
                                                               RCPublicServiceMultiImgTxtCellHeaderCellGradientHeight)]
                   atIndex:0];

        self.headerLabel = [UILabel new];
        self.headerLabel.textAlignment = NSTextAlignmentLeft;
        self.headerLabel.lineBreakMode = NSLineBreakByCharWrapping;
        self.headerLabel.numberOfLines = 0;
        self.headerLabel.textColor = [UIColor whiteColor];
        self.headerLabel.font = [[RCKitConfig defaultConfig].font fontOfFirstLevel];

        [self addSubview:self.headerImageView];
        [self addSubview:self.headerGradientView];
        [self addSubview:self.headerLabel];

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

+ (CGFloat)getHeaderCellHeightWithWidth:(CGFloat)width {
    return width * 5 / 9;
}

#pragma mark - Private Methods

- (CAGradientLayer *)getGradientLayerWithFrame:(CGRect)frame {
    //为透明度设置渐变效果
    UIColor *colorBegin = [UIColor colorWithRed:(0 / 255.0) green:(0 / 255.0) blue:(0 / 255.0) alpha:0.6];
    UIColor *colorEnd = [UIColor colorWithRed:(0 / 255.0) green:(0 / 255.0) blue:(0 / 255.0) alpha:0.0];
    NSArray *colors = [NSArray arrayWithObjects:(id)colorBegin.CGColor, (id)colorEnd.CGColor, nil];
    CAGradientLayer *gradient = [CAGradientLayer layer];

    gradient.startPoint = CGPointMake(0, 1);
    gradient.endPoint = CGPointMake(0, 0);
    gradient.colors = colors;
    gradient.frame = frame;
    return gradient;
}

- (void)setRichContent:(RCRichContentMessage *)richContent {
    _richContent = richContent;

    [self.headerImageView setImageURL:[NSURL URLWithString:_richContent.imageURL]];

    //设置一个行高上限
    CGSize size = CGSizeMake(self.frame.size.width - RCPublicServiceMultiImgTxtCellHeaderCellTextPaddingLeft -
                                 RCPublicServiceMultiImgTxtCellHeaderCellTextPaddingRight,
                             2000);
    CGSize labelsize =
        [RCKitUtility getTextDrawingSize:_richContent.title
                                    font:[[RCKitConfig defaultConfig].font fontOfFirstLevel]
                         constrainedSize:size];
    if (labelsize.height > RCPublicServiceMultiImgTxtCellHeaderCellGradientHeight) {
        labelsize.height = RCPublicServiceMultiImgTxtCellHeaderCellGradientHeight;
    }

    self.headerLabel.frame = CGRectMake(
        RCPublicServiceMultiImgTxtCellHeaderCellTextPaddingLeft,
        self.frame.size.height - labelsize.height - RCPublicServiceMultiImgTxtCellHeaderCellTextPaddingBottom,
        self.frame.size.width - RCPublicServiceMultiImgTxtCellHeaderCellTextPaddingLeft -
            RCPublicServiceMultiImgTxtCellHeaderCellTextPaddingRight,
        labelsize.height);
    NSString *headerText = [NSString stringWithFormat:@"%@", _richContent.title];
    self.headerLabel.text = headerText;
    if (_richContent.url) {
    }
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
