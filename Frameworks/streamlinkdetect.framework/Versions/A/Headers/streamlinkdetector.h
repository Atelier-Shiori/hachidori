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
#import <AppKit/AppKit.h>
#import "streamlinkdetectordelegate.h"

@class streamlinkinstall;

/**
 This class allows you run a stream with streamlink and obtain stream information (title, episode, site)
 */
@interface streamlinkdetector : NSObject
/**
 The task that executes streamlink
 */
@property (strong) NSTask * task;
/**
 This returns the output from streamlink.
 */
@property (strong) NSPipe * pipe;
/**
 The Streamlink install window.
 */
@property (strong) streamlinkinstall * streamlinkinstallw;
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
 The delegate for the detector
 */
@property (nonatomic, weak) id <streamlinkdetectordelegate> delegate;
/**
 This method allows you to set a streamlinkdetect delegate.
 */
- (void)setDelegate:(id <streamlinkdetectordelegate>)aDelegate;
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
/**
 This method detects a current stream playing and then returns the stream information.
@return NSArray The stream's information (title, episode, season, site)
 */
-(NSArray *)detectAndRetrieveInfo;
/**
 This method checks if streamlink is intalled. If not, you can prompt to install it.
 @pram w The window to attach the dialog to as a sheet
 */
-(void)checkStreamLink:(NSWindow *)w;
/**
 This method checks if streamlink is intalled. If not, it will return false
 @return bool Shows if streamlink is installed.
 */
-(bool)checkifStreamLinkExists;
/**
 This method installs Streamlink
 */
-(void)installStreamLink;
@end
