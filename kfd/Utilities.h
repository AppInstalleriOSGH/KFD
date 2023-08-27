//
//  Utilities.h
//  kfd
//
//  Created by AppInstaller iOS
//

#include <stdio.h>
#import <Foundation/Foundation.h>

uint64_t getTask(void);
uint64_t kread_ptr(uint64_t kaddr);
uint64_t vm_map_get_header(uint64_t vm_map_ptr);
uint64_t vm_map_header_get_first_entry(uint64_t vm_header_ptr);
uint64_t vm_map_entry_get_next_entry(uint64_t vm_entry_ptr);
uint32_t vm_header_get_nentries(uint64_t vm_header_ptr);
void vm_entry_get_range(uint64_t vm_entry_ptr, uint64_t *start_address_out, uint64_t *end_address_out);
void vm_map_iterate_entries(uint64_t vm_map_ptr, void (^itBlock)(uint64_t start, uint64_t end, uint64_t entry, BOOL *stop));
uint64_t vm_map_find_entry(uint64_t vm_map_ptr, uint64_t address);
void vm_map_entry_set_prot(uint64_t entry_ptr, vm_prot_t prot, vm_prot_t max_prot);
uint64_t start;
uint64_t end;
uint64_t task_get_vm_map(uint64_t task_ptr);
uint64_t funVnodeOverwrite2(int to_file_index, char* from);

NSArray<NSString*>* funVnodeIterateByVnode(uint64_t vnode);
uint64_t findChildVnodeByVnode(uint64_t vnode, NSString* childname);
uint64_t getKASLRSlide(void);
void kreadbuf(uint64_t kaddr, void* output, size_t size);
uint64_t funVnodeChown(uint64_t vnode, uid_t uid, gid_t gid);
void funVnodeHide(uint64_t vnode);
uint64_t kopen(uint64_t puaf_pages, uint64_t puaf_method, uint64_t kread_method, uint64_t kwrite_method);
void kclose(uint64_t kfd);
uint64_t getProc(pid_t pid);
uint64_t getVnodeAtPath(char* filename);
uint64_t getVnodeAtPathByChdir(char *path);
uint64_t funVnodeRedirectFolderFromVnode(char* to, uint64_t from_vnode);
uint64_t createFolderAndRedirect(uint64_t vnode, NSString *mntPath);
uint64_t UnRedirectAndRemoveFolder(uint64_t orig_to_v_data, NSString *mntPath);
char* CStringFromNSString(NSString* string);

//File Manager Stuff
NSData* dataFromFile(NSString* directoryPath, NSString* fileName);
void writeDataToFile(NSData* fileData, NSString* directoryPath, NSString* fileName);
NSString* removeFile(NSString* directoryPath, NSString* fileName);
NSString* makeSymlink(NSString* directoryPath, NSString* fileName, NSString* destinationPath);
BOOL isFileDeletable(NSString* directoryPath, NSString* fileName);
NSString* createDirectory(NSString* directoryPath, NSString* fileName);
NSArray<NSString*>* contentsOfDirectory(NSString* directoryPath);
NSData* dataFromFileCopy(NSString* directoryPath, NSString* fileName);
BOOL isFileReadable(NSString* directoryPath, NSString* fileName);
