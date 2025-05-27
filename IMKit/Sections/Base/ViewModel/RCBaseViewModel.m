//
//  RCBaseViewModel.m
//  Pods-RCUserProfile_Example
//
//  Created by RobinCui on 2024/8/15.
//

#import "RCBaseViewModel.h"
#import "RCViewModelAdapterCenter.h"

@interface RCBaseViewModel () {
    id __weak _delegate;
}
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

@end
