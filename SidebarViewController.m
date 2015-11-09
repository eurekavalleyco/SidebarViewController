//
//  SidebarViewController.m
//  SidebarViewController
//
//  Created by Ken M. Haggerty on 11/5/15.
//  Copyright © 2015 Eureka Valley Co. All rights reserved.
//

#pragma mark - // NOTES (Private) //

#pragma mark - // IMPORTS (Private) //

#import "SidebarViewController.h"
#import "AKDebugger.h"
#import "AKGenerics.h"
#import "CentralDispatch+Delegates.h"
#import "SystemInfo.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark - // DEFINITIONS (Private) //

#define DEFAULT_MAINVIEW_OFFSET_PORTRAIT self.view.frame.size.width*0.75f
#define DEFAULT_MAINVIEW_OFFSET_LANDSCAPE self.view.frame.size.width*0.75f
#define DEFAULT_MAINVIEW_BOUNCES_OVERSHOOT YES
#define DEFAULT_MAINVIEW_BOUNCES_UNDERSHOOT NO

#define ANIMATION_DURATION 0.25f
#define MINIMUM_SPEED 400.0f
#define RUBBER_BANDING 0.33f

#define SHADOW_OPACITY 0.05f
#define SHADOW_COLOR [UIColor blackColor].CGColor
#define SHADOW_RADIUS fminf(self.mainView.frame.size.width, self.mainView.frame.size.height)*0.05f
#define SHADOW_OFFSET CGSizeMake(0.0f, SHADOW_RADIUS*0.33f)

#define SEGUE_MAINVIEW @"embedMainView"
#define SEGUE_SIDEVIEW @"embedSideView"

@interface SidebarViewController () <SidebarDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) IBOutlet UIView *tapView;
@property (nonatomic, strong) IBOutlet UIView *mainView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *constraintMainViewTrailing;
@property (nonatomic, strong) IBOutlet UIView *sideView;
@property (nonatomic) CGFloat mainViewOffset;
@property (nonatomic) CGFloat mainViewOffsetPortrait;
@property (nonatomic) CGFloat mainViewOffsetLandscape;
@property (nonatomic) BOOL mainViewBouncesOnOvershoot;
@property (nonatomic) BOOL mainViewBouncesOnUndershoot;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *secondaryPanGestureRecognizer;
@property (nonatomic) CGPoint touchPoint;

// GENERAL //

- (void)setup;
- (void)teardown;

// OBSERVERS //

- (void)addObserversToSystemInfo;
- (void)removeObserversFromSystemInfo;

// RESPONDERS //

- (void)deviceOrientationDidChange:(NSNotification *)notification;
- (void)mainViewDidPan:(UIPanGestureRecognizer *)panGestureRecognizer;
- (void)mainViewWasTapped:(UITapGestureRecognizer *)tapGestureRecognizer;

// OTHER //

- (void)setTargetMainViewOffset:(CGFloat)offset;

@end

@implementation SidebarViewController

#pragma mark - // SETTERS AND GETTERS //

@synthesize mainViewController = _mainViewController;
@synthesize sideViewController = _sideViewController;
@synthesize tapView = _tapView;
@synthesize mainView = _mainView;
@synthesize constraintMainViewTrailing = _constraintMainViewTrailing;
@synthesize sideView = _sideView;
@synthesize mainViewOffset = _mainViewOffset;
@synthesize mainViewOffsetPortrait = _mainViewOffsetPortrait;
@synthesize mainViewOffsetLandscape = _mainViewOffsetLandscape;
@synthesize mainViewBouncesOnOvershoot = _mainViewBouncesOnOvershoot;
@synthesize mainViewBouncesOnUndershoot = _mainViewBouncesOnUndershoot;
@synthesize panGestureRecognizer = _panGestureRecognizer;
@synthesize tapGestureRecognizer = _tapGestureRecognizer;
@synthesize secondaryPanGestureRecognizer = _secondaryPanGestureRecognizer;
@synthesize touchPoint = _touchPoint;

- (void)setMainViewController:(UIViewController <SidebarMainViewControllerProtocol> *)mainViewController
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetter tags:@[AKD_UI] message:nil];
    
    if ([AKGenerics object:mainViewController isEqualToObject:_mainViewController]) return;
    
    if ([_mainViewController respondsToSelector:@selector(setSidebarPanGestureRecognizer:)]) [_mainViewController setSidebarPanGestureRecognizer:nil];
    
    _mainViewController = mainViewController;
    
    if ([mainViewController respondsToSelector:@selector(setSidebarPanGestureRecognizer:)]) [mainViewController setSidebarPanGestureRecognizer:self.secondaryPanGestureRecognizer];
}

- (void)setMainViewOffsetPortrait:(CGFloat)offset
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetter tags:@[AKD_UI] message:nil];
    
    _mainViewOffsetPortrait = offset;
}

- (void)setMainViewOffsetLandscape:(CGFloat)offset
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetter tags:@[AKD_UI] message:nil];
    
    _mainViewOffsetLandscape = offset;
}

- (void)setMainViewBouncesOnOvershoot:(BOOL)bounces
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetter tags:@[AKD_UI] message:nil];
    
    _mainViewBouncesOnOvershoot = bounces;
}

- (void)setMainViewBouncesOnUndershoot:(BOOL)bounces
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetter tags:@[AKD_UI] message:nil];
    
    _mainViewBouncesOnUndershoot = bounces;
}

- (UIPanGestureRecognizer *)panGestureRecognizer
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_UI] message:nil];
    
    if (_panGestureRecognizer) return _panGestureRecognizer;
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(mainViewDidPan:)];
    [_panGestureRecognizer setDelegate:self];
    return _panGestureRecognizer;
}

- (UITapGestureRecognizer *)tapGestureRecognizer
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_UI] message:nil];
    
    if (_tapGestureRecognizer) return _tapGestureRecognizer;
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mainViewWasTapped:)];
    [_tapGestureRecognizer setDelegate:self];
    return _tapGestureRecognizer;
}

- (UIPanGestureRecognizer *)secondaryPanGestureRecognizer
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_UI] message:nil];
    
    if (_secondaryPanGestureRecognizer) return _secondaryPanGestureRecognizer;
    
    _secondaryPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(mainViewDidPan:)];
    [_secondaryPanGestureRecognizer setDelegate:self];
    return _secondaryPanGestureRecognizer;
}

#pragma mark - // INITS AND LOADS //

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self)
    {
        [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeCritical methodType:AKMethodTypeSetup tags:@[AKD_UI] message:[NSString stringWithFormat:@"%@ is nil", stringFromVariable(self)]];
        return nil;
    }
    
    [self setup];
    return self;
}

- (void)awakeFromNib
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    [super awakeFromNib];
    
    [self setup];
}

- (void)viewDidLoad
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    [super viewDidLoad];
    
    [self.mainView.layer setMasksToBounds:NO];
    [self.mainView.layer setShadowOpacity:SHADOW_OPACITY];
    [self.mainView.layer setShadowColor:SHADOW_COLOR];
    [self.mainView.layer setShadowRadius:SHADOW_RADIUS];
    [self.mainView.layer setShadowOffset:SHADOW_OFFSET];
    [self.mainView.layer setShadowPath:[UIBezierPath bezierPathWithRect:self.mainView.bounds].CGPath];
    
    [self.tapView addGestureRecognizer:self.panGestureRecognizer];
    [self.tapView addGestureRecognizer:self.tapGestureRecognizer];
    [self.tapView setHidden:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    [self teardown];
}

#pragma mark - // PUBLIC METHODS //

- (void)setMainViewOpen:(BOOL)open animated:(BOOL)animated
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_UI] message:nil];
    
    NSTimeInterval animationDuration = 0.0f;
    if (animated)
    {
        if (open) animationDuration = ANIMATION_DURATION*(self.mainViewOffset-self.constraintMainViewTrailing.constant)/self.mainViewOffset;
        else animationDuration = ANIMATION_DURATION*self.constraintMainViewTrailing.constant/self.mainViewOffset;
    }
    CGFloat constant = 0.0f;
    if (open) constant = self.mainViewOffset;
    [self.constraintMainViewTrailing setConstant:constant];
    [self.view setNeedsUpdateConstraints];
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self.tapView setHidden:!open];
    }];
}

#pragma mark - // DELEGATED METHODS (UIGestureRecognizerDelegate) //

#pragma mark - // OVERWRITTEN METHODS //

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    UIViewController *destinationViewController = segue.destinationViewController;
    if ([AKGenerics object:segue.identifier isEqualToObject:SEGUE_MAINVIEW])
    {
        if (![destinationViewController conformsToProtocol:@protocol(SidebarMainViewControllerProtocol)] && [destinationViewController isKindOfClass:[UINavigationController class]])
        {
            destinationViewController = ((UINavigationController *)destinationViewController).visibleViewController;
        }
        if ([destinationViewController conformsToProtocol:@protocol(SidebarMainViewControllerProtocol)])
        {
            [self setMainViewController:(UIViewController <SidebarMainViewControllerProtocol> *)destinationViewController];
        }
    }
    else if ([AKGenerics object:segue.identifier isEqualToObject:SEGUE_SIDEVIEW])
    {
        if (![destinationViewController conformsToProtocol:@protocol(SidebarSideViewControllerProtocol)] && [destinationViewController isKindOfClass:[UINavigationController class]])
        {
            destinationViewController = ((UINavigationController *)destinationViewController).visibleViewController;
        }
        if ([destinationViewController conformsToProtocol:@protocol(SidebarSideViewControllerProtocol)])
        {
            [self setSideViewController:(UIViewController <SidebarSideViewControllerProtocol> *)destinationViewController];
        }
    }
}

- (void)viewWillLayoutSubviews
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    [super viewWillLayoutSubviews];
    
    [self setMainViewOffsetPortrait:DEFAULT_MAINVIEW_OFFSET_PORTRAIT];
    [self setMainViewOffsetLandscape:DEFAULT_MAINVIEW_OFFSET_LANDSCAPE];
    if ([SystemInfo isPortrait]) [self setMainViewOffset:self.mainViewOffsetPortrait];
    else [self setMainViewOffset:self.mainViewOffsetLandscape];
}

- (void)viewDidLayoutSubviews
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    [super viewDidLayoutSubviews];
}

#pragma mark - // PRIVATE METHODS (General) //

- (void)setup
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    [self setMainViewBouncesOnOvershoot:DEFAULT_MAINVIEW_BOUNCES_OVERSHOOT];
    [self setMainViewBouncesOnUndershoot:DEFAULT_MAINVIEW_BOUNCES_UNDERSHOOT];
    
    [self addObserversToSystemInfo];
    
    [CentralDispatch setSidebarDelegate:self];
}

- (void)teardown
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    [self removeObserversFromSystemInfo];
    [self.mainView removeGestureRecognizer:self.panGestureRecognizer];
    if ([self.mainViewController respondsToSelector:@selector(setSidebarPanGestureRecognizer:)])
    {
        [self.mainViewController setSidebarPanGestureRecognizer:self.secondaryPanGestureRecognizer];
    }
}

#pragma mark - // PRIVATE METHODS (Observers) //

- (void)addObserversToSystemInfo
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_NOTIFICATION_CENTER] message:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:NOTIFICATION_DEVICE_ORIENTATION_DID_CHANGE object:nil];
}

- (void)removeObserversFromSystemInfo
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_NOTIFICATION_CENTER] message:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_DEVICE_ORIENTATION_DID_CHANGE object:nil];
}

#pragma mark - // PRIVATE METHODS (Responders) //

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_NOTIFICATION_CENTER, AKD_UI] message:nil];
    
    if ([SystemInfo isPortrait]) [self setMainViewOffset:self.mainViewOffsetPortrait];
    else [self setMainViewOffset:self.mainViewOffsetLandscape];
}

- (void)mainViewDidPan:(UIPanGestureRecognizer *)panGestureRecognizer
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_UI] message:nil];
    
    CGPoint touchPoint = [panGestureRecognizer locationInView:self.view];
    CGFloat offset, velocity;
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateChanged:
            offset = self.touchPoint.x-touchPoint.x;
            [self setTargetMainViewOffset:self.view.frame.size.width/2.0f-self.mainView.center.x+offset];
        case UIGestureRecognizerStateBegan:
            [self setTouchPoint:touchPoint];
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            velocity = -1.0f*[panGestureRecognizer velocityInView:self.view].x;
            if (velocity > MINIMUM_SPEED)
            {
                [self setMainViewOpen:YES animated:YES];
            }
            else if (velocity < -1.0f*MINIMUM_SPEED)
            {
                [self setMainViewOpen:NO animated:YES];
            }
            else
            {
                if (self.constraintMainViewTrailing.constant < self.mainViewOffset*0.5f)
                {
                    [self setMainViewOpen:NO animated:YES];
                }
                else
                {
                    [self setMainViewOpen:YES animated:YES];
                }
            }
            [self setTouchPoint:CGPointZero];
            break;
        default:
            // nothing
            break;
    }
}

- (void)mainViewWasTapped:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_UI] message:nil];
    
    [self setMainViewOpen:NO animated:YES];
}

#pragma mark - // PRIVATE METHODS (Other) //

- (void)setTargetMainViewOffset:(CGFloat)offset
{
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetter tags:@[AKD_UI] message:nil];
    
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeDebug methodType:AKMethodTypeSetter tags:@[AKD_UI] message:[NSString stringWithFormat:@"%@ = %f", stringFromVariable(offset), offset]];
    if (offset < 0.0f)
    {
        if (self.mainViewBouncesOnUndershoot) offset = offset*RUBBER_BANDING+self.constraintMainViewTrailing.constant*(1.0f-RUBBER_BANDING);
        else offset = 0.0f;
    }
    else if (offset > self.mainViewOffset)
    {
        if (self.mainViewBouncesOnOvershoot) offset = offset*RUBBER_BANDING+self.constraintMainViewTrailing.constant*(1.0f-RUBBER_BANDING);
        else offset = self.mainViewOffset;
    }
    [self.constraintMainViewTrailing setConstant:offset];
    [self.mainView setNeedsUpdateConstraints];
    [self.mainView layoutIfNeeded];
}

@end