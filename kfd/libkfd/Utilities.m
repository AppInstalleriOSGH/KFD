//
//  Utilities.m
//  kfd
//
//  Created by AppInstaller iOS
//

#import <Foundation/Foundation.h>
#include "Utilities.h"
#include "libkfd.h"

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

//Lines 14-182 are from https://github.com/wh1te4ever/kfund
uint8_t kread8(u64 kfd, uint64_t where) {
    uint8_t out;
    kread(kfd, where, &out, sizeof(uint8_t));
    return out;
}

uint32_t kread16(u64 kfd, uint64_t where) {
    uint16_t out;
    kread(kfd, where, &out, sizeof(uint16_t));
    return out;
}

uint32_t kread32(u64 kfd, uint64_t where) {
    uint32_t out;
    kread(kfd, where, &out, sizeof(uint32_t));
    return out;
}

uint64_t kread64(u64 kfd, uint64_t where) {
    uint64_t out;
    kread(kfd, where, &out, sizeof(uint64_t));
    return out;
}

void kwrite8(u64 kfd, uint64_t where, uint8_t what) {
    uint8_t _buf[8] = {};
    _buf[0] = what;
    _buf[1] = kread8(kfd, where+1);
    _buf[2] = kread8(kfd, where+2);
    _buf[3] = kread8(kfd, where+3);
    _buf[4] = kread8(kfd, where+4);
    _buf[5] = kread8(kfd, where+5);
    _buf[6] = kread8(kfd, where+6);
    _buf[7] = kread8(kfd, where+7);
    kwrite((u64)(kfd), &_buf, where, sizeof(u64));
}

void kwrite16(u64 kfd, uint64_t where, uint16_t what) {
    u16 _buf[4] = {};
    _buf[0] = what;
    _buf[1] = kread16(kfd, where+2);
    _buf[2] = kread16(kfd, where+4);
    _buf[3] = kread16(kfd, where+6);
    kwrite((u64)(kfd), &_buf, where, sizeof(u64));
}

void kwrite32(u64 kfd, uint64_t where, uint32_t what) {
    u32 _buf[2] = {};
    _buf[0] = what;
    _buf[1] = kread32(kfd, where+4);
    kwrite((u64)(kfd), &_buf, where, sizeof(u64));
}

void kwrite64(u64 kfd, uint64_t where, uint64_t what) {
    u64 _buf[1] = {};
    _buf[0] = what;
    kwrite((u64)(kfd), &_buf, where, sizeof(u64));
}

uint64_t getProc(u64 kfd, pid_t pid) {
    uint64_t proc = ((struct kfd*)kfd)->info.kaddr.kernel_proc;
    while (true) {
        if(kread32(kfd, proc + off_p_pid) == pid) {
            return proc;
        }
        proc = kread64(kfd, proc + off_p_list_le_prev);
    }
    return 0;
}

uint64_t getVnodeAtPath(u64 kfd, char* filename) {
    int file_index = open(filename, O_RDONLY);
    if (file_index == -1) return -1;
    uint64_t proc = getProc(kfd, getpid());
    uint64_t filedesc_pac = kread64(kfd, proc + off_p_pfd);
    uint64_t filedesc = filedesc_pac | 0xffffff8000000000;
    uint64_t openedfile = kread64(kfd, filedesc + (8 * file_index));
    uint64_t fileglob_pac = kread64(kfd, openedfile + off_fp_glob);
    uint64_t fileglob = fileglob_pac | 0xffffff8000000000;
    uint64_t vnode_pac = kread64(kfd, fileglob + off_fg_data);
    uint64_t to_vnode = vnode_pac | 0xffffff8000000000;
    close(file_index);
    return to_vnode;
}

uint64_t getVnodeAtPathByChdir(u64 kfd, char *path) {
    if(access(path, F_OK) == -1) return -1;
    if(chdir(path) == -1) return -1;
    uint64_t fd_cdir_vp = kread64(kfd, getProc(kfd, getpid()) + off_p_pfd + off_fd_cdir);
    chdir("/");
    return fd_cdir_vp;
}

uint64_t funVnodeRedirectFolderFromVnode(u64 kfd, char* to, uint64_t from_vnode) {
    uint64_t to_vnode = getVnodeAtPathByChdir(kfd, to);
    if(to_vnode == -1) {
        printf("[-] Unable to get vnode, path: %s\n", to);
        return -1;
    }
    uint8_t to_v_references = kread8(kfd, to_vnode + off_vnode_v_references);
    uint32_t to_usecount = kread32(kfd, to_vnode + off_vnode_v_usecount);
    uint32_t to_v_kusecount = kread32(kfd, to_vnode + off_vnode_v_kusecount);
    uint64_t orig_to_v_data = kread64(kfd, to_vnode + off_vnode_v_data);
    //If mount point is different, return -1
    uint64_t to_devvp = kread64(kfd, (kread64(kfd, to_vnode + off_vnode_v_mount) | 0xffffff8000000000) + off_mount_mnt_devvp);
    uint64_t from_devvp = kread64(kfd, (kread64(kfd, from_vnode + off_vnode_v_mount) | 0xffffff8000000000) + off_mount_mnt_devvp);
    if(to_devvp != from_devvp) {
        printf("[-] mount points of folders are different!\n");
        return -1;
    }
    uint64_t from_v_data = kread64(kfd, from_vnode + off_vnode_v_data);
    kwrite32(kfd, to_vnode + off_vnode_v_usecount, to_usecount + 1);
    kwrite32(kfd, to_vnode + off_vnode_v_kusecount, to_v_kusecount + 1);
    kwrite8(kfd, to_vnode + off_vnode_v_references, to_v_references + 1);
    kwrite64(kfd, to_vnode + off_vnode_v_data, from_v_data);
    return orig_to_v_data;
}

uint64_t funVnodeUnRedirectFolder(u64 kfd, char* to, uint64_t orig_to_v_data) {
    uint64_t to_vnode = getVnodeAtPath(kfd, to);
    if(to_vnode == -1) {
        printf("[-] Unable to get vnode, path: %s\n", to);
        return -1;
    }
    uint8_t to_v_references = kread8(kfd, to_vnode + off_vnode_v_references);
    uint32_t to_usecount = kread32(kfd, to_vnode + off_vnode_v_usecount);
    uint32_t to_v_kusecount = kread32(kfd, to_vnode + off_vnode_v_kusecount);
    kwrite64(kfd, to_vnode + off_vnode_v_data, orig_to_v_data);
    if(to_usecount > 0)
        kwrite32(kfd, to_vnode + off_vnode_v_usecount, to_usecount - 1);
    if(to_v_kusecount > 0)
        kwrite32(kfd, to_vnode + off_vnode_v_kusecount, to_v_kusecount - 1);
    if(to_v_references > 0)
        kwrite8(kfd, to_vnode + off_vnode_v_references, to_v_references - 1);
    return 0;
}

uint64_t createFolderAndRedirect(u64 kfd, uint64_t vnode, NSString *mntPath) {
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:mntPath withIntermediateDirectories:NO attributes:nil error:nil];
    return funVnodeRedirectFolderFromVnode(kfd, mntPath.UTF8String, vnode);
}

uint64_t UnRedirectAndRemoveFolder(u64 kfd, uint64_t orig_to_v_data, NSString *mntPath) {
    funVnodeUnRedirectFolder(kfd, mntPath.UTF8String, orig_to_v_data);
    NSError* error;
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:&error];
    if (error) {
        print(error.localizedDescription.UTF8String);
    }
    return 0;
}

char* CStringFromNSString(NSString* string) {
    return string.UTF8String;
}

NSData* dataFromFile(u64 kfd, NSString* directoryPath, NSString* fileName) {
    NSString* mntPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    uint64_t orig_to_v_data = createFolderAndRedirect(kfd, getVnodeAtPathByChdir(kfd, directoryPath.UTF8String), mntPath);
    NSData* fileData = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", mntPath, fileName]];
    UnRedirectAndRemoveFolder(kfd, orig_to_v_data, mntPath);
    return fileData;
}

void writeDataToFile(u64 kfd, NSData* fileData, NSString* directoryPath, NSString* fileName) {
    NSString* mntPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    uint64_t orig_to_v_data = createFolderAndRedirect(kfd, getVnodeAtPathByChdir(kfd, directoryPath.UTF8String), mntPath);
    const void *_Nullable rawData = [fileData bytes];
    const char* data = (char *)rawData;
    int open_fd = open([NSString stringWithFormat:@"%@/%@", mntPath, fileName].UTF8String, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    write(open_fd, data, strlen(data));
    close(open_fd);
    UnRedirectAndRemoveFolder(kfd, orig_to_v_data, mntPath);
}

NSString* removeFile(u64 kfd, NSString* directoryPath, NSString* fileName) {
    NSString* mntPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    uint64_t orig_to_v_data = createFolderAndRedirect(kfd, getVnodeAtPathByChdir(kfd, directoryPath.UTF8String), mntPath);
    NSError* error;
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", mntPath, fileName] error:&error];
    if (error) {
        print(error.localizedDescription.UTF8String);
    }
    UnRedirectAndRemoveFolder(kfd, orig_to_v_data, mntPath);
    return error.localizedDescription;
}

NSString* makeSymlink(u64 kfd, NSString* directoryPath, NSString* fileName, NSString* destinationPath) {
    NSString* mntPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    uint64_t orig_to_v_data = createFolderAndRedirect(kfd, getVnodeAtPathByChdir(kfd, directoryPath.UTF8String), mntPath);
    NSError* error;
    [[NSFileManager defaultManager] createSymbolicLinkAtPath:[NSString stringWithFormat:@"%@/%@", mntPath, fileName] withDestinationPath:destinationPath error:&error];
    if (error) {
        print(error.localizedDescription.UTF8String);
    }
    UnRedirectAndRemoveFolder(kfd, orig_to_v_data, mntPath);
    return error.localizedDescription;
}

BOOL isFileDeletable(u64 kfd, NSString* directoryPath, NSString* fileName) {
    NSString* mntPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    uint64_t orig_to_v_data = createFolderAndRedirect(kfd, getVnodeAtPathByChdir(kfd, directoryPath.UTF8String), mntPath);
    BOOL isDeletable = [[NSFileManager defaultManager] isDeletableFileAtPath:[NSString stringWithFormat:@"%@/%@", mntPath, fileName]];
    UnRedirectAndRemoveFolder(kfd, orig_to_v_data, mntPath);
    return isDeletable;
}

NSString* createDirectory(u64 kfd, NSString* directoryPath, NSString* fileName) {
    NSString* mntPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    uint64_t orig_to_v_data = createFolderAndRedirect(kfd, getVnodeAtPathByChdir(kfd, directoryPath.UTF8String), mntPath);
    NSError* error;
    [[NSFileManager defaultManager] createDirectoryAtPath:[NSString stringWithFormat:@"%@/%@", mntPath, fileName] withIntermediateDirectories:NO attributes:nil error:&error];
    if (error) {
        print(error.localizedDescription.UTF8String);
    }
    UnRedirectAndRemoveFolder(kfd, orig_to_v_data, mntPath);
    return error.localizedDescription;
}

NSArray<NSString*>* contentsOfDirectory(u64 kfd, NSString* directoryPath) {
    NSString* mntPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    uint64_t orig_to_v_data = createFolderAndRedirect(kfd, getVnodeAtPathByChdir(kfd, directoryPath.UTF8String), mntPath);
    NSError* error;
    NSArray<NSString*>* directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:&error];
    if (error) {
        print(error.localizedDescription.UTF8String);
    }
    UnRedirectAndRemoveFolder(kfd, orig_to_v_data, mntPath);
    return directoryContents;
}

NSData* dataFromFileCopy(u64 kfd, NSString* directoryPath, NSString* fileName) {
    NSString* mntPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    NSString* copyPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    uint64_t orig_to_v_data = createFolderAndRedirect(kfd, getVnodeAtPathByChdir(kfd, directoryPath.UTF8String), mntPath);
    NSError* error;
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/%@", mntPath, fileName] toPath:copyPath error:&error];
    if (error) {
        print(error.localizedDescription.UTF8String);
    }
    NSData* fileData = [NSData dataWithContentsOfFile:copyPath];
    [[NSFileManager defaultManager] removeItemAtPath:copyPath error:&error];
    if (error) {
        print(error.localizedDescription.UTF8String);
    }
    UnRedirectAndRemoveFolder(kfd, orig_to_v_data, mntPath);
    return fileData;
}

BOOL isFileReadable(u64 kfd, NSString* directoryPath, NSString* fileName) {
    NSString* mntPath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), [[NSUUID UUID] UUIDString]];
    uint64_t orig_to_v_data = createFolderAndRedirect(kfd, getVnodeAtPathByChdir(kfd, directoryPath.UTF8String), mntPath);
    BOOL isReadable = [[NSFileManager defaultManager] isReadableFileAtPath:[NSString stringWithFormat:@"%@/%@", mntPath, fileName]];
    UnRedirectAndRemoveFolder(kfd, orig_to_v_data, mntPath);
    return isReadable;
}

void testProc(uint64_t kfd) {
    NSString* execPath = NSProcessInfo.processInfo.arguments[0];
    print(execPath.UTF8String);
    uint64_t ubc_info = kread64(kfd, getVnodeAtPath(kfd, execPath.UTF8String) + off_vnode_vu_ubcinfo) | 0xffffff8000000000;
    uint32_t cs_add_gen = kread32(kfd, ubc_info + off_ubc_info_cs_add_gen);
    printf("cs_add_gen: 0x%x\n", cs_add_gen);
    //kwrite32(kfd, ubc_info + off_ubc_info_cs_add_gen, cs_add_gen);
    uint64_t csblobs = kread64(kfd, ubc_info + off_ubc_info_cs_blobs);
    printf("csblobs: 0x%llx\n", csblobs);
    uint32_t csb_flags = kread32(kfd, csblobs + off_cs_blob_csb_flags);
    printf("csb_flags: 0x%x\n", csb_flags);
    uint64_t csb_teamid = kread64(kfd, csblobs + off_cs_blob_csb_teamid);
    printf("csb_teamid: 0x%llx\n", csb_teamid);
}
