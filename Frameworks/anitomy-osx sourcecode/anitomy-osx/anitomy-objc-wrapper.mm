//
//  anitomy-objc-wrapper.m
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

#import "anitomy-objc-wrapper.h"
#import "anitomy.h"
#include <iostream>
#include <string>

@implementation anitomy_bridge
#if TARGET_RT_BIG_ENDIAN
const NSStringEncoding kEncoding_wchar_t =
CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF32BE);
#else
const NSStringEncoding kEncoding_wchar_t =
CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF32LE);
#endif

-(NSDictionary *)tokenize:(NSString *) filename{
    anitomy::Anitomy anitomy;
    NSData *d = [filename dataUsingEncoding:kEncoding_wchar_t];
    anitomy.Parse(std::wstring((wchar_t *)[d bytes], [d length] / sizeof(wchar_t)));//"[Ouroboros]_Fullmetal_Alchemist_Brotherhood_-_01.mkv"
    
    auto& elements = anitomy.elements();
    
    // Generate NSString and Convert
    NSString * title = [self wstringtoNSString:elements.get(anitomy::kElementAnimeTitle)];
    NSString * episode = [self wstringtoNSString:elements.get(anitomy::kElementEpisodeNumber)];
    NSString * group = [self wstringtoNSString:elements.get(anitomy::kElementReleaseGroup)];
    NSString * year = [self wstringtoNSString: elements.get(anitomy::kElementAnimeYear)];
    NSString * releaseversion = [self wstringtoNSString: elements.get(anitomy::kElementReleaseVersion)];
    NSString * videoterm = [self wstringtoNSString: elements.get(anitomy::kElementVideoTerm)];
    NSString * videosource = [self wstringtoNSString: elements.get(anitomy::kElementSource)];
    NSDictionary * dic = [[NSDictionary alloc] initWithObjectsAndKeys:title,@"title",episode,@"episode",group,@"group",year,@"year",releaseversion, @"releaseversion", videoterm,@"videoterm", videosource, @"videosource", nil];
    return dic;
}
-(NSString *)wstringtoNSString:(const std::wstring&)ws{
    char *data = (char *)ws.data();
    size_t size = ws.size() * sizeof(wchar_t);
    
    NSString *result = [[NSString alloc] initWithBytes:data length:size
                                               encoding:kEncoding_wchar_t];
    return result;
}
@end
