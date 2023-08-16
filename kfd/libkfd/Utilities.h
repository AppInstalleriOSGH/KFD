//
//  Utilities.h
//  kfd
//
//  Created by AppInstaller iOS
//

#include <stdio.h>
#import <Foundation/Foundation.h>

uint64_t funVnodeChown(uint64_t kfd, uint64_t vnode, uid_t uid, gid_t gid);
void funVnodeHide(uint64_t kfd, uint64_t vnode);
uint64_t kopen(uint64_t puaf_pages, uint64_t puaf_method, uint64_t kread_method, uint64_t kwrite_method);
void kclose(uint64_t kfd);
uint64_t getProc(uint64_t kfd, pid_t pid);
uint64_t getVnodeAtPath(uint64_t kfd, char* filename);
uint64_t getVnodeAtPathByChdir(uint64_t kfd, char *path);
uint64_t funVnodeRedirectFolderFromVnode(uint64_t kfd, char* to, uint64_t from_vnode);
uint64_t createFolderAndRedirect(uint64_t kfd, uint64_t vnode, NSString *mntPath);
uint64_t UnRedirectAndRemoveFolder(uint64_t kfd, uint64_t orig_to_v_data, NSString *mntPath);
char* CStringFromNSString(NSString* string);

//File Manager Stuff
NSData* dataFromFile(uint64_t kfd, NSString* directoryPath, NSString* fileName);
void writeDataToFile(uint64_t kfd, NSData* fileData, NSString* directoryPath, NSString* fileName);
NSString* removeFile(uint64_t kfd, NSString* directoryPath, NSString* fileName);
NSString* makeSymlink(uint64_t kfd, NSString* directoryPath, NSString* fileName, NSString* destinationPath);
BOOL isFileDeletable(uint64_t kfd, NSString* directoryPath, NSString* fileName);
NSString* createDirectory(uint64_t kfd, NSString* directoryPath, NSString* fileName);
NSArray<NSString*>* contentsOfDirectory(uint64_t kfd, NSString* directoryPath);
NSData* dataFromFileCopy(uint64_t kfd, NSString* directoryPath, NSString* fileName);
BOOL isFileReadable(uint64_t kfd, NSString* directoryPath, NSString* fileName);
