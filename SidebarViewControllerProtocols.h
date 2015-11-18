//
//  SidebarViewControllerProtocols.h
//  SidebarViewController
//
//  Created by Ken M. Haggerty on 11/6/15.
//  Copyright © 2015 Eureka Valley Co. All rights reserved.
//

#pragma mark - // NOTES (Public) //

#pragma mark - // IMPORTS (Public) //

#import <UIKit/UIKit.h>

#pragma mark - // PROTOCOLS //

@protocol SidebarMainViewControllerProtocol <NSObject>
@optional
- (void)addPanGestureRecognizerWithTarget:(id)target action:(SEL)action delegate:(id <UIGestureRecognizerDelegate>)delegate;
- (void)removePanGestureRecognizerWithTarget:(id)target action:(SEL)action;
@end

@protocol SidebarSideViewControllerProtocol <NSObject>
@optional

@end
