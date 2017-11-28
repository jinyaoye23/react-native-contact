//
//  RNContact.m
//  RNContact
//
//  Created by Jason on 2017/11/7.
//  Copyright © 2017年 Jason. All rights reserved.
//

#import "RNContact.h"

#import "RCTContact.h"

#import "RCTBridgeModule.h"
#import "RCTBundleURLProvider.h"

#import <AddressBookUI/AddressBookUI.h>
#import <AddressBook/AddressBook.h>

@interface RNContact()<RCTBridgeModule, ABPeoplePickerNavigationControllerDelegate>

@property (copy, nonatomic) RCTResponseSenderBlock responseCallBack;
@property (nonatomic, strong) ABPeoplePickerNavigationController *peoplePicker;

@end


@implementation RNContact

RCT_EXPORT_MODULE(RNContact);

//打开通讯录选择器
RCT_EXPORT_METHOD(openContactPicker:(RCTResponseSenderBlock)callback){
    _responseCallBack = callback;
    
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    if (status == kABAuthorizationStatusAuthorized) {
        [self showContactPicker];
    } else if (status == kABAuthorizationStatusNotDetermined){
        CFErrorRef *error = nil;
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(nil, error);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
           
            if (granted) {
                // 有权限
               [self showContactPicker];
            } else {
                // 无权限
                NSDictionary* result  = @{@"status":@"10001", @"msg": @"无访问通讯录的权限"};
                _responseCallBack(@[result]);
            }
            
        });
    } else if (status == kABAuthorizationStatusRestricted || status == kABAuthorizationStatusDenied) {
        // 无权限
        NSDictionary* result  = @{@"status":@"10001", @"msg": @"无访问通讯录的权限"};
        _responseCallBack(@[result]);
    }
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (_peoplePicker == nil) {
//            _peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
//            _peoplePicker.displayedProperties = @[@(kABPersonPhoneProperty)];
//            _peoplePicker.peoplePickerDelegate = self;
//        }
//
//        [[self topViewController] presentViewController:_peoplePicker animated:YES completion:NULL];
//    });
}


//判断是否有通讯录权限
RCT_EXPORT_METHOD(checkContactPermissions:(RCTResponseSenderBlock)callback){
    _responseCallBack = callback;
    dispatch_async(dispatch_get_main_queue(), ^{
        CFErrorRef *error = nil;
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(nil, error);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            NSLog(@"granted==%d",granted);
            if (granted) {
                NSDictionary* result  = @{@"code":[NSNumber numberWithBool:true]};
                _responseCallBack(@[result]);
            } else {
                NSDictionary* result  = @{@"code":[NSNumber numberWithBool:false]};
                _responseCallBack(@[result]);
            }
        });
    });
}

-(void) showContactPicker {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_peoplePicker == nil) {
            _peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
            _peoplePicker.displayedProperties = @[@(kABPersonPhoneProperty)];
            _peoplePicker.peoplePickerDelegate = self;
        }
        
        [[self topViewController] presentViewController:_peoplePicker animated:YES completion:NULL];
    });
}

#pragma mark - ABPeoplePickerNavigationControllerDelegate
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)picker
{
    _responseCallBack(@[@{@"code":@"10002",@"msg":@"用户主动取消"}]);
    [_peoplePicker dismissViewControllerAnimated:YES completion:NULL];
}

// use in iOS7 or earlier
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    [self peoplePickerNavigationController:peoplePicker didSelectPerson:person];
    return NO;
}

// use in iOS7 or earlier
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    return YES;
//    [self handleSelectPerson:person property:property identifier:identifier];
//    _peoplePicker = nil;
//    return NO;
}

// Called after a property has been selected by the user.
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker didSelectPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    // not implemented
}

- (void) peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person
{
    _peoplePicker = peoplePicker;
//    NSNumber *pickerdId = [NSNumber numberWithInt:ABRecordGetRecordID(person)];
    
    RCTContact *pickedContact = [[RCTContact alloc] initFromABRecord:(ABRecordRef)person];
    
    NSArray * fields = [NSArray arrayWithObjects:@"*", nil];
//    NSArray * fields = ;
    NSDictionary * returnFields = [[RCTContact class] calcReturnFields:fields];
    NSDictionary *result = @{@"code":@"10000",@"data":[pickedContact toDictionary:returnFields]};
    
//    [peoplePicker presentationController] dismissViewControllerAnimated
    [peoplePicker dismissViewControllerAnimated:YES completion:^{
        _responseCallBack(@[result]);
    }];
}



// handle
//- (void)handleSelectPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier{
//    [_peoplePicker dismissViewControllerAnimated:YES completion:NULL];
//
//    ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, property);
//    NSString *phone = nil;
//    if ((ABMultiValueGetCount(phoneNumbers) > 0)) {
//        phone = (NSString *)CFBridgingRelease(ABMultiValueCopyValueAtIndex(phoneNumbers, identifier));
//    }
//    if (phone == nil) {
//        phone = @"";
//    }
//    NSString *phoneStr = [NSString stringWithString:phone];
//
//    NSString *firstName = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
//    NSString *lastName = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
//    if (!firstName) {
//        firstName = @"";
//    }
//    if (!lastName) {
//        lastName = @"";
//    }
//    NSString *nameStr = [NSString stringWithFormat:@"%@ %@",lastName,firstName];
//
//    NSDictionary* result = @{@"code":[NSNumber numberWithInt:0],@"data":@{@"name":nameStr,@"phone":phoneStr}};
//
//    _responseCallBack(@[result]);
//
//    _peoplePicker = nil;
//
//    NSLog(@"nameStr ---> %@,phoneStr ---> %@",nameStr,phoneStr);
//}


//获取当前视图控制器
- (UIViewController*)topViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    } else {
        return rootViewController;
    }
}

@end
