//
//  anitomy-objc-wrapper.h
//  Anitomy Objective C Wrapper
//
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Foundation/Foundation.h>

@interface anitomy_bridge : NSObject
/*
 Usage: NSDictionary * d = [[[anitomy_bridge init] alloc] tokenize:@"<filename>"]
 Dictionary Contents: title, episode, episodetitle, episodetype, group, year, releaseversion, videoterm, videosource, season
 */
-(NSDictionary *)tokenize:(NSString *) filename;
@end