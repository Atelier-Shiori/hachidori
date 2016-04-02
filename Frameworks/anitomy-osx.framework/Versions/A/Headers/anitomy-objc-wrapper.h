//
//  anitomy-objc-wrapper.h
//  Anitomy Objective C Wrapper
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>

@interface anitomy_bridge : NSObject
/*
 Usage: NSDictionary * d = [[[anitomy_bridge init] alloc] tokenize:@"<filename>"]
 Dictionary Contents: title, episode, episodetitle, episodetype, group, year, releaseversion, videoterm, videosource, season
 */
-(NSDictionary *)tokenize:(NSString *) filename;
@end