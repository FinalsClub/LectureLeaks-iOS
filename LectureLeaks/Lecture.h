//
//  Lecture.h
//  CopRecorder
//
//  Created by Christopher Ballinger on 6/9/11.
//  Copyright 2011. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Lecture : NSObject 
{
    NSString *title;
    NSString *className;
    NSString *school;
    NSString *fileName;
    NSDate *date;
} 

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *className;
@property (nonatomic, retain) NSString *school;
@property (nonatomic, retain) NSString *fileName;
@property (nonatomic, retain) NSDate *date;

+ (id)lectureWithTitle:(NSString*)title className:(NSString*)className school:(NSString*)school fileName:(NSString*)fileName date:(NSDate*)date;

@end