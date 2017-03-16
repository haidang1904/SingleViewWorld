//
//  BLEdbcore.m
//  SingleViewWorld
//
//  Created by samsung on 2015. 8. 21..
//  Copyright (c) 2015년 samsung. All rights reserved.
//

#import "BLEdbcore.h"
#import "WowMacInfo.h"

NSString * const kEntityNameLocal = @"LocalName";
NSString * const kEntityNameWowMac = @"WowMac";

@interface BLEdbcore()

@property AppDelegate* appDelegate;
@property NSManagedObjectContext *context;

@end

@implementation BLEdbcore

#pragma mark -
#pragma mark Coredata
+ (instancetype)sharedInstance
{
    static BLEdbcore *sSharedInstance;
    static dispatch_once_t token;
    dispatch_once(&token, ^()
                  {
                      sSharedInstance = [[BLEdbcore alloc] init];
                  });
    
    return sSharedInstance;
}

- (instancetype)init
{
    self = [super init];
    
    if (self != nil)
    {
        self.appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        self.context = [self.appDelegate managedObjectContext];
    }
    
    return self;
}
- (void)createData:(NSString *)entityName object:(id)object
{
    if ([entityName isEqualToString:kEntityNameLocal])              // Local Name DB
    {
        PeripheralInfo *objectData = (PeripheralInfo *)object;
        [self updateBLEData:objectData];
    }
    else if([entityName isEqualToString:kEntityNameWowMac])         // WOW MAC DB
    {
        WowMacInfo *objectData = (WowMacInfo *)object;
        [self createWowData:objectData];
    }
    else
    {
        SVLogTEST(@"Entity name is not exist");
    }
    
}

- (void)updateData:(NSString *)entityName object:(id)object
{
    if ([entityName isEqualToString:kEntityNameLocal])              // Local Name DB
    {
        PeripheralInfo *objectData = (PeripheralInfo *)object;
        [self updateBLEData:objectData];
    }
}

- (id)readData:(NSString *)entityName Key:(id)attrName value:(id)value
{
    if ([entityName isEqualToString:kEntityNameLocal])              // Local Name DB
    {
        NSString *valueData = (NSString *)value;
        NSString *returnData;
        returnData = [self getBLEData:valueData];
        return returnData;
    }
    else if([entityName isEqualToString:kEntityNameWowMac])         // WOW MAC DB
    {
        NSArray *returnData = [NSArray array];
        returnData = [self readWowData:nil];
        return returnData;
    }
    return nil;
}

- (void)deleteData:(NSString *)entityName Key:(id)attrName value:(id)value
{
    if ([entityName isEqualToString:kEntityNameLocal])              // Local Name DB
    {
    }
    else if([entityName isEqualToString:kEntityNameWowMac])         // WOW MAC DB
    {
        WowMacInfo *valueData = (WowMacInfo *)value;
        [self deleteWowData:valueData];
    }
}

#pragma mark -
#pragma mark BLE Coredata CRUD
/*
    BLE Coredata CRUD
*/
- (void)createBLEData:(PeripheralInfo *)peripheralInfo
{
    SVLogTEST(@"createBLEData");
    NSManagedObject *newObject = [NSEntityDescription insertNewObjectForEntityForName:kEntityNameLocal inManagedObjectContext:_context];
    NSError *error;
    
    [newObject setValue:peripheralInfo.fakeName forKey:@"localname"];
    [newObject setValue:peripheralInfo.uuid forKey:@"uuid"];
    [_context save:&error];
}

- (NSManagedObject *)readBLEData:(NSString *)uuid
{
    NSManagedObject *ReturnData = nil;
    NSEntityDescription *Entity = [NSEntityDescription entityForName:kEntityNameLocal inManagedObjectContext:_context];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:Entity];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(uuid = %@)",uuid];
    [request setPredicate:pred];
    
    NSError *error;
    NSArray *objects = [_context executeFetchRequest:request error:&error];
    
    if([objects count] == 0)
    {
    }
    else
    {
        ReturnData = objects[[objects count]-1];
    }
    return ReturnData;
}

- (NSString *)getBLEData:(NSString *)uuid
{
    NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:kEntityNameLocal inManagedObjectContext:_context];
    
    NSString *ReturnData =  nil;

    object = [self readBLEData:uuid];
    if(object != nil)
    {
        ReturnData = [object valueForKey:@"localname"];
    }
    return ReturnData;
}

- (void)updateBLEData:(PeripheralInfo *)peripheralInfo
{
    NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:kEntityNameLocal inManagedObjectContext:_context];
    
    NSError *error;
    
    object = [self readBLEData:peripheralInfo.uuid];
    if(object != nil)
    {
        [object setValue:peripheralInfo.fakeName forKey:@"localname"];
        [object setValue:peripheralInfo.uuid forKey:@"uuid"];
        [_context save:&error];
        SVLogTEST(@"updateData complete");
    }
    else
    {
        [self createBLEData:peripheralInfo];
    }
}

#pragma mark -
#pragma mark WowMac Coredata CRUD
/*
    WowMac Coredata CRUD
*/
- (void)createWowData:(WowMacInfo *)macinfo
{
    SVLogTEST(@"createWowData");
    if(nil == [self readWowData:macinfo])
    {
        NSManagedObject *newObject = [NSEntityDescription insertNewObjectForEntityForName:kEntityNameWowMac inManagedObjectContext:_context];
        NSError *error;
        
        [newObject setValue:macinfo.mac1.uppercaseString forKey:@"mac1"];
        [newObject setValue:macinfo.mac2.uppercaseString forKey:@"mac2"];
        [newObject setValue:macinfo.mac3.uppercaseString forKey:@"mac3"];
        [newObject setValue:macinfo.mac4.uppercaseString forKey:@"mac4"];
        [newObject setValue:macinfo.mac5.uppercaseString forKey:@"mac5"];
        [newObject setValue:macinfo.mac6.uppercaseString forKey:@"mac6"];
        
        [_context save:&error];
        
        if(error)
        {
            SVLogTEST(@"DB update error:%@",error.localizedDescription);
        }
        else
        {
            SVLogTEST(@"DB update success");
        }
    }
    else
    {
        SVLogTEST(@"Mac address is already exist");
    }

}

- (NSArray *)readWowData:(WowMacInfo *)macinfo
{
    NSArray *ReturnData = nil;
    NSEntityDescription *Entity = [NSEntityDescription entityForName:kEntityNameWowMac inManagedObjectContext:_context];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:Entity];
    
    if(macinfo != nil)
    {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(mac1 = %@) AND (mac2 = %@) AND (mac3 = %@) AND (mac4 = %@) AND (mac5 = %@) AND (mac6 = %@)",macinfo.mac1,macinfo.mac2,macinfo.mac3,macinfo.mac4,macinfo.mac5,macinfo.mac6];
        [request setPredicate:pred];
    }
    
    NSError *error;
    NSArray *objects = [_context executeFetchRequest:request error:&error];

    if([objects count] != 0)
    {
        ReturnData = objects;
    }
    return ReturnData;
}

- (void)deleteWowData:(WowMacInfo *)macinfo
{
    NSArray *arr = [self readWowData:macinfo];
    if(nil != arr)
    {
        NSManagedObject *Object = (NSManagedObject *)arr[0];
        [_context deleteObject:Object];
        SVLogTEST(@"Mac address delete success");
    }
    else
    {
        SVLogTEST(@"Mac address is not exist");
    }
    
}
@end
