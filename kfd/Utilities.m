//
//  Utilities.m
//  kfd
//
//  Created by AppInstaller iOS
//

#import <Foundation/Foundation.h>
#include "Utilities.h"
#include "libkfd.h"
#include <sys/stat.h>

//Offsets
uint32_t off_p_list_le_prev = 0x8;
uint32_t off_p_proc_ro = 0x18;
uint32_t off_p_ppid = 0x20;
uint32_t off_p_original_ppid = 0x24;
uint32_t off_p_pgrpid = 0x28;
uint32_t off_p_uid = 0x2c;
uint32_t off_p_gid = 0x30;
uint32_t off_p_ruid = 0x34;
uint32_t off_p_rgid = 0x38;
uint32_t off_p_svuid = 0x3c;
uint32_t off_p_svgid = 0x40;
uint32_t off_p_sessionid = 0x44;
uint32_t off_p_puniqueid = 0x48;
uint32_t off_p_pid = 0x60;
uint32_t off_p_pfd = 0xf8;
uint32_t off_p_textvp = 0x350;
uint32_t off_p_name = 0x381;
uint32_t off_p_ro_p_csflags = 0x1c;
uint32_t off_p_ro_p_ucred = 0x20;
uint32_t off_p_ro_pr_proc = 0;
uint32_t off_p_ro_pr_task = 0x8;
uint32_t off_p_ro_t_flags_ro = 0x78;
uint32_t off_u_cr_label = 0x78;
uint32_t off_u_cr_posix = 0x18;
uint32_t off_cr_uid = 0;
uint32_t off_cr_ruid = 0x4;
uint32_t off_cr_svuid = 0x8;
uint32_t off_cr_ngroups = 0xc;
uint32_t off_cr_groups = 0x10;
uint32_t off_cr_rgid = 0x50;
uint32_t off_cr_svgid = 0x54;
uint32_t off_cr_gmuid = 0x58;
uint32_t off_cr_flags = 0x5c;
uint32_t off_task_itk_space = 0x300;
uint32_t off_task_t_flags = 0x3D0;
uint32_t off_fd_ofiles = 0;
uint32_t off_fd_cdir = 0x20;
uint32_t off_fp_glob = 0x10;
uint32_t off_fg_data = 0x38;
uint32_t off_fg_flag = 0x10;
uint32_t off_vnode_v_ncchildren_tqh_first = 0x30;
uint32_t off_vnode_v_iocount = 0x64;
uint32_t off_vnode_v_usecount = 0x60;
uint32_t off_vnode_v_flag = 0x54;
uint32_t off_vnode_v_name = 0xb8;
uint32_t off_vnode_v_mount = 0xd8;
uint32_t off_vnode_v_data = 0xe0;
uint32_t off_vnode_v_kusecount = 0x5c;
uint32_t off_vnode_v_references = 0x5b;
uint32_t off_vnode_v_lflag = 0x58;
uint32_t off_vnode_v_owner = 0x68;
uint32_t off_vnode_v_parent = 0xc0;
uint32_t off_vnode_v_label = 0xe8;
uint32_t off_vnode_v_cred = 0x98;
uint32_t off_vnode_v_writecount = 0xb0;
uint32_t off_vnode_v_type = 0x70;
uint32_t off_vnode_vu_ubcinfo = 0x78;
uint32_t off_mount_mnt_data = 0x11F;
uint32_t off_mount_mnt_fsowner = 0x9c0;
uint32_t off_mount_mnt_fsgroup = 0x9c4;
uint32_t off_mount_mnt_devvp = 0x980;
uint32_t off_mount_mnt_flag = 0x70;
uint32_t off_specinfo_si_flags = 0x10;
uint32_t off_namecache_nc_vp = 0x48;
uint32_t off_namecache_nc_child_tqe_prev = 0x10;
uint32_t off_ipc_space_is_table = 0x20;
uint32_t off_ubc_info_cs_blobs = 0x50;
uint32_t off_ubc_info_cs_add_gen = 0x2c;
uint32_t off_cs_blob_csb_pmap_cs_entry = 0xb8;
uint32_t off_cs_blob_csb_cdhash = 0x58;
uint32_t off_cs_blob_csb_flags = 0x20;
uint32_t off_cs_blob_csb_teamid = 0x88;
uint32_t off_cs_blob_csb_validation_category = 0xb0;     
uint32_t off_pmap_cs_code_directory_ce_ctx = 0x1c8;
uint32_t off_pmap_cs_code_directory_der_entitlements_size = 0x1d8;
uint32_t off_pmap_cs_code_directory_trust = 0x1dc;
uint32_t off_ipc_entry_ie_object = 0;
uint32_t off_ipc_object_io_bits = 0;
uint32_t off_ipc_object_io_references = 0x4;
uint32_t off_ipc_port_ip_kobject = 0x48; 

//Lines 96-279 are from https://github.com/wh1te4ever/kfund
uint8_t kread8(uint64_t where) {
    uint8_t out;
    kread(_kfd, where, &out, sizeof(uint8_t));
    return out;
}

uint32_t kread16(uint64_t where) {
    uint16_t out;
    kread(_kfd, where, &out, sizeof(uint16_t));
    return out;
}

uint32_t kread32(uint64_t where) {
    uint32_t out;
    kread(_kfd, where, &out, sizeof(uint32_t));
    return out;
}

uint64_t kread64(uint64_t where) {
    uint64_t out;
    kread(_kfd, where, &out, sizeof(uint64_t));
    return out;
}

void kwrite8(uint64_t where, uint8_t what) {
    uint8_t _buf[8] = {};
    _buf[0] = what;
    _buf[1] = kread8(where+1);
    _buf[2] = kread8(where+2);
    _buf[3] = kread8(where+3);
    _buf[4] = kread8(where+4);
    _buf[5] = kread8(where+5);
    _buf[6] = kread8(where+6);
    _buf[7] = kread8(where+7);
    kwrite((u64)(_kfd), &_buf, where, sizeof(u64));
}

void kwrite16(uint64_t where, uint16_t what) {
    u16 _buf[4] = {};
    _buf[0] = what;
    _buf[1] = kread16(where+2);
    _buf[2] = kread16(where+4);
    _buf[3] = kread16(where+6);
    kwrite((u64)(_kfd), &_buf, where, sizeof(u64));
}

void kwrite32(uint64_t where, uint32_t what) {
    u32 _buf[2] = {};
    _buf[0] = what;
    _buf[1] = kread32(where+4);
    kwrite((u64)(_kfd), &_buf, where, sizeof(u64));
}

void kwrite64(uint64_t where, uint64_t what) {
    u64 _buf[1] = {};
    _buf[0] = what;
    kwrite((u64)(_kfd), &_buf, where, sizeof(u64));
}

uint64_t getProc(pid_t pid) {
    uint64_t proc = ((struct kfd*)_kfd)->info.kaddr.kernel_proc;
    while (true) {
        if(kread32(proc + off_p_pid) == pid) {
            return proc;
        }
        proc = kread64(proc + off_p_list_le_prev);
    }
    return 0;
}

uint64_t getVnodeAtPath(char* filename) {
    int file_index = open(filename, O_RDONLY);
    if (file_index == -1) return -1;
    uint64_t proc = getProc(getpid());
    uint64_t filedesc_pac = kread64(proc + off_p_pfd);
    uint64_t filedesc = filedesc_pac | 0xffffff8000000000;
    uint64_t openedfile = kread64(filedesc + (8 * file_index));
    uint64_t fileglob_pac = kread64(openedfile + off_fp_glob);
    uint64_t fileglob = fileglob_pac | 0xffffff8000000000;
    uint64_t vnode_pac = kread64(fileglob + off_fg_data);
    uint64_t to_vnode = vnode_pac | 0xffffff8000000000;
    close(file_index);
    return to_vnode;
}

uint64_t getVnodeAtPathByChdir(char *path) {
    if(access(path, F_OK) == -1) {
        printf("no access to %s\n", path);
        return -1;
    }
    if(chdir(path) == -1) {
        printf("cant chdir to %s\n", path);
        return -1;
    }
    uint64_t fd_cdir_vp = kread64(getProc(getpid()) + off_p_pfd + off_fd_cdir);
    chdir("/");
    return fd_cdir_vp;
}

uint64_t funVnodeRedirectFolderFromVnode(char* to, uint64_t from_vnode) {
    uint64_t to_vnode = getVnodeAtPathByChdir(to);
    if(to_vnode == -1) {
        printf("[-] Unable to get vnode, path: %s\n", to);
        return -1;
    }
    uint8_t to_v_references = kread8(to_vnode + off_vnode_v_references);
    uint32_t to_usecount = kread32(to_vnode + off_vnode_v_usecount);
    uint32_t to_v_kusecount = kread32(to_vnode + off_vnode_v_kusecount);
    uint64_t orig_to_v_data = kread64(to_vnode + off_vnode_v_data);
    //If mount point is different, return -1
    uint64_t to_devvp = kread64((kread64(to_vnode + off_vnode_v_mount) | 0xffffff8000000000) + off_mount_mnt_devvp);
    uint64_t from_devvp = kread64((kread64(from_vnode + off_vnode_v_mount) | 0xffffff8000000000) + off_mount_mnt_devvp);
    if(to_devvp != from_devvp) {
        printf("[-] mount points of folders are different!\n");
        return -1;
    }
    uint64_t from_v_data = kread64(from_vnode + off_vnode_v_data);
    kwrite32(to_vnode + off_vnode_v_usecount, to_usecount + 1);
    kwrite32(to_vnode + off_vnode_v_kusecount, to_v_kusecount + 1);
    kwrite8(to_vnode + off_vnode_v_references, to_v_references + 1);
    kwrite64(to_vnode + off_vnode_v_data, from_v_data);
    return orig_to_v_data;
}

uint64_t funVnodeUnRedirectFolder(char* to, uint64_t orig_to_v_data) {
    uint64_t to_vnode = getVnodeAtPath(to);
    if(to_vnode == -1) {
        printf("[-] Unable to get vnode, path: %s\n", to);
        return -1;
    }
    uint8_t to_v_references = kread8(to_vnode + off_vnode_v_references);
    uint32_t to_usecount = kread32(to_vnode + off_vnode_v_usecount);
    uint32_t to_v_kusecount = kread32(to_vnode + off_vnode_v_kusecount);
    kwrite64(to_vnode + off_vnode_v_data, orig_to_v_data);
    if(to_usecount > 0)
        kwrite32(to_vnode + off_vnode_v_usecount, to_usecount - 1);
    if(to_v_kusecount > 0)
        kwrite32(to_vnode + off_vnode_v_kusecount, to_v_kusecount - 1);
    if(to_v_references > 0)
        kwrite8(to_vnode + off_vnode_v_references, to_v_references - 1);
    return 0;
}

uint64_t funVnodeIterateByVnode(uint64_t vnode) {
    char vp_name[256];
    kreadbuf(kread64(vnode + off_vnode_v_name), &vp_name, 256);
    printf("Parent vnode name: %s, vnode: 0x%llx\n", vp_name, vnode);
    uint64_t vp_namecache = kread64(vnode + off_vnode_v_ncchildren_tqh_first); 
    //vp_namecache = kread64(vp_namecache + 0x0);
    
    for (int i = 1; i <= 3; i++) {
        if(vp_namecache == 0)
            break;
        vnode = kread64(vp_namecache + off_namecache_nc_vp);
        if(vnode == 0)
            break;
        kreadbuf(kread64(vnode + off_vnode_v_name), &vp_name, 256);
        printf("Child vnode name: %s, vnode: 0x%llx\n", vp_name, vnode);
        vp_namecache = kread64(vp_namecache + 0x0);
    }
    return 0;
}

void kreadbuf(uint64_t kaddr, void* output, size_t size) {
    uint64_t endAddr = kaddr + size;
    uint32_t outputOffset = 0;
    unsigned char* outputBytes = (unsigned char*)output;
    for(uint64_t curAddr = kaddr; curAddr < endAddr; curAddr += 4) {
        uint32_t k = kread32(curAddr);
        unsigned char* kb = (unsigned char*)&k;
        for(int i = 0; i < 4; i++) {
            if(outputOffset == size) break;
            outputBytes[outputOffset] = kb[i];
            outputOffset++;
        }
        if(outputOffset == size) break;
    }
}

uint64_t createFolderAndRedirect(uint64_t vnode, NSString *mntPath) {
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:mntPath withIntermediateDirectories:NO attributes:nil error:nil];
    return funVnodeRedirectFolderFromVnode(mntPath.UTF8String, vnode);
}

uint64_t UnRedirectAndRemoveFolder(uint64_t orig_to_v_data, NSString *mntPath) {
    funVnodeUnRedirectFolder(mntPath.UTF8String, orig_to_v_data);
    NSError* error;
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:&error];
    if (error) {
        print(error.localizedDescription.UTF8String);
    }
    return 0;
}

void funVnodeHide(uint64_t vnode) {
    uint32_t usecount = kread32(vnode + off_vnode_v_usecount);
    uint32_t iocount = kread32(vnode + off_vnode_v_iocount);
    printf("[i] vnode->usecount: %d, vnode->iocount: %d\n", usecount, iocount);
    kwrite32(vnode + off_vnode_v_usecount, usecount + 1);
    kwrite32(vnode + off_vnode_v_iocount, iocount + 1);
    uint32_t v_flags = kread32(vnode + off_vnode_v_flag);
    printf("[i] vnode->v_flags: 0x%x\n", v_flags);
    kwrite32(vnode + off_vnode_v_flag, (v_flags | 0x008000));
    usecount = kread32(vnode + off_vnode_v_usecount);
    iocount = kread32(vnode + off_vnode_v_iocount);
    if(usecount > 0)
        kwrite32(vnode + off_vnode_v_usecount, usecount - 1);
    if(iocount > 0)
        kwrite32(vnode + off_vnode_v_iocount, iocount - 1);
}

uint64_t funVnodeChown(uint64_t vnode, uid_t uid, gid_t gid) {
    if(vnode == -1) {
        printf("Invalid vnode");
        return -1;
    }
    uint64_t v_data = kread64(vnode + off_vnode_v_data);
    uint32_t v_uid = kread32(v_data + 0x80);
    uint32_t v_gid = kread32(v_data + 0x84);    
    printf("Patching vnode->v_uid %d -> %d\n", v_uid, uid);
    kwrite32(v_data+0x80, uid);
    printf("Patching vnode->v_gid %d -> %d\n", v_gid, gid);
    kwrite32(v_data+0x84, gid);
    return 0;
}

char* CStringFromNSString(NSString* string) {
    printf("test 12\n");
    return string.UTF8String;
}

NSData* dataFromFile(NSString* directoryPath, NSString* fileName) {
    NSString* mntPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    uint64_t orig_to_v_data = createFolderAndRedirect(getVnodeAtPathByChdir(directoryPath.UTF8String), mntPath);
    NSData* fileData = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", mntPath, fileName]];
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    return fileData;
}

void writeDataToFile(NSData* fileData, NSString* directoryPath, NSString* fileName) {
    NSString* mntPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    uint64_t orig_to_v_data = createFolderAndRedirect(getVnodeAtPathByChdir(directoryPath.UTF8String), mntPath);
    const void *_Nullable rawData = [fileData bytes];
    const char* data = (char *)rawData;
    int open_fd = open([NSString stringWithFormat:@"%@/%@", mntPath, fileName].UTF8String, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    write(open_fd, data, strlen(data));
    close(open_fd);
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
}

NSString* removeFile(NSString* directoryPath, NSString* fileName) {
    NSString* mntPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    uint64_t orig_to_v_data = createFolderAndRedirect(getVnodeAtPathByChdir(directoryPath.UTF8String), mntPath);
    NSError* error;
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", mntPath, fileName] error:&error];
    if (error) {
        print(error.localizedDescription.UTF8String);
    }
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    return error.localizedDescription;
}

NSString* makeSymlink(NSString* directoryPath, NSString* fileName, NSString* destinationPath) {
    NSString* mntPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    uint64_t orig_to_v_data = createFolderAndRedirect(getVnodeAtPathByChdir(directoryPath.UTF8String), mntPath);
    NSError* error;
    [[NSFileManager defaultManager] createSymbolicLinkAtPath:[NSString stringWithFormat:@"%@/%@", mntPath, fileName] withDestinationPath:destinationPath error:&error];
    if (error) {
        print(error.localizedDescription.UTF8String);
    }
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    return error.localizedDescription;
}

BOOL isFileDeletable(NSString* directoryPath, NSString* fileName) {
    NSString* mntPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    uint64_t orig_to_v_data = createFolderAndRedirect(getVnodeAtPathByChdir(directoryPath.UTF8String), mntPath);
    BOOL isDeletable = [[NSFileManager defaultManager] isDeletableFileAtPath:[NSString stringWithFormat:@"%@/%@", mntPath, fileName]];
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    return isDeletable;
}

NSString* createDirectory(NSString* directoryPath, NSString* fileName) {
    NSString* mntPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    uint64_t orig_to_v_data = createFolderAndRedirect(getVnodeAtPathByChdir(directoryPath.UTF8String), mntPath);
    NSError* error;
    [[NSFileManager defaultManager] createDirectoryAtPath:[NSString stringWithFormat:@"%@/%@", mntPath, fileName] withIntermediateDirectories:NO attributes:nil error:&error];
    if (error) {
        print(error.localizedDescription.UTF8String);
    }
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    return error.localizedDescription;
}

NSArray<NSString*>* contentsOfDirectory(NSString* directoryPath) {
    NSString* mntPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    uint64_t orig_to_v_data = createFolderAndRedirect(getVnodeAtPathByChdir(directoryPath.UTF8String), mntPath);
    NSError* error;
    NSArray<NSString*>* directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:&error];
    if (error) {
        print(error.localizedDescription.UTF8String);
    }
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    return directoryContents;
}

NSData* dataFromFileCopy(NSString* directoryPath, NSString* fileName) {
    NSString* mntPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    NSString* copyPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    uint64_t orig_to_v_data = createFolderAndRedirect(getVnodeAtPathByChdir(directoryPath.UTF8String), mntPath);
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/%@", mntPath, fileName] toPath:copyPath error:nil];
    NSData* fileData = [NSData dataWithContentsOfFile:copyPath];
    [[NSFileManager defaultManager] removeItemAtPath:copyPath error:nil];
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    return fileData;
}

BOOL isFileReadable(NSString* directoryPath, NSString* fileName) {
    NSString* mntPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    uint64_t orig_to_v_data = createFolderAndRedirect(getVnodeAtPathByChdir(directoryPath.UTF8String), mntPath);
    BOOL isReadable = [[NSFileManager defaultManager] isReadableFileAtPath:[NSString stringWithFormat:@"%@/%@", mntPath, fileName]];
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    return isReadable;
}

uint64_t getKASLRSlide(void) {
    return ((struct kfd*)_kfd)->perf.kernel_slide;
}
