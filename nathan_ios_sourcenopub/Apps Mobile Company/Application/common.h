//
//  common.h
//  Siberian
//
//  Created by The Tiger App Creator Team on 24/02/14.
//
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CommonCrypto/CommonDigest.h>
#import <CoreLocation/CoreLocation.h>

BOOL isScreeniPhone5();
BOOL isScreeniPhone6();
BOOL isScreeniPhone6Plus();
BOOL isAtLeastiOS7();
int getScreenWidth();
int getScreenHeight();
NSString *getAppName();
NSMutableDictionary *appColors;

@interface common : NSObject

+ (void)setColors:(NSDictionary *)colors;
+ (NSDictionary *)getColors:(NSString *)area;
+ (NSString *)unescape:(NSString *)string;
+ (void)replaceTextWithLocalizedTextInSubviewsForView:(UIView*)view;
+ (BOOL)isInsideLocation:(CLLocation *)fromLocation searchLocation:(CLLocation *)searchLocation withRadiusInMeters:(double)radiusLocation;

@end

/** Request Protection **/
@interface NSString (SHA1)

+ (NSString*) toSHA1:(NSString*)input;

@end

@implementation NSString (SHA1)

+ (NSString *) toSHA1:(NSString*)input
{
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (CC_LONG) data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
    
}

@end