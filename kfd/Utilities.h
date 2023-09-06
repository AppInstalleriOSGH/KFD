//
//  Utilities.h
//  kfd
//
//  Created by AppInstaller iOS
//

#include <stdio.h>
#import <Foundation/Foundation.h>

void test(void);

void kreadbuf(uint64_t kaddr, void* output, size_t size);
uint64_t funVnodeChown(uint64_t vnode, uid_t uid, gid_t gid);
void funVnodeHide(uint64_t vnode);
uint64_t kopen(uint64_t puaf_pages, uint64_t puaf_method, uint64_t kread_method, uint64_t kwrite_method);
void kclose(uint64_t kfd);
uint64_t getProc(pid_t pid);
uint64_t getVnodeAtPathByChdir(char *path);
uint64_t funVnodeRedirectFolderFromVnode(char* to, uint64_t from_vnode);
uint64_t createFolderAndRedirect(uint64_t vnode, NSString *mntPath);
uint64_t UnRedirectAndRemoveFolder(uint64_t orig_to_v_data, NSString *mntPath);
char* CStringFromNSString(NSString* string);

//File Manager Stuff
uint64_t fileOverwrite(int fileIndex, NSData* fileData);
NSData* dataFromFile(NSString* directoryPath, NSString* fileName);
void writeDataToFile(NSData* fileData, NSString* directoryPath, NSString* fileName);
NSString* removeFile(NSString* directoryPath, NSString* fileName);
NSString* makeSymlink(NSString* directoryPath, NSString* fileName, NSString* destinationPath);
BOOL isFileDeletable(NSString* directoryPath, NSString* fileName);
NSString* createDirectory(NSString* directoryPath, NSString* fileName);
NSArray<NSString*>* contentsOfDirectory(NSString* directoryPath);
NSData* dataFromFileCopy(NSString* directoryPath, NSString* fileName);
BOOL isFileReadable(NSString* directoryPath, NSString* fileName);
