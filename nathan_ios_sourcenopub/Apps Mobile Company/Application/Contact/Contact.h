//
//  Contact.h
//  Apps Mobile Company
//
//  Created by Adrien Sala on 30/12/2014.
//  Copyright (c) 2014 Adrien Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBookUI/AddressBookUI.h>

@protocol ContactDelegate

- (void) contactAdded;
- (void) contactNotAdded:(int)code;

@end


@interface Contact : NSObject {
    id <NSObject, ContactDelegate> delegate;
}

@property (retain) id <NSObject, ContactDelegate> delegate;
@property(strong, nonatomic) NSDictionary *details;

- (void)addToAddressBook;

@end
