//
//  SocialSharing.m
//  Apps Mobile Company
//
//  Created by Florent BEGUE on 12/10/15.
//  Copyright © 2015 Adrien Sala. All rights reserved.
//

#import "SocialSharing.h"

@implementation SocialSharing;

@synthesize delegate;

-(void)open:(UIViewController *)viewController withSharingData:(NSDictionary *)sharing_data {
    NSLog(@"openSharing");
    
    if([delegate respondsToSelector:@selector(shareViewWillAppear)]) {
        [delegate shareViewWillAppear];
    }
    
    NSDictionary *urlParts = NSBundle.mainBundle.infoDictionary [@"Url"];
    
    //create tinyurl
    NSURL *sharingUrl = [NSURL URLWithString: [NSString stringWithFormat:@"http://tinyurl.com/api-create.php?url=%@", [[NSString alloc] initWithFormat:@"%@://%@/application/device/downloadapp/app_id/%@", [urlParts objectForKey:@"url_scheme"], [urlParts objectForKey:@"url_domain"], NSBundle.mainBundle.infoDictionary [@"AppId"]] ] ];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:sharingUrl];
    NSURLResponse *response;
    NSError *error;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    
    if(!error) {
        sharingUrl = [[NSURL alloc] initWithString:responseString];
    } else {
        sharingUrl = [[NSURL alloc] initWithString: [[NSString alloc] initWithFormat:@"%@://%@/application/device/downloadapp/app_id/%@", [urlParts objectForKey:@"url_scheme"], [urlParts objectForKey:@"url_domain"], NSBundle.mainBundle.infoDictionary [@"AppId"]]];
    }
    
    NSString *sharingText = @"";
    if([[sharing_data objectForKey:@"custom_sharing_text"] isKindOfClass:[NSString class]]) {
         sharingText = [[NSString alloc] initWithFormat:[sharing_data objectForKey:@"custom_sharing_text"], sharingUrl];
    } else {
        NSString *pageName = [sharing_data objectForKey:@"page_name"];
        
        NSString *contentMessage = ![sharing_data objectForKey:@"content"] ? pageName : [sharing_data valueForKey:@"content"];
        contentMessage = [[NSString alloc] initWithFormat:@"\"%@\"", contentMessage];
        
        NSString *picture = [sharing_data objectForKey:@"picture"];
        picture = [picture isKindOfClass:[NSNull class]]?@"":[[NSString alloc] initWithFormat:@"%@://%@/%@/%@", [urlParts objectForKey:@"url_scheme"], [urlParts objectForKey:@"url_domain"], [urlParts objectForKey:@"url_key"], picture];
        
        sharingText = [[NSString alloc] initWithFormat: NSLocalizedString(@"Hi. I just found: %@ in the %@ app. %@", nil), contentMessage, getAppName(), sharingUrl];
    }
    
    //pas d'ajout d'image pour le moment car il faut la télécharger avant
    NSArray *dataToShare = @[sharingText];
    
    UIActivityViewController* activityViewController = [[UIActivityViewController alloc] initWithActivityItems:dataToShare applicationActivities:nil];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        //if iPhone
        [viewController presentViewController:activityViewController animated:YES completion:^{[self shareViewDidAppear];}];
    } else {
        //if iPad
        // Change Rect to position Popover
        UIPopoverController *popup = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
        [popup presentPopoverFromRect:CGRectMake(viewController.view.frame.size.width, 67, 0, 0)inView:viewController.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
        [self shareViewDidAppear];
    }

}

-(void)shareViewDidAppear {
    if([delegate respondsToSelector:@selector(shareViewDidAppear)]) {
        [delegate shareViewDidAppear];
    }
}

@end