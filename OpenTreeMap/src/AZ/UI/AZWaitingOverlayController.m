// This file is part of the OpenTreeMap code.
//
// OpenTreeMap is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// OpenTreeMap is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with OpenTreeMap.  If not, see <http://www.gnu.org/licenses/>.

#import "AZWaitingOverlayController.h"
#import <QuartzCore/QuartzCore.h>

#define degreesToRadians(x) (M_PI * x / 180.0)

@implementation AZWaitingOverlayController (Private)

- (void)createLoadingView
{
    CGSize loadingSize = CGSizeMake(150, 150);
    waitingView = [[UIView alloc] initWithFrame:CGRectMake(0,0,0,0)];
    waitingView.backgroundColor = [UIColor clearColor];
    
    // Round corners using CALayer property
    [[waitingView layer] setCornerRadius:10];
    [waitingView setClipsToBounds:YES];
    
    // Create colored border using CALayer property
    [[waitingView layer] setBorderColor:[[UIColor whiteColor] CGColor]];
    [[waitingView layer] setBorderWidth:2.75];
    
    //create the semi-transparent view
    CGRect transparentViewFrame = CGRectMake(0, 0, loadingSize.width, loadingSize.height );
    UIView* transparentView = [[UIView alloc] initWithFrame:transparentViewFrame ];
    transparentView.backgroundColor = [UIColor blackColor];
    transparentView.alpha = 0.75;
    
    [waitingView addSubview:transparentView];
    
    //create the activity indicator
    UIActivityIndicatorView* loadingIcon = [[UIActivityIndicatorView alloc] 
                                            initWithActivityIndicatorStyle:
                                            UIActivityIndicatorViewStyleWhiteLarge];
    [loadingIcon startAnimating];
    //Set the frame for the indicator
    CGRect liFrame = loadingIcon.frame;
    CGRect loadingIconFrame = CGRectMake(loadingSize.width/2 - liFrame.size.width/2,
                                         loadingSize.height/2 - 20 - liFrame.size.height/2,
                                         liFrame.size.width, liFrame.size.height );
    loadingIcon.frame = loadingIconFrame;
    [waitingView addSubview:loadingIcon];
    
    //Create the text to place in the loading view
    CGRect labelFrame = CGRectMake( 10, loadingSize.height - 80, loadingSize.width - 20, 55 );
    titleLabel = [[UILabel alloc] initWithFrame:labelFrame];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = UITextAlignmentCenter;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:50];
    titleLabel.adjustsFontSizeToFitWidth = YES;  
    [waitingView addSubview:titleLabel];
    
    //create the view to dim the screen
    dimView = [[UIView alloc] initWithFrame:CGRectMake(0,0,0,0)];
    dimView.backgroundColor = [UIColor blackColor];
    dimView.alpha = 0.25;
}

- (void)rotateWaitingView
{
    //Detecting and handling orientation
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    CGAffineTransform rotationTransform = CGAffineTransformIdentity;
    if ( orientation == UIDeviceOrientationLandscapeLeft )
        rotationTransform = CGAffineTransformRotate(rotationTransform, degreesToRadians(90));
    else if( orientation == UIDeviceOrientationLandscapeRight )
        rotationTransform = CGAffineTransformRotate(rotationTransform, degreesToRadians(-90));
    else if( orientation == UIDeviceOrientationPortraitUpsideDown )
        rotationTransform = CGAffineTransformRotate(rotationTransform, degreesToRadians(180));
    
    [self animateWaitingViewRotation:rotationTransform];
}

- (void)animateWaitingViewRotation:(CGAffineTransform)transform
{
    [UIView beginAnimations:@"swing" context:(void *)waitingView];
    [UIView setAnimationDuration:0.10];
    
    waitingView.transform = transform;
    
    [UIView commitAnimations];
}

@end

@implementation AZWaitingOverlayController

+ (id)sharedController
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (id)init 
{
    self = [super init];
    if (self) {
        [self createLoadingView];
    }
    return self;
}

- (void)showOverlay
{
    [self showOverlayWithTitle:kWaitingOverlayControllerDefaultOverlayTitle];
}

- (void)showOverlayWithTitle:(NSString*)title
{
    CGRect appFrame = [[UIScreen mainScreen] bounds];

    CGSize loadingSize = CGSizeMake(150, 150);
    CGRect loadingFrame = CGRectMake(appFrame.size.width/2 - loadingSize.width/2, 
                                     appFrame.size.height/2 - loadingSize.height/2, 
                                     loadingSize.width, loadingSize.height );
    waitingView.frame = loadingFrame;
    titleLabel.text = title;
    
    CGRect dimViewFrame = CGRectMake(0, 0, appFrame.size.width, appFrame.size.height);
    dimView.frame = dimViewFrame;
    
    [self rotateWaitingView];
    
    [[[UIApplication sharedApplication] keyWindow] addSubview:dimView];
    [[[UIApplication sharedApplication] keyWindow] addSubview:waitingView];
}

- (void) hideOverlay
{
    [waitingView removeFromSuperview];
    [dimView removeFromSuperview];
    
    CGAffineTransform rotationTransform = CGAffineTransformIdentity;
    rotationTransform = CGAffineTransformRotate(rotationTransform, degreesToRadians(0));
    waitingView.transform = rotationTransform;
}

@end
