//
//  RCSearchItemView.m
//  HelloIos
//
//  Created by litao on 15/4/9.
//  Copyright (c) 2015年 litao. All rights reserved.
//

#import "RCSearchItemView.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCPublicServiceViewConstants.h"

@interface RCSearchItemView ()
@property (nonatomic, strong) UILabel *keyLabel;
@end

@implementation RCSearchItemView
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setKeyContent:(NSString *)keyContent {
    if (keyContent) {
        NSDictionary *dict = @{NSForegroundColorAttributeName : RGBCOLOR(83, 213, 105)};
        NSAttributedString *key = [[NSAttributedString alloc] initWithString:keyContent attributes:dict];
        self.keyLabel.attributedText = key;
    }
}

#pragma mark – Private Methods

- (void)setup {
    UIImageView *imageView = [[UIImageView alloc]
        initWithFrame:CGRectMake(RCPublicServiceProfileCellPaddingLeft, RCPublicServiceProfileCellPaddingTop,
                                 RCPublicServiceProfileHeaderImageWidth - 20,
                                 RCPublicServiceProfileHeaderImageHeigh - 20)];
    [imageView setImage:RCResourceImage(@"default_portrait")];

    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    CGSize size = CGSizeMake(RCPublicServiceProfileCellTitleWidth, 2000);
    CGSize labelsize = [RCKitUtility getTextDrawingSize:RCLocalizedString(@"Search")
                                                   font:font
                                        constrainedSize:size];
    UILabel *searchLabel =
        [[UILabel alloc] initWithFrame:CGRectMake(RCPublicServiceProfileHeaderImageWidth,
                                                  RCPublicServiceProfileHeaderImageHeigh / 2 - labelsize.height / 2,
                                                  labelsize.width, labelsize.height)];
    CGRect frame = searchLabel.frame;
    frame.origin.x += frame.size.width + 5;
    frame.size.width = self.frame.size.width - frame.origin.x - RCPublicServiceProfileHeaderPaddingRight;
    self.keyLabel.frame = frame;

    [self addSubview:imageView];
    [self addSubview:searchLabel];
    [self addSubview:self.keyLabel];

    UITapGestureRecognizer *tapGesture =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTaped:)];
    [self addGestureRecognizer:tapGesture];
}

- (void)onTaped:(id)sender {
    [self.delegate onSearchItemTapped];
}

#pragma mark – Getters and Setters

- (UILabel *)keyLabel{
    if (!_keyLabel) {
        _keyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _keyLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _keyLabel.textAlignment = NSTextAlignmentLeft;
        _keyLabel.numberOfLines = 1;
        [_keyLabel setText:@"搜索: "];
        _keyLabel.textAlignment = NSTextAlignmentLeft;
        _keyLabel.numberOfLines = 1;
    }
    return _keyLabel;
}
@end
