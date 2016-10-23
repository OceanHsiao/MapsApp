//
//  ViewController.m
//  MapsApp
//
//  Created by Ocean on 2016-10-21.
//  Copyright © 2016 Ocean. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "MKMapView+ZoomLevel.h"
@import GoogleMaps;

typedef enum : NSUInteger {
  enumGoogleMap,
  enumMapKit
} enumMapType;

@interface ViewController () <CLLocationManagerDelegate>

@end

@implementation ViewController {
  GMSMapView *_googlemapView;
  CLLocationManager *_locationManager;
  CLLocation *_currentLocation;
  MKCoordinateRegion _region;
  enumMapType _currentMapType;
  NSMutableArray *_googleMapMarkers; // To record GoogleMap markers' locations(CLLocation)
  NSMutableArray *_mapKitAnnotations;// To record MapKit annotations' locations(CLLocation)
}

@synthesize mapKitView = _mapKitView,
lblChosenMap = _lblChosenMap,
viewGoogleMap = _viewGoogleMap,
switchChangeMap = _switchChangeMap;

- (void)viewDidLoad {
  [super viewDidLoad];
  _googleMapMarkers = [[NSMutableArray alloc] init];
  _mapKitAnnotations = [[NSMutableArray alloc] init];
  
  [self initUI];
}

- (void)viewDidAppear:(BOOL)animated {
  /*** Set Switch controller trigger method ***/
  [_switchChangeMap addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
  
  /*** Init location manager for current location Authorization and updating ***/
  if (nil == _locationManager)
    _locationManager = [[CLLocationManager alloc] init];
  _locationManager.delegate = self;
  _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
  _locationManager.distanceFilter = kCLDistanceFilterNone;
  
  [self checkLocationAuthorization]; //Check getting current location authorization (in iOS8)
  
  [_locationManager startUpdatingLocation];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void) initUI {
  _lblChosenMap.text = @"MapKit";
  _navigationBar.topItem.title = @"MapKit";
  
  _currentMapType = enumMapKit;
  
  /*** Google Map ***/
  _googlemapView = [GMSMapView mapWithFrame:_viewGoogleMap.bounds camera:[GMSCameraPosition alloc]];
  _googlemapView.myLocationEnabled = YES;
  
  [_viewGoogleMap addSubview:_googlemapView];
  _viewGoogleMap.hidden = YES;
  
  /*** MapKit ***/
  _mapKitView.showsUserLocation = YES;
  [_mapKitView setCenterCoordinate:_mapKitView.userLocation.location.coordinate animated:YES];
}

- (IBAction)zoomIn:(id)sender {
  
  switch (_currentMapType) {
    case enumGoogleMap: {
      GMSCameraUpdate *cameraUpdate = [GMSCameraUpdate zoomIn];
      [_googlemapView animateWithCameraUpdate:cameraUpdate];
    }
      break;
    case enumMapKit: {
      MKCoordinateSpan span;
      _region.center = _mapKitView.region.center;
      
      span.latitudeDelta = _mapKitView.region.span.latitudeDelta /4;
      span.longitudeDelta = _mapKitView.region.span.longitudeDelta /4;
      _region.span=span;
      
      [_mapKitView setRegion:_region animated:YES];
    }
      break;
    default:
      break;
  }
}

- (IBAction)zoomOut:(id)sender {
  switch (_currentMapType) {
    case enumGoogleMap: {
      GMSCameraUpdate *cameraUpdate = [GMSCameraUpdate zoomOut];
      [_googlemapView animateWithCameraUpdate:cameraUpdate];
    }
      break;
    case enumMapKit: {
      MKCoordinateSpan span;
      _region.center = _mapKitView.region.center;
      
      span.latitudeDelta = _mapKitView.region.span.latitudeDelta * 4;
      span.longitudeDelta = _mapKitView.region.span.longitudeDelta * 4;
      _region.span=span;
      
      [_mapKitView setRegion:_region animated:YES];
    }
      break;
    default:
      break;
  }
}

- (IBAction)addTag:(id)sender {
  switch (_currentMapType) {
    case enumGoogleMap: {
      NSInteger makersCount = _googleMapMarkers.count;  //Get the numbers of markers in map
      
      //Get current location and set a marker including its title and snippet
      GMSMarker *marker = [[GMSMarker alloc] init];
      marker.position = CLLocationCoordinate2DMake(_currentLocation.coordinate.latitude,
                                                   _currentLocation.coordinate.longitude);
      marker.title = [NSString stringWithFormat:@"GoogleMap Tag %li", (long)makersCount + 1];
      marker.snippet = [NSString stringWithFormat:@"Tag at location (%f, %f)",
                        _currentLocation.coordinate.latitude, _currentLocation.coordinate.longitude];
      marker.map = _googlemapView;
      
      //Add tag location to array
      CLLocation *tagLocation = [[CLLocation alloc] initWithLatitude:_currentLocation.coordinate.latitude
                                                           longitude:_currentLocation.coordinate.longitude];
      [_googleMapMarkers addObject:tagLocation];
    }
      break;
    case enumMapKit: {
      //You also can use [_mapKitView.annotations count] to get the numbers of annotations
      NSInteger annotationsCount = [_mapKitAnnotations count]; //Get the numbers of annotations in map
      
      //Get current location and set an Annotation including its title and subtitle
      MKPointAnnotation *pointAnnotation = [[MKPointAnnotation alloc] init];
      pointAnnotation.coordinate = CLLocationCoordinate2DMake(_currentLocation.coordinate.latitude,
                                                              _currentLocation.coordinate.longitude);
      pointAnnotation.title = [NSString stringWithFormat:@"MapKit Tag %li", (long)annotationsCount + 1];
      pointAnnotation.subtitle = [NSString stringWithFormat:@"Tag at location (%f, %f)",
                                  _currentLocation.coordinate.latitude, _currentLocation.coordinate.longitude];
      
      [_mapKitView addAnnotation:pointAnnotation];
      
      //Add tag location to array
      CLLocation *tagLocation = [[CLLocation alloc] initWithLatitude:_currentLocation.coordinate.latitude
                                                           longitude:_currentLocation.coordinate.longitude];
      [_mapKitAnnotations addObject:tagLocation];
    }
      break;
    default:
      break;
  }
}

- (void)switchValueChanged:(UISwitch *)theSwitch {
  
  if ([_lblChosenMap.text isEqualToString:@"MapKit"]) {
    _lblChosenMap.text = @"GoogleMap";
    _navigationBar.topItem.title = @"GoogleMap";;
    _mapKitView.hidden = YES;
    _viewGoogleMap.hidden = NO;
    _currentMapType = enumGoogleMap;
  } else {
    _lblChosenMap.text = @"MapKit";
    _navigationBar.topItem.title = @"MapKit";
    _viewGoogleMap.hidden = YES;
    _mapKitView.hidden = NO;
    _currentMapType = enumMapKit;
  }
}

- (void)checkLocationAuthorization {
  CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
  
  if (status == kCLAuthorizationStatusDenied) {
    NSString *title;
    title = (status == kCLAuthorizationStatusDenied) ? @"Location services are off" : @"Background location is not enabled";
    NSString *message = @"To use background location you must turn on 'Always' or 'While Using the App' in the Location Services Settings";
    
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"Cancel"
                                style:UIAlertActionStyleDefault
                                handler:nil];
    
    UIAlertAction* noButton = [UIAlertAction
                               actionWithTitle:@"Settings"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                 /*** Go to Settings lets user set location authorization
                                  Remember that you should add NSLocationAlwaysUsageDescription and NSLocationWhenInUseUsageDescription in Info.plist.
                                  So that App Settings would show 'Always' and 'While Using the App' options.
                                  ***/
                                 NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                 [[UIApplication sharedApplication] openURL:settingsURL];
                               }];
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    
    [self presentViewController:alert animated:NO completion:nil];
  }
  else if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
    [_locationManager requestWhenInUseAuthorization];
  }
  else if (status == kCLAuthorizationStatusAuthorizedAlways) {
    [_locationManager requestAlwaysAuthorization];
  }
}

#pragma CLLocationManagerDelegate delegate
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
  
  //Do this for allowing maps would zoom in to current location
  if (_currentLocation == nil) {
    _currentLocation = [locations lastObject];
    
    /*** GoogleMap camera setting ***/
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:_currentLocation.coordinate.latitude
                                                            longitude:_currentLocation.coordinate.longitude
                                                                 zoom:11];
    [_googlemapView setCamera:camera];
    
    /*** MapKit camera setting ***/
    CLLocationCoordinate2D centerCoord = { _currentLocation.coordinate.latitude, _currentLocation.coordinate.longitude };
    [_mapKitView setCenterCoordinate:centerCoord zoomLevel:10 animated:YES];
    
  }
  
  _currentLocation = [locations lastObject];
  
  //--- display latitude ---
  NSString *lat = [[NSString alloc] initWithFormat:@"%f", _currentLocation.coordinate.latitude];
  
  //--- display longitude ---
  NSString *lng = [[NSString alloc] initWithFormat:@"%f", _currentLocation.coordinate.longitude];
  
  //--- display accuracy ---
  NSString *acc = [[NSString alloc] initWithFormat:@"%f", _currentLocation.horizontalAccuracy];
  
  NSLog(@"lat:%@  ;  lng:%@  ;  acc:%@", lat, lng, acc);
  
}

@end
