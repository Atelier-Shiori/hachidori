//
//  Log.m
//  Hachidori
//
//  Created by 香風智乃 on 3/10/19.
//

#import "Log.h"

@implementation Log
void append(NSString *msg){
    NSString *documentsDirectory = [Log retrieveApplicationSupportDirectory:@""];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"Hachidori.log"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]){
        fprintf(stderr,"Creating file at %s",[path UTF8String]);
        [[NSData data] writeToFile:path atomically:YES];
    }
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
    [handle truncateFileAtOffset:[handle seekToEndOfFile]];
    [handle writeData:[msg dataUsingEncoding:NSUTF8StringEncoding]];
    [handle closeFile];
}

void _Log(NSString *prefix, const char *file, int lineNumber, const char *funcName, NSString *format,...) {
    va_list ap;
    va_start (ap, format);
    format = [format stringByAppendingString:@"\n"];
    NSString *msg = [[NSString alloc] initWithFormat:[NSString stringWithFormat:@"%@",format] arguments:ap];
    va_end (ap);
    fprintf(stderr,"%s%50s:%3d - %s",[prefix UTF8String], funcName, lineNumber, [msg UTF8String]);
    append(msg);
}

+ (NSString *)retrieveApplicationSupportDirectory:(NSString*)append{
    NSFileManager *filemanager = [NSFileManager defaultManager];
    NSError *error;
    NSString *bundlename = [NSBundle mainBundle].infoDictionary[@"CFBundleName"];
    append = [NSString stringWithFormat:@"%@/%@", bundlename, append];
    NSURL *path = [filemanager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:true error:&error];
    NSString *dir = [NSString stringWithFormat:@"%@/%@",path.path,append];
    if (![filemanager fileExistsAtPath:dir isDirectory:nil]) {
        NSError *ferror;
        bool success = [filemanager createDirectoryAtPath:dir withIntermediateDirectories:true attributes:nil error:&ferror];
        if (success && ferror == nil) {
            return dir;
        }
        return @"";
    }
    return dir;
}
@end
