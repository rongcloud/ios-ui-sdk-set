//
//  RCRobotEvaluationView.m
//  RongIMKit
//
//  Created by litao on 16/2/22.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCRobotEvaluationView.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
@interface RCRobotEvaluationView () <RCCustomIOSAlertViewDelegate>
@property (nonatomic, weak) id<RCRobotEvaluationViewDelegate> robotEvaluationViewDelegate;
@property (nonatomic) BOOL isResolved;
@property (nonatomic, strong) UIButton *yesButton;
@property (nonatomic, strong) UIButton *noButton;
@property (nonatomic, strong) UILabel *titleLabel;
@end
#define CLIENT_VIEW_HEIGHT 120
#define CLIENT_VIEW_WIDTH 290
#define TITLE_PADDING_TOP 10
#define TITLE_PADDING_LEFT_RIGHT 10
#define TITLE_HEIGHT 40
#define TITLE_WIDTH (CLIENT_VIEW_WIDTH - TITLE_PADDING_LEFT_RIGHT - TITLE_PADDING_LEFT_RIGHT)
#define BUTTON_PADDING_LEFT_RIGHT 40
#define BUTTONS_PADDING 40
#define BUTTON_WIDTH (CLIENT_VIEW_WIDTH - BUTTON_PADDING_LEFT_RIGHT - BUTTON_PADDING_LEFT_RIGHT - BUTTONS_PADDING) / 2
#define BUTTON_PADDING_TOP_BUTTOM 10
#define BUTTON_HEIGHT                                                                                                  \
    (CLIENT_VIEW_HEIGHT - TITLE_PADDING_TOP - TITLE_HEIGHT - BUTTON_PADDING_TOP_BUTTOM - BUTTON_PADDING_TOP_BUTTOM)

@implementation RCRobotEvaluationView
- (instancetype)initWithDelegate:(id<RCRobotEvaluationViewDelegate>)delegate {
    self = [super init];
    if (self) {
        self.robotEvaluationViewDelegate = delegate;
        self.isResolved = YES;
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
        [self.robotEvaluationViewDelegate robotEvaluateViewCancel:self];
    } else if (buttonIndex == 0) {
        [self.robotEvaluationViewDelegate robotEvaluateView:self didEvaluateValue:self.isResolved];
    }
    [alertView close];
}

#pragma mark - Private Methods

- (void)onYesButton:(id)sender {
    self.isResolved = YES;
}
- (void)onNoButton:(id)sender {
    self.isResolved = NO;
}
- (void)setIsResolved:(BOOL)isResolved {
    _isResolved = isResolved;
    [self.noButton setSelected:!_isResolved];
    [self.yesButton setSelected:_isResolved];
}

- (UIView *)createDemoView {
    UIView *demoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CLIENT_VIEW_WIDTH, CLIENT_VIEW_HEIGHT)];

    [demoView addSubview:self.yesButton];
    [demoView addSubview:self.noButton];
    [demoView addSubview:self.titleLabel];
    return demoView;
}

#pragma mark - Getters and Setters

- (UIButton *)yesButton {
    if (!_yesButton) {
        _yesButton =
            [[UIButton alloc] initWithFrame:CGRectMake(BUTTON_PADDING_LEFT_RIGHT,
                                                       BUTTON_PADDING_TOP_BUTTOM + TITLE_PADDING_TOP + TITLE_HEIGHT,
                                                       BUTTON_WIDTH, BUTTON_HEIGHT)];

        [_yesButton addTarget:self action:@selector(onYesButton:) forControlEvents:UIControlEventTouchDown];
        [_yesButton setBackgroundImage:RCResourceImage(@"custom_service_evaluation_yes_hover")
                              forState:UIControlStateSelected];
        [_yesButton setBackgroundImage:RCResourceImage(@"custom_service_evaluation_yes") forState:UIControlStateNormal];
        [_yesButton.layer setMasksToBounds:YES];
        [_yesButton.layer setCornerRadius:3.0];
        //        [_yesButton.layer setBorderWidth:0.5f];
        //        [_yesButton setTitleColor:[UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0
        //        alpha:1.0f] forState:UIControlStateNormal];
    }
    return _yesButton;
}

- (UIButton *)noButton {
    if (!_noButton) {
        _noButton =
            [[UIButton alloc] initWithFrame:CGRectMake(BUTTON_PADDING_LEFT_RIGHT + BUTTON_WIDTH + BUTTONS_PADDING,
                                                       BUTTON_PADDING_TOP_BUTTOM + TITLE_PADDING_TOP + TITLE_HEIGHT,
                                                       BUTTON_WIDTH, BUTTON_HEIGHT)];
        [_noButton addTarget:self action:@selector(onNoButton:) forControlEvents:UIControlEventTouchDown];
        [_noButton setBackgroundImage:RCResourceImage(@"custom_service_evaluation_no_hover")
                             forState:UIControlStateSelected];
        [_noButton setBackgroundImage:RCResourceImage(@"custom_service_evaluation_no") forState:UIControlStateNormal];
        [_noButton.layer setMasksToBounds:YES];
        [_noButton.layer setCornerRadius:3.0];
        //        [_noButton.layer setBorderWidth:0.5f];
        //        [_noButton setTitleColor:[UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0
        //        alpha:1.0f] forState:UIControlStateNormal];
    }
    return _noButton;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]
            initWithFrame:CGRectMake(TITLE_PADDING_LEFT_RIGHT, TITLE_PADDING_TOP, TITLE_WIDTH, TITLE_HEIGHT)];
        [_titleLabel setText:RCLocalizedString(@"Robot_Comment_Title")];
        [_titleLabel setTextAlignment:NSTextAlignmentCenter];
        _titleLabel.textColor = RCDYCOLOR(0x000000, 0x9f9f9f);
    }
    return _titleLabel;
}
@end
