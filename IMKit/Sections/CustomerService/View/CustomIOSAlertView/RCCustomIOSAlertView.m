//
//  RCCustomIOSAlertView.m
//  RCCustomIOSAlertView
//
//  Created by Richard on 20/09/2013.
//  Copyright (c) 2013-2015 Wimagguc.
//
//  Lincesed under The MIT License (MIT)
//  http://opensource.org/licenses/MIT
//

#import "RCCustomIOSAlertView.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
const static CGFloat kRCCustomIOSAlertViewDefaultButtonHeight = 50;
const static CGFloat kRCCustomIOSAlertViewDefaultButtonSpacerHeight = 1;
const static CGFloat kRCCustomIOSAlertViewCornerRadius = 7;
const static CGFloat kCustomIOS7MotionEffectExtent = 10.0;

CGFloat rcButtonHeight = 0;
CGFloat rcButtonSpacerHeight = 0;

@implementation RCCustomIOSAlertView

@synthesize parentView, containerView, dialogView, onButtonTouchUpInside;
@synthesize delegate;
@synthesize buttonTitles;
@synthesize useMotionEffects;

- (id)initWithParentView:(UIView *)_parentView {
    self = [self init];
    if (_parentView) {
        self.frame = _parentView.frame;
        self.parentView = _parentView;
        self.parentView.backgroundColor =
            [RCKitUtility generateDynamicColor:[HEXCOLOR(0x000000) colorWithAlphaComponent:0.5]
                                     darkColor:[HEXCOLOR(0x6a6a6a) colorWithAlphaComponent:0.6]];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        self.frame =
            CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);

        delegate = self;
        useMotionEffects = false;
        buttonTitles = @[ @"Close" ];

        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deviceOrientationDidChange:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

#pragma mark - Public Methods
// Create the dialog view, and animate opening the dialog
- (void)show {
    dialogView = [self createContainerView];

    dialogView.layer.shouldRasterize = YES;
    dialogView.layer.rasterizationScale = [[UIScreen mainScreen] scale];

    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [[UIScreen mainScreen] scale];

#if (defined(__IPHONE_7_0))
    if (useMotionEffects) {
        [self applyMotionEffects];
    }
#endif

    self.backgroundColor = [RCKitUtility generateDynamicColor:[HEXCOLOR(0x000000) colorWithAlphaComponent:0.5]
                                                    darkColor:[HEXCOLOR(0x6a6a6a) colorWithAlphaComponent:0.6]];

    [self addSubview:dialogView];

    // Can be attached to a view or to the top most window
    // Attached to a view:
    if (parentView != NULL) {
        [parentView addSubview:self];

        // Attached to the top most window
    } else {

        // On iOS7, calculate with orientation
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {

            UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
            switch (interfaceOrientation) {
            case UIInterfaceOrientationLandscapeLeft:
                self.transform = CGAffineTransformMakeRotation(M_PI * 270.0 / 180.0);
                break;

            case UIInterfaceOrientationLandscapeRight:
                self.transform = CGAffineTransformMakeRotation(M_PI * 90.0 / 180.0);
                break;

            case UIInterfaceOrientationPortraitUpsideDown:
                self.transform = CGAffineTransformMakeRotation(M_PI * 180.0 / 180.0);
                break;

            default:
                break;
            }

            [self setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];

            // On iOS8, just place the dialog in the middle
        } else {

            CGSize screenSize = [self countScreenSize];
            CGSize dialogSize = [self countDialogSize];
            CGSize keyboardSize = CGSizeMake(0, 0);

            dialogView.frame = CGRectMake((screenSize.width - dialogSize.width) / 2,
                                          (screenSize.height - keyboardSize.height - dialogSize.height) / 2,
                                          dialogSize.width, dialogSize.height);
        }

        [[[[UIApplication sharedApplication] windows] firstObject] addSubview:self];
    }

    dialogView.layer.opacity = 0.5f;
    dialogView.layer.transform = CATransform3DMakeScale(1.3f, 1.3f, 1.0);

    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.2f
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         __strong typeof(weakSelf) strongSelf = weakSelf;
                         strongSelf.dialogView.layer.opacity = 1.0f;
                         strongSelf.dialogView.layer.transform = CATransform3DMakeScale(1, 1, 1);
                     }
                     completion:NULL];
}

// Button has been touched
- (IBAction)customIOS7dialogButtonTouchUpInside:(id)sender {
    [self dismissWithClickedButtonIndex:(int)[sender tag]];
}

- (void)dismissWithClickedButtonIndex:(int)index {
    if (delegate != NULL) {
        [delegate customIOS7dialogButtonTouchUpInside:self clickedButtonAtIndex:index];
    }

    if (onButtonTouchUpInside != NULL) {
        onButtonTouchUpInside(self, index);
    }
}

// Dialog close animation then cleaning and removing the view from the parent
- (void)close {
    CATransform3D currentTransform = dialogView.layer.transform;

    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        CGFloat startRotation = [[dialogView valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
        CATransform3D rotation = CATransform3DMakeRotation(-startRotation + M_PI * 270.0 / 180.0, 0.0f, 0.0f, 0.0f);

        dialogView.layer.transform = CATransform3DConcat(rotation, CATransform3DMakeScale(1, 1, 1));
    }

    dialogView.layer.opacity = 1.0f;

    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.2f
        delay:0.0
        options:UIViewAnimationOptionTransitionNone
        animations:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.dialogView.layer.transform =
                CATransform3DConcat(currentTransform, CATransform3DMakeScale(0.6f, 0.6f, 1.0));
            strongSelf.dialogView.layer.opacity = 0.0f;
        }
        completion:^(BOOL finished) {
            for (UIView *v in [weakSelf subviews]) {
                [v removeFromSuperview];
            }
            [weakSelf removeFromSuperview];
        }];
}

#pragma mark - Private Methods
// Default button behaviour
- (void)customIOS7dialogButtonTouchUpInside:(RCCustomIOSAlertView *)alertView
                       clickedButtonAtIndex:(NSInteger)buttonIndex {
    DebugLog(@"Button Clicked! %d, %d", (int)buttonIndex, (int)[alertView tag]);
    [self close];
}

- (void)setSubView:(UIView *)subView {
    containerView = subView;
}

// Creates the container view here: create the dialog, then add the custom content and buttons
- (UIView *)createContainerView {
    if (containerView == NULL) {
        containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 150)];
    }

    CGSize screenSize = [self countScreenSize];
    CGSize dialogSize = [self countDialogSize];

    // For the black background
    [self setFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];

    // This is the dialog's container; we attach the custom content and the buttons to this one
    UIView *dialogContainer = [[UIView alloc]
        initWithFrame:CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - dialogSize.height) / 2,
                                 dialogSize.width, dialogSize.height)];

    // First, we style the dialog to match the iOS7 UIAlertView >>>
    dialogContainer.backgroundColor = [RCKitUtility
        generateDynamicColor:[UIColor colorWithRed:233.0 / 255.0 green:233.0 / 255.0 blue:233.0 / 255.0 alpha:1.0f]
                   darkColor:[HEXCOLOR(0x000000) colorWithAlphaComponent:0.8]];
    dialogContainer.layer.masksToBounds = YES;
    dialogContainer.layer.cornerRadius = 10;
    // There is a line above the button
    UIView *lineView = [[UIView alloc]
        initWithFrame:CGRectMake(0, dialogContainer.bounds.size.height - rcButtonHeight - rcButtonSpacerHeight,
                                 dialogContainer.bounds.size.width, rcButtonSpacerHeight)];
    lineView.backgroundColor = [RCKitUtility
        generateDynamicColor:[UIColor colorWithRed:198.0 / 255.0 green:198.0 / 255.0 blue:198.0 / 255.0 alpha:1.0f]
                   darkColor:HEXCOLOR(0x3a3a3a)];
    [dialogContainer addSubview:lineView];
    // ^^^

    // Add the custom container if there is any
    [dialogContainer addSubview:containerView];

    // Add the buttons too
    [self addButtonsToView:dialogContainer];

    return dialogContainer;
}

// Helper function: add buttons to container
- (void)addButtonsToView:(UIView *)container {
    if (buttonTitles == NULL) {
        return;
    }

    CGFloat buttonWidth = container.bounds.size.width / [buttonTitles count];

    for (int i = 0; i < [buttonTitles count]; i++) {

        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];

        [closeButton setFrame:CGRectMake(i * buttonWidth, container.bounds.size.height - rcButtonHeight, buttonWidth,
                                         rcButtonHeight)];

        [closeButton addTarget:self
                        action:@selector(customIOS7dialogButtonTouchUpInside:)
              forControlEvents:UIControlEventTouchUpInside];
        [closeButton setTag:i];

        [closeButton setTitle:[buttonTitles objectAtIndex:i] forState:UIControlStateNormal];
        [closeButton
            setTitleColor:[RCKitUtility generateDynamicColor:[UIColor colorWithRed:0.0f green:0.5f blue:1.0f alpha:1.0f]
                                                   darkColor:HEXCOLOR(0x007acc)]
                 forState:UIControlStateNormal];
        [closeButton
            setTitleColor:[RCKitUtility generateDynamicColor:[UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:0.5f]
                                                   darkColor:HEXCOLOR(0x007acc)]
                 forState:UIControlStateHighlighted];
        [closeButton.titleLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
        [closeButton.layer setCornerRadius:kRCCustomIOSAlertViewCornerRadius];

        [container addSubview:closeButton];
        if (i == [buttonTitles count] - 1) {
            UIView *line =
                [[UIView alloc] initWithFrame:CGRectMake(i * buttonWidth, container.bounds.size.height - rcButtonHeight,
                                                         1, rcButtonHeight)];
            line.backgroundColor = [RCKitUtility generateDynamicColor:[UIColor colorWithRed:198.0 / 255.0
                                                                                      green:198.0 / 255.0
                                                                                       blue:198.0 / 255.0
                                                                                      alpha:1.0f]
                                                            darkColor:HEXCOLOR(0x3a3a3a)];
            [container addSubview:line];
        }
    }
}

// Helper function: count and return the dialog's size
- (CGSize)countDialogSize {
    CGFloat dialogWidth = containerView.frame.size.width;
    CGFloat dialogHeight = containerView.frame.size.height + rcButtonHeight + rcButtonSpacerHeight;

    return CGSizeMake(dialogWidth, dialogHeight);
}

// Helper function: count and return the screen's size
- (CGSize)countScreenSize {
    if (buttonTitles != NULL && [buttonTitles count] > 0) {
        rcButtonHeight = kRCCustomIOSAlertViewDefaultButtonHeight;
        rcButtonSpacerHeight = kRCCustomIOSAlertViewDefaultButtonSpacerHeight;
    } else {
        rcButtonHeight = 0;
        rcButtonSpacerHeight = 0;
    }

    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;

    // On iOS7, screen width and height doesn't automatically follow orientation
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            CGFloat tmp = screenWidth;
            screenWidth = screenHeight;
            screenHeight = tmp;
        }
    }

    return CGSizeMake(screenWidth, screenHeight);
}

#if (defined(__IPHONE_7_0))
// Add motion effects
- (void)applyMotionEffects {

    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        return;
    }

    UIInterpolatingMotionEffect *horizontalEffect =
        [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                        type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalEffect.minimumRelativeValue = @(-kCustomIOS7MotionEffectExtent);
    horizontalEffect.maximumRelativeValue = @(kCustomIOS7MotionEffectExtent);

    UIInterpolatingMotionEffect *verticalEffect =
        [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                        type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalEffect.minimumRelativeValue = @(-kCustomIOS7MotionEffectExtent);
    verticalEffect.maximumRelativeValue = @(kCustomIOS7MotionEffectExtent);

    UIMotionEffectGroup *motionEffectGroup = [[UIMotionEffectGroup alloc] init];
    motionEffectGroup.motionEffects = @[ horizontalEffect, verticalEffect ];

    [dialogView addMotionEffect:motionEffectGroup];
}
#endif

// Rotation changed, on iOS7
- (void)changeOrientationForIOS7 {

    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];

    CGFloat startRotation = [[self valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
    CGAffineTransform rotation;

    switch (interfaceOrientation) {
    case UIInterfaceOrientationLandscapeLeft:
        rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 270.0 / 180.0);
        break;

    case UIInterfaceOrientationLandscapeRight:
        rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 90.0 / 180.0);
        break;

    case UIInterfaceOrientationPortraitUpsideDown:
        rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 180.0 / 180.0);
        break;

    default:
        rotation = CGAffineTransformMakeRotation(-startRotation + 0.0);
        break;
    }

    [UIView animateWithDuration:0.2f
                          delay:0.0
                        options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         dialogView.transform = rotation;

                     }
                     completion:nil];
}

// Rotation changed, on iOS8
- (void)changeOrientationForIOS8:(NSNotification *)notification {

    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;

    [UIView animateWithDuration:0.2f
                          delay:0.0
                        options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         CGSize dialogSize = [self countDialogSize];
                         CGSize keyboardSize =
                             [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
                         self.frame = CGRectMake(0, 0, screenWidth, screenHeight);
                         dialogView.frame = CGRectMake((screenWidth - dialogSize.width) / 2,
                                                       (screenHeight - keyboardSize.height - dialogSize.height) / 2,
                                                       dialogSize.width, dialogSize.height);
                     }
                     completion:nil];
}

// Handle device orientation changes
- (void)deviceOrientationDidChange:(NSNotification *)notification {
    // If dialog is attached to the parent view, it probably wants to handle the orientation change itself
    if (parentView != NULL) {
        return;
    }

    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        [self changeOrientationForIOS7];
    } else {
        [self changeOrientationForIOS8:notification];
    }
}

#pragma mark - Notification Action

// Handle keyboard show/hide changes
- (void)keyboardWillShow:(NSNotification *)notification {
    CGSize screenSize = [self countScreenSize];
    CGSize dialogSize = [self countDialogSize];
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation) &&
        NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) {
        CGFloat tmp = keyboardSize.height;
        keyboardSize.height = keyboardSize.width;
        keyboardSize.width = tmp;
    }

    [UIView animateWithDuration:0.2f
                          delay:0.0
                        options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         dialogView.frame =
                             CGRectMake((screenSize.width - dialogSize.width) / 2,
                                        (screenSize.height - keyboardSize.height - dialogSize.height) / 2,
                                        dialogSize.width, dialogSize.height);
                     }
                     completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    CGSize screenSize = [self countScreenSize];
    CGSize dialogSize = [self countDialogSize];

    [UIView animateWithDuration:0.2f
                          delay:0.0
                        options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         dialogView.frame = CGRectMake((screenSize.width - dialogSize.width) / 2,
                                                       (screenSize.height - dialogSize.height) / 2, dialogSize.width,
                                                       dialogSize.height);
                     }
                     completion:nil];
}

@end
