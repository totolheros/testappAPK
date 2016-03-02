//
//  Contact.m
//  Apps Mobile Company
//
//  Created by Adrien Sala on 30/12/2014.
//  Copyright (c) 2014 Adrien Sala. All rights reserved.
//

#import "Contact.h"

@implementation Contact

@synthesize details, delegate;

- (void)addToAddressBook {
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied ||
        ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted) {
        
        if([delegate respondsToSelector:@selector(contactNotAdded:)]) {
            [delegate contactNotAdded:1];
        }
        
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized){
        [self _addToAddressBook];
    } else { // ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined

        ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (granted) {
                    [self _addToAddressBook];
                } else if([delegate respondsToSelector:@selector(contactNotAdded:)]) {
                    [delegate contactNotAdded:1];
                }
                
            });
        });
        
    }
    
}

- (void)_addToAddressBook {
    
    NSString *contactFirstName;
    NSString *contactLastName;
    NSString *contactPhoneNumber;
    NSData *contactImageData;
    
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, nil);
    ABRecordRef contact = ABPersonCreate();
    if([details objectForKey:@"firstname"]) {
        contactFirstName = [details objectForKey:@"firstname"];
        ABRecordSetValue(contact, kABPersonFirstNameProperty, (__bridge CFStringRef) contactFirstName, nil);
    }
    if([details objectForKey:@"lastname"]) {
        contactLastName = [details objectForKey:@"lastname"];
        ABRecordSetValue(contact, kABPersonLastNameProperty, (__bridge CFStringRef) contactLastName, nil);
    }
    
    if([details objectForKey:@"phone"]) {
        contactPhoneNumber = [details objectForKey:@"phone"];
        ABMutableMultiValueRef phoneNumbers = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        ABMultiValueAddValueAndLabel(phoneNumbers, (__bridge CFStringRef)contactPhoneNumber, kABPersonPhoneMainLabel, NULL);
        ABRecordSetValue(contact, kABPersonPhoneProperty, phoneNumbers, nil);
    }

    if([details objectForKey:@"image_url"]) {
        NSURL *imageUrl = [[NSURL alloc] initWithString:[details objectForKey:@"image_url"]];
        contactImageData = [NSData dataWithContentsOfURL:imageUrl];
        ABPersonSetImageData(contact, (__bridge CFDataRef)contactImageData, nil);
    }
    
    if([details objectForKey:@"street"]) {
        @try {
            
            ABMutableMultiValueRef address = ABMultiValueCreateMutable(kABDictionaryPropertyType);
            CFStringRef keys[3];
            CFStringRef values[3];
            keys[0] = kABPersonAddressStreetKey;
            keys[1] = kABPersonAddressZIPKey;
            keys[2] = kABPersonAddressCityKey;
            
            values[0] = (__bridge_retained CFStringRef) [details objectForKey:@"street"];
            values[1] = (__bridge_retained CFStringRef) [details objectForKey:@"postcode"];
            values[2] = (__bridge_retained CFStringRef) [details objectForKey:@"city"];
            
            CFDictionaryRef dicref = CFDictionaryCreate(kCFAllocatorDefault, (void *)keys, (void *)values, 3, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

            ABMultiValueIdentifier identifier;
            ABMultiValueAddValueAndLabel(address, dicref, kABHomeLabel, &identifier);
            ABRecordSetValue(contact, kABPersonAddressProperty, address, nil);
            
        }
        @catch (NSException * e) {
            NSLog(@"Exception: %@", e);
        }
        @finally {

        }
    }
    
    ABAddressBookAddRecord(addressBookRef, contact, nil);
    
    NSArray *allContacts = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBookRef);
    for (id record in allContacts){
        ABRecordRef thisContact = (__bridge ABRecordRef)record;
        if (CFStringCompare(ABRecordCopyCompositeName(thisContact), ABRecordCopyCompositeName(contact), 0) == kCFCompareEqualTo){
            if([delegate respondsToSelector:@selector(contactNotAdded:)]) {
                [delegate contactNotAdded:2];
            }
            return;
        }
    }
    
    ABAddressBookSave(addressBookRef, nil);
    
    if([delegate respondsToSelector:@selector(contactAdded)]) {
        [delegate contactAdded];
    }
    
}


@end
