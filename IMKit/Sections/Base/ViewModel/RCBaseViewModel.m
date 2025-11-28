//
//  RCBaseViewModel.m
//  Pods-RCUserProfile_Example
//
//  Created by RobinCui on 2024/8/15.
//

#import "RCBaseViewModel.h"
#import "RCViewModelAdapterCenter.h"
#import "RCLoadingTipView.h"

@interface RCBaseViewModel () {
    id __weak _delegate;
}
@property (nonatomic, weak) RCLoadingTipView *loadingView;
@end

@implementation RCBaseViewModel


- (id)delegate {
    if (!_delegate) {
        id delegate = [RCViewModelAdapterCenter delegateForViewModelClass:[self class]];
        _delegate = delegate;
    }
    return _delegate;
}

- (void)setDelegate:(id)delegate {
    _delegate = delegate;
}

- (void)loadingWithTip:(NSString *)tip {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.loadingView) {
            [self.loadingView stopLoading];
        }
        self.loadingView = [RCLoadingTipView loadingWithTip:tip];
        [self.loadingView startLoading];
    });
   
}

- (void)stopLoading {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.loadingView stopLoading];
        self.loadingView = nil;
    });
   
}
@end
