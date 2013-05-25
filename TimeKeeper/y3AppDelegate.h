//
//  y3AppDelegate.h
//  TimeKeeper
//
//  Created by Yasuo Miyoshi on 12/06/28.
//  Copyright (c) 2012 Kochi Univ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface y3AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
