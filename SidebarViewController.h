//
//  SidebarViewController.h
//  SidebarViewController
//
//  Created by Ken M. Haggerty on 11/5/15.
//  Copyright © 2015 Eureka Valley Co. All rights reserved.
//

#pragma mark - // NOTES (Public) //

#pragma mark - // IMPORTS (Public) //

#import <UIKit/UIKit.h>
#import "SidebarViewControllerProtocols.h"

#pragma mark - // PROTOCOLS //

#pragma mark - // DEFINITIONS (Public) //

@interface SidebarViewController : UIViewController
@property (nonatomic, strong) IBOutlet UIViewController <SidebarMainViewControllerProtocol> *mainViewController;
@property (nonatomic, strong) IBOutlet UIViewController <SidebarSideViewControllerProtocol> *sideViewController;
- (void)setMainViewOffsetPortrait:(CGFloat)offset;
- (void)setMainViewOffsetLandscape:(CGFloat)offset;
- (void)setMainViewBouncesOnOvershoot:(BOOL)bounces;
- (void)setMainViewBouncesOnUndershoot:(BOOL)bounces;
- (void)setMainViewOpen:(BOOL)open animated:(BOOL)animated;
@end
