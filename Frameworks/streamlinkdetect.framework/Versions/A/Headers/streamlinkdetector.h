//
//  streamlinkdetector.h
//  streamlinkdetect
//
//  Created by 天々座理世 on 2017/03/21.
//  Copyright © 2017年 Atelier Shiori. All rights reserved.
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
/**
 This class allows you run a stream with streamlink and obtain stream information (title, episode, site)
 */
@interface streamlinkdetector : NSObject{
    /**
     The task that executes streamlink
     */
    NSTask * task;
    /**
     This returns the output from streamlink.
     */
    NSPipe * pipe;
}
/**
 This specifies the streamURL
 */
@property (strong, setter=setStreamURL:) NSString * streamurl;
/**
 This specifies arguments for streamlink
 */
@property (strong, setter=setargs:) NSString * args;
/**
 This specifies the name of the stream to open in a media player.
 */
@property (strong, setter=setStream:) NSString * stream;
/**
 This returns information about the playing stream.
 @return NSArray The stream's information (title, episode, season, site)
 */
@property (strong, getter=getdetectinfo) NSArray * detectioninfo;
/**
 This specifies if there is a stream open.
 @return bool Streamlinker's state.
 */
@property (getter=getStreamStatus) bool isstreaming;

/**
 This method retrieves the stream information of a URL.
 @return bool Specifies if the stream information retrieval is successful or not.
 */
-(bool)getDetectionInfo;
/**
 This method starts streamlink with the specified arguments, stream url and stream name.
 */
-(void)startStream;
/**
 This method starts terminates streamlink.
 */
-(void)stopStream;
/**
 This method returns a list of available streams.
 */
-(NSArray *)getAvailableStreams;
@end
