//
//  Hachidori+Hachidori_Update.h
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//
//

#import "Hachidori.h"

@interface Hachidori (Hachidori_Update)
-(int)updatetitle:(NSString *)titleid;
-(int)performupdate:(NSString *)titleid;
-(BOOL)updatestatus:(NSString *)titleid
            episode:(NSString *)episode
              score:(float)showscore
        watchstatus:(NSString*)showwatchstatus
              notes:(NSString*)note
          isPrivate:(BOOL)privatevalue;
-(bool)removetitle:(NSString *)titleid;
@end
