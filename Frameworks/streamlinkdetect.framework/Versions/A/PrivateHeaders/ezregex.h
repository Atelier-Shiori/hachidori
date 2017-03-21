//
//  ezregex.h
//  Detectstream
//
//  Created by Tail Red on 2/06/15.
//  Copyright 2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
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

//
// This class is used to simplify regex
//
@interface ezregex : NSObject
-(BOOL)checkMatch:(NSString *)string pattern:(NSString *)pattern;
-(NSString *)searchreplace:(NSString *)string pattern:(NSString *)pattern;
-(NSString *)findMatch:(NSString *)string pattern:(NSString *)pattern rangeatindex:(int)ri;
-(NSArray *)findMatches:(NSString *)string pattern:(NSString *)pattern;
@end