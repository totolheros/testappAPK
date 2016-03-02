//
//  ViewController.h
//  Siberian Angular
//
//  Created by Adrien Sala on 08/07/2014.
//  Copyright (c) 2014 Adrien Sala. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AddressBook/AddressBook.h>
#import "RNCachingURLProtocol.h"
#import "webViewController.h"
#import "musicViewController.h"
#import "Contact.h"
#import "SocialSharing.h"
#import "common.h"
#import "ZBarSDK.h"

@interface ViewController : UIViewController <UIWebViewDelegate, webViewControllerDelegate, audioPlayerDelegate, socialSharingDelegate, CLLocationManagerDelegate, ContactDelegate, ZBarReaderDelegate, UIAlertViewDelegate> {
    BOOL webViewIsLoaded;
    NSString *appFirstRunning;
    NSURL *webviewUrl;
    CLLocationManager *locationManager;
    AudioPlayer *audioPlayer;
}

@property (strong, nonatomic) NSDictionary *scanProtocols;
@property (strong, nonatomic) NSDictionary *audioPlayerData;
@property (strong, nonatomic) NSString *scanContent;

@property (strong, nonatomic) IBOutlet UIView *remotePlayerView;
@property (strong, nonatomic) IBOutlet UIButton *audioTitle;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *btnPrevious;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *btnPlayPause;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *btnNext;
@property (strong, nonatomic) IBOutlet UISlider *progressBar;

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (strong, nonatomic) IBOutlet loaderView *loader;

@property (strong, nonatomic) UIImageView *splashScreen;
@property (strong, nonatomic) UIImage *splashScreenImage;

- (void)saveCookies;
- (void)loadCookies;

/** audioPlayer **/
- (IBAction)maximizeAudioPlayer:(id)sender;
- (IBAction)playPrevious:(id)sender;
- (IBAction)playOrPause:(id)sender;
- (IBAction)playNext:(id)sender;
- (IBAction)progressBarChanged:(id)sender;
/** /audioPlayer **/

@end
