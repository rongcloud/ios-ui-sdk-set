//
//  RCPublicServiceProfileUrlCell.m
//  HelloIos
//
//  Created by litao on 15/4/10.
//  Copyright (c) 2015年 litao. All rights reserved.
//

#import "RCPublicServiceProfileUrlCell.h"
#import "RCKitUtility.h"
#import "RCPublicServiceViewConstants.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
@interface RCPublicServiceProfileUrlCell ()
@property (nonatomic, strong) UILabel *title;
@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, weak) id<RCPublicServiceProfileViewUrlDelegate> delegate;
@end

@implementation RCPublicServiceProfileUrlCell

- (instancetype)init {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"hello"];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setTitle:(NSString *)title
             url:(NSString *)urlString
        delegate:(id<RCPublicServiceProfileViewUrlDelegate>)delegate {
    self.title.text = title;
    self.urlString = urlString;
    [self updateFrame];
    if (urlString && urlString.length > 0) {
        UITapGestureRecognizer *tapGesture =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTaped:)];
        [self addGestureRecognizer:tapGesture];
    }

    self.delegate = delegate;
}

#pragma mark – Private Methods

- (void)setup {
    CGRect bounds = [[UIScreen mainScreen] bounds];
    bounds.size.height = 0;
    self.frame = bounds;

    self.title = [[UILabel alloc] initWithFrame:CGRectZero];

    self.title.numberOfLines = 0;
    self.title.textAlignment = NSTextAlignmentLeft;
    self.title.font = [[RCKitConfig defaultConfig].font fontOfFirstLevel];
    self.title.textColor = RCDYCOLOR(0x00000, 0x9f9f9f);
    [self.contentView addSubview:self.title];
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)onTaped:(id)sender {
    [self.delegate gotoUrl:self.urlString];
}

- (void)updateFrame {
    CGRect contentViewFrame = self.frame;
    UIFont *font = [[RCKitConfig defaultConfig].font fontOfFirstLevel];
    //设置一个行高上限
    CGSize size = CGSizeMake(RCPublicServiceProfileCellTitleWidth, 2000);
    //计算实际frame大小，并将label的frame变成实际大小
    CGSize labelsize = [RCKitUtility getTextDrawingSize:self.title.text font:font constrainedSize:size];
    self.title.frame = CGRectMake(2 * RCPublicServiceProfileCellPaddingLeft, RCPublicServiceProfileCellPaddingTop,
                                  labelsize.width, labelsize.height);

    contentViewFrame.size.height =
        self.title.frame.size.height + RCPublicServiceProfileCellPaddingTop + RCPublicServiceProfileCellPaddingBottom;
    self.frame = contentViewFrame;
}
@end
