//                                                                                                                
// Copyright (c) 2012 Azavea                                                                                
//                                                                                                                
// Permission is hereby granted, free of charge, to any person obtaining a copy                                   
// of this software and associated documentation files (the "Software"), to                                       
// deal in the Software without restriction, including without limitation the                                     
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or                                    
//  sell copies of the Software, and to permit persons to whom the Software is                                    
// furnished to do so, subject to the following conditions:                                                       
//                                                                                                                
// The above copyright notice and this permission notice shall be included in                                     
// all copies or substantial portions of the Software.                                                            
//                                                                                                                
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR                                     
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,                                       
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE                                    
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER                                         
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,                                  
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN                                      
// THE SOFTWARE.                                                                                                  
//  

#import "OTMMapViewController.h"
#import "AZWMSOverlay.h"
#import "AZPointOffsetOverlay.h"
#import "OTMEnvironment.h"
#import "OTMAPI.h"
#import "OTMTreeDetailViewController.h"

@interface OTMMapViewController ()
- (void)setupMapView;

-(void)slideDetailUpAnimated:(BOOL)anim;
-(void)slideDetailDownAnimated:(BOOL)anim;
/**
 Append single-tap recognizer to the view that calls handleSingleTapGesture:
 */
- (void)addGestureRecognizersToView:(UIView *)view;
@end

@implementation OTMMapViewController

@synthesize lastClickedTree, detailView, treeImage, dbh, species, address, detailsVisible, selectedPlot;

- (void)viewDidLoad
{
    self.detailsVisible = NO;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch 
                                                                                          target:nil
                                                                                          action:nil];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithTitle:@"Filter"
                                              style:UIBarButtonItemStyleBordered
                                              target:nil
                                              action:nil];
    
    self.title = @"Tree Map";
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatedImage:)
                                                 name:kOTMMapViewControllerImageUpdate
                                               object:nil];    
    
    [super viewDidLoad];
    [self slideDetailDownAnimated:NO];
     
    [self setupMapView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kOTMMapViewControllerImageUpdate
                                                  object:nil];
}

-(void)updatedImage:(NSNotification *)note {
    self.treeImage.image = note.object;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender 
{
    if ([segue.identifier isEqualToString:@"Details"]) {
        OTMTreeDetailViewController *dest = segue.destinationViewController;
        [dest view]; // Force it load its view
        
        dest.data = self.selectedPlot;
        dest.keys = [NSArray arrayWithObjects:
                     [NSArray arrayWithObjects:
                      @"General Tree Information",
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       @"id", @"key",
                       @"Tree Number", @"label", nil],
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       @"tree.sci_name", @"key",
                       @"Scientific Name", @"label", nil],                      
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       @"tree.dbh", @"key",
                       @"Trunk Diameter", @"label", 
                       @"fmtIn:", @"format",  
                       [NSNumber numberWithBool:YES], @"editable", nil],
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       @"tree.height", @"key",
                       @"Tree Height", @"label",
                       @"fmtM:", @"format",  
                       [NSNumber numberWithBool:YES], @"editable", nil],
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       @"tree.canopy_height", @"key",
                       @"Canopy Height", @"label", 
                       @"fmtM:", @"format", 
                       [NSNumber numberWithBool:YES], @"editable", nil],
                      nil],
                     nil];
        
        dest.imageView.image = self.treeImage.image;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark Detail View

-(void)setDetailViewData:(NSDictionary*)plot {
    NSString* tdbh = nil;
    NSString* tspecies = nil;
    NSString* taddress = nil;
    
    NSDictionary* tree;
    if ((tree = [plot objectForKey:@"tree"]) && [tree isKindOfClass:[NSDictionary class]]) {
        NSString* dbhValue = [tree objectForKey:@"dbh"];
        
        if (dbhValue != nil && ![[NSString stringWithFormat:@"%@", dbhValue] isEqualToString:@"<null>"]) {
            tdbh =  [NSString stringWithFormat:@"%@", dbhValue];   
        }
        
        tspecies = [NSString stringWithFormat:@"%@",[tree objectForKey:@"species_name"]];
    }
    
    taddress = [plot objectForKey:@"address"];
    
    if (tdbh == nil || tdbh == @"<null>") { tdbh = @"Diameter"; }
    if (tspecies == nil || tspecies == @"<null>") { tspecies = @"Species"; }
    if (taddress == nil || taddress == @"<null>") { taddress = @"Address"; }
    
    [self.dbh setText:tdbh];
    [self.species setText:tspecies];
    [self.address setText:taddress];
}

-(void)slideDetailUpAnimated:(BOOL)anim {
    if (anim) {
        [UIView beginAnimations:@"slidedetailup" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:0.2];
    }
    
    [self.detailView setFrame:
        CGRectMake(0,
                   self.view.bounds.size.height - self.detailView.frame.size.height,
                   self.view.bounds.size.width, 
                   self.detailView.frame.size.height)];
    
    self.detailsVisible = YES;
    
    if (anim) {
        [UIView commitAnimations];
    }
}

-(void)slideDetailDownAnimated:(BOOL)anim {
    if (anim) {
        [UIView beginAnimations:@"slidedetaildown" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDuration:0.2];
    }    
    
    [self.detailView setFrame:
     CGRectMake(0,
                self.view.bounds.size.height,
                self.view.bounds.size.width, 
                self.detailView.frame.size.height)];
    
    self.detailsVisible = NO;
    
    if (anim) {
        [UIView commitAnimations];
    }
}

#pragma mark Map view setup

- (void)setupMapView
{
    OTMEnvironment *env = [OTMEnvironment sharedEnvironment];

    MKCoordinateRegion region = [env mapViewInitialCoordinateRegion];
    [mapView setRegion:region animated:FALSE];
    [mapView regionThatFits:region];
    [mapView setDelegate:self];
    [self addGestureRecognizersToView:mapView];

    AZWMSOverlay *overlay = [[AZWMSOverlay alloc] init];

    [overlay setServiceUrl:[env geoServerWMSServiceURL]];
    [overlay setLayerNames:[env geoServerLayerNames]];
    [overlay setFormat:[env geoServerFormat]];

    [mapView addOverlay:overlay];
}

- (void)addGestureRecognizersToView:(UIView *)view
{
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapGesture:)];
    singleTapRecognizer.numberOfTapsRequired = 1;
    singleTapRecognizer.numberOfTouchesRequired = 1;
    [view addGestureRecognizer:singleTapRecognizer];

    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] init];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    doubleTapRecognizer.numberOfTouchesRequired = 1;

    // In order to pass double-taps to the underlying MKMapView the delegate for this recognizer (self) needs
    // to return YES from gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:
    doubleTapRecognizer.delegate = self;
    [view addGestureRecognizer:doubleTapRecognizer];

    // This prevents delays the single-tap recognizer slightly and ensures that it will _not_ fire if there is
    // a double-tap
    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
}

#pragma mark UIGestureRecognizer handlers

/**
 INCOMPLETE
 Get the latitude and longitude of the point on the map that was touched
 */
- (void)handleSingleTapGesture:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded)
    {
        return;
    }
    CGPoint touchPoint = [gestureRecognizer locationInView:mapView];
    CLLocationCoordinate2D touchMapCoordinate = [mapView convertPoint:touchPoint toCoordinateFromView:mapView];

    [[[OTMEnvironment sharedEnvironment] api] getPlotsNearLatitude:touchMapCoordinate.latitude
                                                         longitude:touchMapCoordinate.longitude
                                                          callback:^(NSArray* plots, NSError* error) 
    {
        if ([plots count] == 0) { // No plots returned
            [self slideDetailDownAnimated:YES];
        } else {            
            NSDictionary* plot = [plots objectAtIndex:0];
            
            self.selectedPlot = [plot mutableDeepCopy];
            
            NSDictionary* geom = [plot objectForKey:@"geometry"];
            
            NSDictionary* tree = [plot objectForKey:@"tree"];
            
            self.treeImage.image = nil;
            
            if (tree && [tree isKindOfClass:[NSDictionary class]]) {
                NSArray* images = [tree objectForKey:@"images"];
                
                if (images && [images isKindOfClass:[NSArray class]] && [images count] > 0) {
                    int imageId = [[[images objectAtIndex:0] objectForKey:@"id"] intValue];
                    int plotId = [[plot objectForKey:@"id"] intValue];
                    
                    [[[OTMEnvironment sharedEnvironment] api] getImageForTree:plotId
                                                                      photoId:imageId
                                                                     callback:^(UIImage* image, NSError* error)
                     {
                         self.treeImage.image = image;
                     }];
                }
            }
            
            [self setDetailViewData:plot];
            [self slideDetailUpAnimated:YES];
            
            double lat = [[geom objectForKey:@"lat"] doubleValue];
            double lon = [[geom objectForKey:@"lng"] doubleValue];
            CLLocationCoordinate2D center = CLLocationCoordinate2DMake(lat, lon);
            MKCoordinateSpan span = [[OTMEnvironment sharedEnvironment] mapViewSearchZoomCoordinateSpan];
            
            [mapView setRegion:MKCoordinateRegionMake(center, span) animated:YES];
            
            if (self.lastClickedTree) {
                [mapView removeAnnotation:self.lastClickedTree];
                self.lastClickedTree = nil;
            }
            
            self.lastClickedTree = [[MKPointAnnotation alloc] init];
            
            [self.lastClickedTree setCoordinate:center];
            
            [mapView addAnnotation:self.lastClickedTree];
            NSLog(@"Here with plot %@", plot); 
        }
    }];
    
    // TODO: Fetch nearest tree for lat lon
    NSLog(@"Touched lat:%f lon:%f",touchMapCoordinate.latitude, touchMapCoordinate.longitude);
}

#pragma mark UIGestureRecognizerDelegate methods

/**
 Asks the delegate if two gesture recognizers should be allowed to recognize gestures simultaneously.
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // Returning YES ensures that double-tap gestures propogate to the MKMapView
    return YES;
}

#pragma mark MKMapViewDelegate

- (void)mapView:(MKMapView*)mView regionDidChangeAnimated:(BOOL)animated {
    MKCoordinateRegion region = [mView region];
    double lngMin = region.center.longitude - region.span.longitudeDelta / 2.0;
    double lngMax = region.center.longitude + region.span.longitudeDelta / 2.0;
    double latMin = region.center.latitude - region.span.latitudeDelta / 2.0;
    double latMax = region.center.latitude + region.span.latitudeDelta / 2.0;
    
    if (self.lastClickedTree) {
        CLLocationCoordinate2D center = self.lastClickedTree.coordinate;
        
        BOOL shouldBeShown = center.longitude >= lngMin && center.longitude <= lngMax &&
                             center.latitude >= latMin && center.latitude <= latMax;

        if (shouldBeShown && !self.detailsVisible) {
            [self slideDetailUpAnimated:YES];
        } else if (!shouldBeShown && self.detailsVisible) {
            [self slideDetailDownAnimated:YES];
        }
    }
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    return [[AZPointOffsetOverlay alloc] initWithOverlay:overlay];
}

#pragma mark UISearchBarDelegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)bar {
    [bar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)bar {
    [bar setText:@""];
    [bar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)bar {
    NSString *searchText = [NSString stringWithFormat:@"%@ %@", [bar text], [[OTMEnvironment sharedEnvironment] searchSuffix]];
    NSString *urlEncodedSearchText = [searchText stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    [[[OTMEnvironment sharedEnvironment] api] geocodeAddress:urlEncodedSearchText
        callback:^(NSArray* matches, NSError* error) {
            if ([matches count] > 0) {
                NSDictionary *firstMatch = [matches objectAtIndex:0];
                double lon = [((NSNumber*)[firstMatch objectForKey:@"x"]) doubleValue];
                double lat = [((NSNumber*)[firstMatch objectForKey:@"y"]) doubleValue];
                CLLocationCoordinate2D center = CLLocationCoordinate2DMake(lat, lon);
                MKCoordinateSpan span = [[OTMEnvironment sharedEnvironment] mapViewSearchZoomCoordinateSpan];
                [mapView setRegion:MKCoordinateRegionMake(center, span) animated:YES];
                [bar setShowsCancelButton:NO animated:YES];
                [bar resignFirstResponder];
            } else {
                NSString *message;
                if (error != nil) {
                    NSLog(@"Error geocoding location: %@", [error description]);
                    message = @"Sorry. There was a problem completing your search.";
                } else {
                    message = @"No Results Found";
                }
                [UIAlertView showAlertWithTitle:nil message:message cancelButtonTitle:@"OK" otherButtonTitle:nil callback:^(UIAlertView *alertView, int btnIdx) {
                    [bar setShowsCancelButton:YES animated:YES];
                    [bar becomeFirstResponder];
                }];
            }
       }];
}


@end