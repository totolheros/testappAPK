//
//  ViewController.m
//  Siberian Angular
//
//  Created by Adrien Sala on 08/07/2014.
//  Copyright (c) 2014 Adrien Sala. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize webView, locationManager, loader;
@synthesize splashScreen, splashScreenImage;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionStateDidChange:) name:@"connectionStateDidChange" object:nil];
    
    webViewIsLoaded = NO;
    
    [self addSplashScreen];
    
    // Créé et affiche le loader
    CGRect frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    loader = [[loaderView alloc] initWithFrame:frame];
    // Ajoute le loader à la vue en cours
    [self.view addSubview:loader];
    [self.view bringSubviewToFront:loader];
    [loader show];

    NSUserDefaults *dict = [NSUserDefaults standardUserDefaults];
    appFirstRunning = [dict stringForKey:@"appFirstRunning"];
    NSLog(@"appFirstRunning: %@", appFirstRunning);
    if(![appFirstRunning isEqualToString:@"false"]) {
        [dict setObject:@"false" forKey:@"appFirstRunning"];
        [dict synchronize];
    }

    webView.delegate = self;
    webView.scrollView.bounces = NO;
    
    [self loadWebview];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGRect loaderFrame, splashScreenFrame;
    if(UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        float splashScreenFrameHeight = screenBounds.size.height * splashScreen.frame.size.height / splashScreen.frame.size.width;
        float splashScreenFrameY = -(splashScreen.frame.size.height / 4);
        splashScreenFrame = CGRectMake(0, isAtLeastiOS7()?splashScreenFrameY:splashScreenFrameY-19, screenBounds.size.height, splashScreenFrameHeight);
        loaderFrame = CGRectMake(loader.frame.origin.x, loader.frame.origin.y, screenBounds.size.height, screenBounds.size.width);
    } else {
        splashScreenFrame = CGRectMake(0, isAtLeastiOS7()?0:-19, screenBounds.size.width, screenBounds.size.height);
        loaderFrame = CGRectMake(loader.frame.origin.x, loader.frame.origin.y, screenBounds.size.width, screenBounds.size.height);
    }

    splashScreen.frame = splashScreenFrame;
    loader.frame = loaderFrame;
    [loader replaceIndicator];
}

- (void)viewDidUnload {
    [self setWebView:nil];
    [self setLocationManager:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self toggleAudioPlayerRemote];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addSplashScreen {
    
    splashScreen = [UIImageView alloc];
    
    if(splashScreenImage) {
        splashScreen = [splashScreen initWithImage:splashScreenImage];
    } else if(isScreeniPhone6Plus()) {
        splashScreen = [splashScreen initWithImage:[UIImage imageNamed:@"LaunchImage-800-Portrait-736h@3x"]];
    } else if(isScreeniPhone6()) {
        splashScreen = [splashScreen initWithImage:[UIImage imageNamed:@"LaunchImage-800-667h@2x"]];
    } else if(isScreeniPhone5()) {
        splashScreen = [splashScreen initWithImage:[UIImage imageNamed:@"LaunchImage-700-568h@2x"]];
    } else {
        splashScreen = [splashScreen initWithImage:[UIImage imageNamed:@"LaunchImage-700@2x"]];
    }
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    splashScreen.frame = CGRectMake(0, isAtLeastiOS7()?0:-19, screenBounds.size.width, screenBounds.size.height);
    
    [self.view addSubview:splashScreen];
    [self.view bringSubviewToFront:splashScreen];
    
}

- (void)loadWebview {

    [self loadCookies];

    NSString *url = [[Url sharedInstance] get:@""];
    NSURLRequest *request = [NSURLRequest requestWithURL:[[NSURL alloc] initWithString:url]];
    
    [webView loadRequest:request];
    
}

- (void)saveCookies {
    NSData *cookiesData = [NSKeyedArchiver archivedDataWithRootObject: [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:cookiesData forKey:@"cookies"];
    [defaults synchronize];
}

- (void)loadCookies {
    NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData: [[NSUserDefaults standardUserDefaults] objectForKey:@"cookies"]];
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in cookies) {
        [cookieStorage setCookie:cookie];
    }
}

#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSString *url = [NSString stringWithFormat:@"%@", [request URL]];
    NSLog(@"url : %@", url);

    if([url hasPrefix:@"mailto:"]) {
        return YES;
    } else if([url rangeOfString:@"tel:"].location != NSNotFound) {
        NSLog(@"phone number : %@", [request URL]);
    } else if(navigationType == UIWebViewNavigationTypeLinkClicked || ([url hasPrefix:@"https://m.facebook.com/"] && [[[request URL] path] hasSuffix:@"/dialog/oauth"])) {
        webviewUrl = [[NSURL alloc] initWithString:url];
        [self performSegueWithIdentifier:@"openWebview" sender:self];
        return NO;
    } else if([url rangeOfString:@"app:"].location != NSNotFound) {
        
        NSArray *words = [url componentsSeparatedByString:@":"];
        SEL function = NSSelectorFromString([words lastObject]);
        if([self respondsToSelector:function]) {
            [self performSelector:function];
        } else {
            NSLog(@"Function not found: %@", [words lastObject]);
        }
        
        return NO;
        
    }
    
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"Error when loading the content");
    NSLog(@"Details: %@", error);
    NSLog(@"Domain: %@", [error domain]);
    
    if(!webViewIsLoaded) {
        useCache = YES;
        [self loadWebview];
    }
    [loader hide];
}

- (void)webViewDidFinishLoad:(UIWebView *)wv {
    
    if(!webViewIsLoaded) {
        
        webViewIsLoaded = YES;
        
        if(isAtLeastiOS7()) {
            [webView stringByEvaluatingJavaScriptFromString:@"angular.element(document.body).addClass('iOS7')"];
        }

        NSUserDefaults * dict =[NSUserDefaults standardUserDefaults];
        NSString * identifier =[dict stringForKey :@"identifier"];
        NSString * jsSetIdentifier =[NSString stringWithFormat :@"if(window.Application) { window.Application.setDeviceUid('%@'); window.Application.handle_address_book = true; window.Application.addHandler('code_scan'); window.Application.addHandler('social_sharing'); window.Application.addHandler('facebook_connect'); window.Application.addHandler('audio_player'); }", identifier];
        [webView stringByEvaluatingJavaScriptFromString : jsSetIdentifier];
        
        NSString * jsonString =[webView stringByEvaluatingJavaScriptFromString :@"JSON.stringify(window.colors)"];
        NSData * jsonData =[jsonString dataUsingEncoding : NSUTF8StringEncoding];
        NSDictionary * colors =[NSJSONSerialization JSONObjectWithData : jsonData options : NSJSONReadingAllowFragments error : nil];
        [common setColors : colors];
        
    }
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"openWebview"]) {
        [segue.destinationViewController setWebViewUrl:webviewUrl];
        [(webViewController *)segue.destinationViewController setDelegate:self];
    } else if ([[segue identifier] isEqualToString:@"openAudioPlayer"]) {
        [segue.destinationViewController setAudioPlayerData:self.audioPlayerData];
    }
}


- (void)getLocation {
    
    NSLog(@"locationServicesEnabled: %@", [CLLocationManager locationServicesEnabled] ? @"YES":@"NO");

    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    
    if([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways && [locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [locationManager requestWhenInUseAuthorization];
    } else {
        [locationManager startUpdatingLocation];
    }
}

- (void)createAdMobView {
    
}

- (void)appIsLoaded {
    
    [loader hide];
    
    if(splashScreen.hidden == NO) {
        // Initialisation et animation du splashscreen
        [UIView beginAnimations:@"startup_image" context:nil];
        [UIView setAnimationDuration:0.8];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector (startupAnimationDone:finished:context:)];
        splashScreen.alpha = 0;
        [UIView commitAnimations];
    }

    if(![appFirstRunning isEqualToString:@"false"]) {
        [webView stringByEvaluatingJavaScriptFromString:@"window.Application.showCacheDownloadModal();"];
    }

    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [locationManager requestAlwaysAuthorization];
    }
}

/** audioPlayer **/
-(void)openAudioPlayer {
    NSLog(@"openAudioPlayer");

    NSString *jsonString = [webView stringByEvaluatingJavaScriptFromString:@"window.audio_player_data"];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    self.audioPlayerData = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];

    [self performSegueWithIdentifier:@"openAudioPlayer" sender:self];
}

- (void)toggleAudioPlayerRemote {
    audioPlayer = [AudioPlayer audioPlayer];
    if(audioPlayer.isMinimized) {
        audioPlayer.delegate = self;
        [self showAudioPlayerRemote];
    } else {
        [self hideAudioPlayerRemote];
    }
}

- (void)showAudioPlayerRemote {
    float marginTop = self.remotePlayerView.frame.size.height;
    webView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height - marginTop);

    if([audioPlayer isRadio]) {
        self.btnPrevious.enabled = NO;
        self.btnNext.enabled = NO;
        self.progressBar.enabled = NO;
    } else {
        self.btnPrevious.enabled = YES;
        self.btnNext.enabled = YES;
        self.progressBar.enabled = YES;
    }

    [self updateView];
    
    if(![audioPlayer isRadio]) {
        [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(handle_UpdateProgress:) userInfo:nil repeats:YES];
    }

    self.remotePlayerView.hidden = NO;
}

- (void)hideAudioPlayerRemote {
    webView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);

    self.remotePlayerView.hidden = YES;
}

-(void)updatePlayButton {
    if([audioPlayer isPlaying]) {
        [self.btnPlayPause setImage:[UIImage imageNamed:@"Pause"]];
    } else {
        [self.btnPlayPause setImage:[UIImage imageNamed:@"Play"]];
    }
}

-(void)updatePreviousNextButton {
    if([audioPlayer isFirstAudioItem]) {
        [self.btnPrevious setEnabled:NO];
    } else {
        [self.btnPrevious setEnabled:YES];
    }

    if([audioPlayer isLastAudioItem]) {
        [self.btnNext setEnabled:NO];
    } else {
        [self.btnNext setEnabled:YES];
    }
}

-(void)updateView {
    self.progressBar.maximumValue = audioPlayer.currentTrackDuration;

    NSString *audioInfo = [[NSString alloc] initWithFormat:@"%@ - %@", audioPlayer.currentTrackTitle, audioPlayer.currentTrackArtist];
    if([audioPlayer isRadio]) {
        audioInfo = audioPlayer.currentTrackTitle;
    }
    
    [self.audioTitle setTitle:audioInfo forState:UIControlStateNormal];

    [self updatePlayButton];
    [self updatePreviousNextButton];
}

-(void)handle_UpdateProgress:(NSTimer *)timer {
    int secondsElapsed = CMTimeGetSeconds(audioPlayer.player.currentTime);
    self.progressBar.value = secondsElapsed;
}

//delegate
-(void)audioPlayerStateChanged {
    [self updatePlayButton];
}

-(void)audioWillPlay {
    [self updateView];
}

- (void)audioDidPlay {
    [self updatePreviousNextButton];
}

- (void)audioDidEnd {
    [self updatePlayButton];
}
//delegate end

- (IBAction)maximizeAudioPlayer:(id)sender {
    audioPlayer.isNewPlaylist = NO;
    [self performSegueWithIdentifier:@"openAudioPlayer" sender:self];
}

- (IBAction)playPrevious:(id)sender {
    [audioPlayer playPreviousItem];
}

- (IBAction)playOrPause:(id)sender {
    [audioPlayer playPause];
}

- (IBAction)playNext:(id)sender {
    [audioPlayer playNextItem];
}

- (IBAction)progressBarChanged:(id)sender {
    [audioPlayer.player seekToTime:CMTimeMakeWithSeconds((int)self.progressBar.value, 1)];
    [audioPlayer.nowPlayingInfo setValue:[NSNumber numberWithFloat:CMTimeGetSeconds(audioPlayer.player.currentTime)] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:audioPlayer.nowPlayingInfo];
}
/** /audioPlayer **/

/** socialSharing **/
- (void)openSharing {
    NSLog(@"openSharing");

    NSString *jsonString = [webView stringByEvaluatingJavaScriptFromString:@"window.sharing_data"];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *sharing_data = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];

    SocialSharing *socialSharing = [[SocialSharing alloc] init];
    socialSharing.delegate = self;
    [socialSharing open:self withSharingData:sharing_data];
}
- (void)shareViewWillAppear {
    [loader show];
}
- (void)shareViewDidAppear {
    [loader hide];
}
/** /socialSharing **/

- (void)markPushAsRead {
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

/* ZBAR */
- (void)openScanCamera {
    NSLog(@"openScanCamera");
    
    NSString *jsonString = [webView stringByEvaluatingJavaScriptFromString:@"window.scan_camera_protocols"];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    self.scanProtocols = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];

    ZBarReaderViewController *codeReader = [ZBarReaderViewController new];
    codeReader.readerDelegate=self;
    codeReader.supportedOrientationsMask = ZBarOrientationMaskAll;
    codeReader.showsHelpOnFail = NO;
    
    UIView * infoButton = [[[[[codeReader.view.subviews objectAtIndex:2] subviews] objectAtIndex:0] subviews] objectAtIndex:3];
    [infoButton setHidden:YES];
    
    ZBarImageScanner *scanner = codeReader.scanner;
    [scanner setSymbology: ZBAR_I25 config: ZBAR_CFG_ENABLE to: 0];
    
    [self presentViewController:codeReader animated:YES completion:nil];
}

- (void)imagePickerController: (UIImagePickerController*) reader didFinishPickingMediaWithInfo: (NSDictionary*) info {
    //  get the decode results
    id<NSFastEnumeration> results = [info objectForKey: ZBarReaderControllerResults];
    
    ZBarSymbol *symbol = nil;
    for(symbol in results)
        // just grab the first barcode
        break;
    
    self.scanContent = symbol.data;
    
    // dismiss the controller
    [reader dismissViewControllerAnimated:YES completion:nil];
    
    [self qrCodeRedirection];
}

-(void)qrCodeRedirection {
    BOOL protocolFound = false;
    NSString *protocol = nil;
    
    for(protocol in self.scanProtocols) {
        
        if([self.scanContent hasPrefix:protocol]) {
            
            if([protocol isEqual:@"http:"] || [protocol isEqual:@"https:"]) {
                webviewUrl = [[NSURL alloc] initWithString:self.scanContent];
                NSLog(@"webviewUrl: %@",self.scanContent);
                [self performSegueWithIdentifier:@"openWebview" sender:self];
                return;
            } else if([protocol isEqual:@"tel:"]) {
                NSURLRequest *request = [NSURLRequest requestWithURL:[[NSURL alloc] initWithString:self.scanContent]];
                [webView loadRequest:request];
                return;
            } else if([protocol isEqual:@"sendback:"]) {
                NSString *value = [self.scanContent substringFromIndex:(@"sendback:").length];
                NSString * jsCallBack =[NSString stringWithFormat :@"if(window.Application) { window.Application.fireCallback('success', 'openScanCamera', '%@'); }", value];
                [webView stringByEvaluatingJavaScriptFromString : jsCallBack];
                NSLog(@"sendback:");
                return;
            }
            
            protocolFound = true;
        } else if([protocol isEqual:@"ctc:"]) {
            NSLog(@"Copy to Clipboard");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:self.scanContent delegate:self cancelButtonTitle:NSLocalizedString(@"Done", nil) otherButtonTitles:NSLocalizedString(@"Copy", nil), nil];
            [alert show];
            
            protocolFound = true;
        }
    }
    
    if(!protocolFound) {
        NSLog(@"Error reading QRCode");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Scanned QRCode" message:NSLocalizedString(@"Error while reading the QRCode", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Done", nil) otherButtonTitles:nil, nil];
        [alert show];
    }
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)reader {
    NSLog(@"Cancelled");
    [reader dismissViewControllerAnimated:YES completion:nil];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != [alertView cancelButtonIndex]){
        NSLog(@"Copy clicked");
        UIPasteboard *cpb = [UIPasteboard generalPasteboard];
        [cpb setString:self.scanContent];
    }
}
/* /ZBAR */

- (void)storeData {
    
    NSLog(@"storeData");
    
    NSString *jsonString = [webView stringByEvaluatingJavaScriptFromString:@"window.store_data"];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *storeData = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
    
    NSUserDefaults *dict = [NSUserDefaults standardUserDefaults];
    
    for(NSString *storeKey in storeData) {
        NSString *storeValue = [storeData objectForKey:storeKey];
        [dict setObject:storeValue forKey:storeKey];
        [dict synchronize];
    }
    
    [webView stringByEvaluatingJavaScriptFromString : @"if(window.Application) { window.Application.fireCallback('success', 'storeData', ''); }"];
    
}

- (void)getStoredData {
    
    NSLog(@"getStoredData");
    
    NSString *jsonString = [webView stringByEvaluatingJavaScriptFromString:@"window.stored_data"];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *storedData = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
    
    NSUserDefaults *dict = [NSUserDefaults standardUserDefaults];
    NSString *resultJSON = @"{";
    
    for(NSString *storedKey in storedData) {
        NSString *storedValue = [dict stringForKey:storedKey];
        
        if(storedValue) {
            resultJSON = [[NSString alloc] initWithFormat:@"%@ \"%@\" : \"%@\",", resultJSON, storedKey, storedValue];
        }
    }

    resultJSON = [[NSString alloc] initWithFormat:@"%@ }", [resultJSON substringToIndex:resultJSON.length-1]];
    
    NSString *jsCallBack =[NSString stringWithFormat :@"if(window.Application) { window.Application.fireCallback('success', 'getStoredData', '%@'); }", resultJSON];
    [webView stringByEvaluatingJavaScriptFromString : jsCallBack];
    
}

- (void)addToContact {
    
    NSString *jsonString = [webView stringByEvaluatingJavaScriptFromString:@"window.contact_data"];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *contact_data = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
    
    Contact *contact = [[Contact alloc] init];
    contact.delegate = self;
    [contact setDetails:contact_data];
    [contact addToAddressBook];
    
}

- (void)contactAdded {
    [webView stringByEvaluatingJavaScriptFromString:@"addToContactCallback('success')"];
}

- (void)contactNotAdded:(int)code {
    NSLog(@"Error adding contact: %d", code);
    NSString *js = [NSString stringWithFormat:@"addToContactCallback('error', %d)", code];
    [webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if (status == kCLAuthorizationStatusAuthorized ||
        status == kCLAuthorizationStatusAuthorizedWhenInUse ||
        status == kCLAuthorizationStatusAuthorizedAlways) {
        [self.locationManager startUpdatingLocation];
    } else if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        [webView stringByEvaluatingJavaScriptFromString:@"setCoordinates('error')"];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)location {
    CLLocation *currentLocation = [location objectAtIndex:0];
    [locationManager stopUpdatingLocation];
    NSLog(@"position: %@", currentLocation);
    NSString *coordinates = [[NSString alloc] initWithFormat:@"setCoordinates('success', %f, %f)", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude];
    [webView stringByEvaluatingJavaScriptFromString:coordinates];
    
}
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    [locationManager stopUpdatingLocation];
    NSLog(@"position: %@", newLocation);
    NSString *coordinates = [[NSString alloc] initWithFormat:@"setCoordinates('success', %f, %f)", newLocation.coordinate.latitude, newLocation.coordinate.longitude];
    [webView stringByEvaluatingJavaScriptFromString:coordinates];
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [webView stringByEvaluatingJavaScriptFromString:@"setCoordinates('error')"];
    NSLog(@"Can't access user's position");
}

- (void)removeBadge {
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)startupAnimationDone:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    [splashScreen removeFromSuperview];
}

- (void)connectionStateDidChange:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    if(userInfo != nil) {
        NSLog(@"Must show Ads: %@", [userInfo objectForKey:@"isOnline"]);
    }
    
}

- (void)facebookDidClose:(BOOL)isLoggedIn {
    if(isLoggedIn) {
        [webView stringByEvaluatingJavaScriptFromString :@"window.checkFacebookLoginStatus();"];
    }
}

@end
