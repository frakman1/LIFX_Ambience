//
//  AppDelegate.h
//  LIFX Ambience
//
//  Created by alnaumf on 6/22/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <LIFXKit/LIFXKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    NSString *udid;
}

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong,nonatomic) NSString *udid;

//used to save the state of the light in main page before leaving
@property (nonatomic) NSMutableDictionary *backupLights;
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@property (nonatomic) LFXTaggedLightCollection *tagged;

@end