//
//  SocialSharing.h
//  Apps Mobile Company
//
//  Created by Florent BEGUE on 12/10/15.
//  Copyright © 2015 Adrien Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "loaderView.h"
#import "common.h"

@protocol socialSharingDelegate

@optional

- (void)shareViewDidAppear;
- (void)shareViewWillAppear;

@end

@interface SocialSharing : NSObject {
    id <NSObject, socialSharingDelegate> delegate;
}

@property (retain) id <NSObject, socialSharingDelegate> delegate;

-(void)open:(UIViewController *)viewController withSharingData:(NSDictionary *)sharingData;

@end
