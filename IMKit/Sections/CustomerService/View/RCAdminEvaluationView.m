//
//  RCAdminEvaluationView.m
//  RongIMKit
//
//  Created by litao on 16/2/22.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCAdminEvaluationView.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#define STAR_COUNT 5
#define CLIENT_VIEW_HEIGHT 120
#define CLIENT_VIEW_WIDTH 290
#define TITLE_PADDING_TOP 10
#define TITLE_PADDING_LEFT_RIGHT 10
#define TITLE_HEIGHT 40
#define TITLE_WIDTH (CLIENT_VIEW_WIDTH - TITLE_PADDING_LEFT_RIGHT - TITLE_PADDING_LEFT_RIGHT)
#define STAR_PADDING_LEFT_RIGHT 20
#define STARS_PADDING 10
#define STAR_WIDTH                                                                                                     \
    ((CLIENT_VIEW_WIDTH - STAR_PADDING_LEFT_RIGHT - STAR_PADDING_LEFT_RIGHT + STARS_PADDING) / STAR_COUNT -            \
     STARS_PADDING)
#define STAR_PADDING_TOP_BUTTOM 15
#define STAR_HEIGHT                                                                                                    \
    (CLIENT_VIEW_HEIGHT - TITLE_PADDING_TOP - TITLE_HEIGHT - STAR_PADDING_TOP_BUTTOM - STAR_PADDING_TOP_BUTTOM)

@interface RCAdminEvaluationView () <RCCustomIOSAlertViewDelegate>
@property (nonatomic, weak) id<RCAdminEvaluationViewDelegate> adminEvaluationViewDelegate;
@property (nonatomic) int starValue; // 0-4
@property (nonatomic, strong) NSArray *starButtonArray;
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation RCAdminEvaluationView
- (instancetype)initWithDelegate:(id<RCAdminEvaluationViewDelegate>)delegate {
    self = [super init];
    if (self) {
        self.adminEvaluationViewDelegate = delegate;
        self.starValue = -1;
        self.delegate = self;
        [self setButtonTitles:[NSMutableArray
                                  arrayWithObjects:RCLocalizedString(@"Submit"),
                                                   RCLocalizedString(@"Cancel"), nil]];
        [self setContainerView:[self createDemoView]];
    }
    return self;
}

#pragma mark - RCCustomIOSAlertViewDelegate
// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)customIOS7dialogButtonTouchUpInside:(RCCustomIOSAlertView *)alertView
                       clickedButtonAtIndex:(NSInteger)buttonIndex {
    DebugLog(@"Delegate: Button at position %d is clicked on alertView %d.", (int)buttonIndex, (int)[alertView tag]);
    if (buttonIndex == 1) {
        [self.adminEvaluationViewDelegate adminEvaluateViewCancel:self];
    } else if (buttonIndex == 0) {
        [self.adminEvaluationViewDelegate adminEvaluateView:self didEvaluateValue:self.starValue];
    }
    [alertView close];
}

#pragma mark - Private Methods

- (UIButton *)starAtIndex:(int)index {
    UIButton *starButton = [[UIButton alloc]
        initWithFrame:CGRectMake(STAR_PADDING_LEFT_RIGHT + index * (STARS_PADDING + STAR_WIDTH),
                                 STAR_PADDING_TOP_BUTTOM + TITLE_PADDING_TOP + TITLE_HEIGHT, STAR_WIDTH, STAR_HEIGHT)];
    [starButton setTag:index];
    [starButton addTarget:self action:@selector(onStarButton:) forControlEvents:UIControlEventTouchDown];
    [starButton setBackgroundImage:RCResourceImage(@"custom_service_star_selected") forState:UIControlStateNormal];

    return starButton;
}

- (void)onStarButton:(id)sender {
    UIButton *touchedButton = (UIButton *)sender;
    self.starValue = (int)touchedButton.tag;
}

- (void)setStarValue:(int)starValue {
    _starValue = starValue;
    for (int i = 0; i < STAR_COUNT; i++) {
        UIButton *btn = self.starButtonArray[i];
        if (i <= starValue) {
            [btn setBackgroundImage:RCResourceImage(@"custom_service_evaluation_star_hover")
                           forState:UIControlStateNormal];
        } else {
            [btn setBackgroundImage:RCResourceImage(@"custom_service_evaluation_star") forState:UIControlStateNormal];
        }
    }
}
- (UIView *)createDemoView {
    UIView *demoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CLIENT_VIEW_WIDTH, CLIENT_VIEW_HEIGHT)];

    for (int i = 0; i < STAR_COUNT; i++) {
        UIButton *btn = self.starButtonArray[i];
        [demoView addSubview:btn];
    }
    [demoView addSubview:self.titleLabel];
    return demoView;
}

#pragma mark - Getters and Setters

- (NSArray *)starButtonArray {
    if (!_starButtonArray) {
        NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < STAR_COUNT; i++) {
            [mutableArray addObject:[self starAtIndex:i]];
        }
        _starButtonArray = mutableArray;
    }
    return _starButtonArray;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]
            initWithFrame:CGRectMake(TITLE_PADDING_LEFT_RIGHT, TITLE_PADDING_TOP, TITLE_WIDTH, TITLE_HEIGHT)];
        [_titleLabel setText:RCLocalizedString(@"Admin_Comment_Title")];
        [_titleLabel setTextAlignment:NSTextAlignmentCenter];
        _titleLabel.textColor = RCDYCOLOR(0x000000, 0x9f9f9f);
    }
    return _titleLabel;
}
@end
