//
//  AppDelegate.m
//  Siberian Angular
//
//  Created by Adrien Sala on 08/07/2014.
//  Copyright (c) 2014 Adrien Sala. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    
    // Set the User Agent
    NSString* userAgent = [[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    userAgent = [userAgent stringByAppendingString:@" Type/siberian.application"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:userAgent, @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];

    // Prepare the cache
    [NSURLProtocol registerClass:[RNCachingURLProtocol class]];

    // Create an identifier if not exists
    NSUserDefaults *dict = [NSUserDefaults standardUserDefaults];
    NSString *identifier = [dict stringForKey:@"identifier"];
    if(identifier.length == 0) {
        CFUUIDRef uuidRef = CFUUIDCreate(NULL);
        CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
        CFRelease(uuidRef);
        identifier = (__bridge NSString *)uuidStringRef;
        [dict setObject:identifier forKey:@"identifier"];
        [dict synchronize];
    }

    // Prepare the push notifications
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        // use registerUserNotificationSettings
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];

    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL ok;
    NSError *setCategoryError = nil;
    ok = [audioSession setCategory:AVAudioSessionCategoryPlayback
                             error:&setCategoryError];
    [audioSession setActive: YES error: nil];

    return YES;
}

/* /PUSH */
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)token {

#if !TARGET_IPHONE_SIMULATOR

    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];

    NSString *pushBadge = @"disabled";
    NSString *pushAlert = @"disabled";
    NSString *pushSound = @"disabled";

    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"isFirstLaunch"] == nil) {
        pushBadge = @"enabled";
        pushAlert = @"enabled";
        pushSound = @"enabled";
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isFirstLaunch"];
    }
    else if([application respondsToSelector:@selector(currentUserNotificationSettings)]) {
        // UIUserNotificationSettings *currentSettings = [application currentUserNotificationSettings];
        pushBadge = @"enabled";
        pushAlert = @"enabled";
        pushSound = @"enabled";
    } else {

        NSUInteger rntypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];

        if(rntypes == UIRemoteNotificationTypeBadge){
            pushBadge = @"enabled";
        }
        else if(rntypes == UIRemoteNotificationTypeAlert) {
            pushAlert = @"enabled";
        }
        else if(rntypes == UIRemoteNotificationTypeSound) {
            pushSound = @"enabled";
        }
        else if(rntypes == ( UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert)) {
            pushBadge = @"enabled";
            pushAlert = @"enabled";
        }
        else if(rntypes == ( UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)) {
            pushBadge = @"enabled";
            pushSound = @"enabled";
        }
        else if(rntypes == ( UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)) {
            pushAlert = @"enabled";
            pushSound = @"enabled";
        }
        else if(rntypes == ( UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)) {
            pushBadge = @"enabled";
            pushAlert = @"enabled";
            pushSound = @"enabled";
        }
    }
    // Get the users Device Model, Display Name, Token & Version Number
    UIDevice *dev = [UIDevice currentDevice];

    NSUserDefaults *dict = [NSUserDefaults standardUserDefaults];
    NSString *identifier = [dict stringForKey:@"identifier"];
    NSString *deviceName = dev.name;
    NSString *deviceModel = dev.model;
    NSString *deviceSystemVersion = dev.systemVersion;

    // Prepare the Device Token for Registration (remove spaces and < >)
    NSString *deviceToken = [[[[token description]
                               stringByReplacingOccurrencesOfString:@"<"withString:@""]
                              stringByReplacingOccurrencesOfString:@">" withString:@""]
                             stringByReplacingOccurrencesOfString: @" " withString: @""];

    NSMutableDictionary *postDatas = [NSMutableDictionary dictionary];
    [postDatas setObject:appName forKey:@"app_name"];
    [postDatas setObject:appVersion forKey:@"app_version"];
    [postDatas setObject:identifier forKey:@"device_uid"];
    [postDatas setObject:deviceToken forKey:@"device_token"];
    [postDatas setObject:deviceName forKey:@"device_name"];
    [postDatas setObject:deviceModel forKey:@"device_model"];
    [postDatas setObject:deviceSystemVersion forKey:@"device_version"];
    [postDatas setObject:pushBadge forKey:@"push_badge"];
    [postDatas setObject:pushAlert forKey:@"push_alert"];
    [postDatas setObject:pushSound forKey:@"push_sound"];

    Request *request = [Request alloc];
    request.delegate = self;

    [request postDatas:postDatas withUrl:@"push/iphone/registerdevice/"];


#endif

}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    //silent notification
    if([userInfo[@"aps"][@"content-available"] intValue] == 1) {
        NSString *pushIdentifier = [[NSString alloc] initWithFormat:@"push%@", userInfo[@"aps"][@"message_id"]];
        
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([userInfo[@"aps"][@"latitude"] doubleValue], [userInfo[@"aps"][@"longitude"] doubleValue]);
        CLRegion *pushRegion = [[CLRegion alloc] initCircularRegionWithCenter:coordinate radius:[userInfo[@"aps"][@"radius"] doubleValue] identifier:pushIdentifier];
        
        CLLocation *pushLocation = [[CLLocation alloc] initWithLatitude:[userInfo[@"aps"][@"latitude"] doubleValue] longitude:[userInfo[@"aps"][@"longitude"] doubleValue]];
        double radiusLocation = [userInfo[@"aps"][@"radius"] doubleValue] * 1000;
        
        NSString * sendUntil = [userInfo[@"aps"][@"send_until"] isKindOfClass:[NSString class]] ? userInfo[@"aps"][@"send_until"] : @"";
        
        if([self isPushStillValid:sendUntil]) {
            
            NSDictionary *notificationInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                                              sendUntil, @"send_until",
                                              userInfo[@"aps"][@"message_id"], @"message_id",
                                              userInfo[@"aps"][@"user_info"][@"alert"][@"body"], @"alert_body",
                                              userInfo[@"aps"][@"user_info"][@"alert"][@"action-loc-key"], @"alert_action",
                                              userInfo[@"aps"][@"user_info"][@"sound"], @"sound",
                                              nil];
            
            if([common isInsideLocation:[locationManager location] searchLocation:pushLocation withRadiusInMeters:radiusLocation]) {
                NSLog(@"Inside region, send local notification");
                
                [self sendLocalNotification:notificationInfo];
            } else {
                NSLog(@"Silent notification received");
                
                NSUserDefaults *dict = [NSUserDefaults standardUserDefaults];
                [dict setObject:notificationInfo forKey:pushIdentifier];
                [dict synchronize];
                
                if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
                    [locationManager requestAlwaysAuthorization];
                }
                [locationManager startMonitoringForRegion:pushRegion];
            }
            
        }
        
        completionHandler(UIBackgroundFetchResultNewData);
        return;
    } else {
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }
}

/** GEOLOCATED PUSH NOTIFICATONS **/
-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSUserDefaults *dict = [NSUserDefaults standardUserDefaults];
    NSDictionary *userInfo = [dict objectForKey:[region identifier]];
    
    if(userInfo != nil) {
        [self sendLocalNotification:userInfo];
        
        [dict removeObjectForKey:[region identifier]];
        [dict synchronize];
    }
    
    [manager stopMonitoringForRegion:region];
}
-(BOOL)isPushStillValid:(NSString *)pushExpirationDate {
    if(![pushExpirationDate isEqualToString:@""]) {
        NSDate *currentDate = [NSDate date];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *pushSendUntilDate = [dateFormatter dateFromString:pushExpirationDate];
        
        NSLog(@"%@ <= %@ = %i", currentDate, pushSendUntilDate, ([currentDate earlierDate:pushSendUntilDate] || [currentDate isEqualToDate:pushSendUntilDate]) );
        return [currentDate earlierDate:pushSendUntilDate] || [currentDate isEqualToDate:pushSendUntilDate];
    } else {
        return YES;
    }
}
-(void)sendLocalNotification:(NSDictionary *)userInfo {
    if([self isPushStillValid:userInfo[@"send_until"]]) {
        NSLog(@"sendLocalNotification: %@", userInfo);
        
        UILocalNotification *locNotification = [[UILocalNotification alloc] init];
        locNotification.alertBody = userInfo[@"alert_body"];
        locNotification.alertAction = userInfo[@"alert_action"];
        locNotification.soundName = userInfo[@"sound"];
        locNotification.applicationIconBadgeNumber++;
        [[UIApplication sharedApplication] presentLocalNotificationNow:locNotification];
        
        //mark push as displayed
        NSUserDefaults *dict = [NSUserDefaults standardUserDefaults];
        NSString *identifier = [dict stringForKey:@"identifier"];
        
        NSMutableDictionary *postDatas = [NSMutableDictionary dictionary];
        [postDatas setObject:identifier forKey:@"device_uid"];
        [postDatas setObject:userInfo[@"message_id"] forKey:@"message_id"];
        
        Request *request = [Request alloc];
        request.delegate = self;
        
        [request postDatas:postDatas withUrl:@"push/iphone/markdisplayed/"];
    } else {
        NSLog(@"Local notification has expired");
    }
}
/** /GEOLOCATED PUSH NOTIFICATONS **/

- (void) connectionDidFinish:(NSData *)datas {

    // Récupère le badge
    NSString *badge = [[NSString alloc] initWithData:datas encoding:NSUTF8StringEncoding];
    [UIApplication sharedApplication].applicationIconBadgeNumber = [badge intValue];
}

- (void) connectionDidFail {
    NSLog(@"connexion échouée");
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
//    NSLog(@"Push échoué");
}

/* /PUSH */

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    ViewController *currentController = (ViewController *)self.window.rootViewController;
    [currentController saveCookies];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
