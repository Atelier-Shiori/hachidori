//
//  MediaStreamParse.h
//  detectstream
//
//  Created by 高町なのは on 2015/02/09.
//  Copyright (c) 2015年 Chikorita157's Anime Blog. All rights reserved.
//
//  This class parses the title if it's playing an episode.
//  It will find title, episode and season information.
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

@interface MediaStreamParse : NSObject
+(NSArray *)parse:(NSArray *)pages;
@end
