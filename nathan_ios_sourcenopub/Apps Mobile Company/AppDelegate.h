//
//  AppDelegate.h
//  Siberian Angular
//
//  Created by Adrien Sala on 08/07/2014.
//  Copyright (c) 2014 Adrien Sala. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
// #import "EVURLCache.h"
#import "ViewController.h"
#import "RNCachingURLProtocol.h"
#import "Url.h"
#import "request.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate, Request> {
    CLLocationManager *locationManager;
}

@property (strong, nonatomic) UIWindow *window;

@end
