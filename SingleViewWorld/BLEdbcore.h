#ifndef BLEDBCORE_H
#define BLEDBCORE_H

//
//  BLEdbcore.h
//  SingleViewWorld
//
//  Created by samsung on 2015. 8. 21..
//  Copyright (c) 2015년 samsung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

extern NSString * const kEntityNameLocal;
extern NSString * const kEntityNameWowMac;

@class PeripheralInfo;
//@class WowMacInfo;

@interface BLEdbcore : NSObject

+ (instancetype)sharedInstance;

- (void)createData:(NSString *)entityName object:(id)object;
- (id)readData:(NSString *)entityName Key:(id)attrName value:(id)value;
- (void)updateData:(NSString *)entityName object:(id)object;
- (void)deleteData:(NSString *)entityName Key:(id)attrName value:(id)value;

@end

#endif
