//
//  ASINSStringAdditions.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 12/09/2008.
//  Copyright 2008 All-Seeing Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (CookieValueEncodingAdditions)

- (NSString *)encodedCookieValue;
- (NSString *)decodedCookieValue;

@end
