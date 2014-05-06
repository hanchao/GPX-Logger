//
//  LogsViewController.m
//  GPSLogger
//
//  Created by NextBusinessSystem on 12/01/26.
//  Copyright (c) 2012 NextBusinessSystem Co., Ltd. All rights reserved.
//

#import "LogsViewController.h"
#import "IBCoreDataStore.h"
#import "IBFunctions.h"
#import "NSManagedObject+InnerBand.h"
#import "Track.h"
#import "TrackPoint.h"
#import "LogTabBarController.h"
#import "MapViewController.h"

@interface LogsViewController ()
@property (strong, nonatomic) NSArray *tracks;
@end

@interface LogsViewController (UITableViewDataSource) <UITableViewDataSource>
@end

@interface LogsViewController (UITableViewDelegate) <UITableViewDelegate>
@end



@implementation LogsViewController

@synthesize tracks = __tracks;


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSError *error;
    self.tracks = [[IBCoreDataStore mainStore] allForEntity:@"Track" orderBy:@"created" ascending:NO error:&error];
    if (error) {
        NSLog(@"%@", error);
    }

    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PushLogTabBarController"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        Track *track = [self.tracks objectAtIndex:indexPath.row];

        LogTabBarController *viewController = (LogTabBarController *)segue.destinationViewController;
        viewController.track = track;
    }
}

@end


#pragma mark - 
@implementation LogsViewController (UITableViewDataSource)

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tracks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    Track *track = [self.tracks objectAtIndex:indexPath.row];
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *text = [formatter stringFromDate:track.created];
    
    cell.textLabel.text = text;
    
    
    double distance = 0.0;
    
    NSArray *trackPoints = track.sotredTrackPoints;
    CLLocation* locations[trackPoints.count];
    
    int i = 0;
    for (TrackPoint *trackPoint in trackPoints) {
        locations[i] = [[CLLocation alloc] initWithLatitude:trackPoint.latitude.doubleValue longitude:trackPoint.longitude.doubleValue];
        i++;
    }
    
    for (int i=1; i<trackPoints.count; i++) {
        CLLocationDistance newDistance = [locations[i-1] distanceFromLocation:locations[i]];
        distance += newDistance;
    }
    
    NSString *distanceString;
    if (distance < 1000) {
        distanceString = [NSString stringWithFormat:@"%.2f%@", distance, NSLocalizedString(@"m", nil)];
    }
    else
    {
        distanceString = [NSString stringWithFormat:@"%.2f%@", distance/1000, NSLocalizedString(@"km", nil)];
    }
    
    NSTimeInterval time = 0.0;
    if (trackPoints.count>0) {
        TrackPoint *startPoint = (TrackPoint *)[trackPoints firstObject];
        TrackPoint *endPoint = (TrackPoint *)[trackPoints lastObject];
        time = [endPoint.created timeIntervalSinceDate:startPoint.created];
    }


    NSUInteger seconds = (NSUInteger)round(time);
    NSString *timeString = [NSString stringWithFormat:@"%02u:%02u:%02u",
                        seconds / 3600, (seconds / 60) % 60, seconds % 60];
    

    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ %@ %@", NSLocalizedString(@"Distance", nil), distanceString, NSLocalizedString(@"Used time", nil), timeString];
    

    return cell;
}

@end


#pragma mark -
@implementation LogsViewController (UITableViewDelegate)

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Track *track = [self.tracks objectAtIndex:indexPath.row];
        
        NSMutableArray *array = [NSMutableArray arrayWithArray:self.tracks];
        [array removeObject:track];
        self.tracks = [NSArray arrayWithArray:array];
        
        [track destroy];
        [[IBCoreDataStore mainStore] save];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end
