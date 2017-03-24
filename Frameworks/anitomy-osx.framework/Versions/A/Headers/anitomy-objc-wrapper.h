//
//  anitomy-objc-wrapper.h
//  Anitomy Objective C Wrapper
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>
/**
 This class allows you to use Anitomy with Objective-C or Swift Projects.
 */
@interface anitomy_bridge : NSObject
/**
 Tokenizes a media's file name. Convenience method so you don't have to initalize an instance of Anitomy.
 @param filename The filename to tokenize.
 @return NSDictionary Returns a dictionary containing information of a filename.
 */
+(NSDictionary *)tokenize:(NSString *) filename;
/**
 Tokenizes a media's file name.
 @param filename The filename to tokenize.
 @return NSDictionary Returns a dictionary containing information of a filename.
 */
-(NSDictionary *)tokenize:(NSString *) filename;
@end
