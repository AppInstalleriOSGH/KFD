/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#include <errno.h>
#include <mach/mach.h>
#include <pthread.h>
#include <semaphore.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <sys/sysctl.h>
#include <unistd.h>

#define min(a, b) (((a) < (b)) ? (a) : (b))
#define max(a, b) (((a) > (b)) ? (a) : (b))

typedef int8_t i8;
typedef int16_t i16;
typedef int32_t i32;
typedef int64_t i64;
typedef intptr_t isize;

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef uintptr_t usize;

#if CONFIG_PRINT
#define print(args...) printf(args)
#else /* CONFIG_PRINT */
#define print(args...)
#endif /* CONFIG_PRINT */
#define print_failure(args...) do { print("[%s]: 🔴 ", __FUNCTION__); print(args); print("\n"); } while (0)
#define print_buffer(uaddr, size)                                          \
    do {                                                                   \
        const u64 u64_per_line = 8;                                        \
        volatile u64* u64_base = (volatile u64*)(uaddr);                   \
        u64 u64_size = ((u64)(size) / sizeof(u64));                        \
        for (u64 u64_offset = 0; u64_offset < u64_size; u64_offset++) {    \
            if ((u64_offset % u64_per_line) == 0) {                        \
                print("[0x%04llx]: ", u64_offset * sizeof(u64));           \
            }                                                              \
            print("%016llx", u64_base[u64_offset]);                        \
            if ((u64_offset % u64_per_line) == (u64_per_line - 1)) {       \
                print("\n");                                               \
            } else {                                                       \
                print(" ");                                                \
            }                                                              \
        }                                                                  \
        if ((u64_size % u64_per_line) != 0) {                              \
            print("\n");                                                   \
        }                                                                  \
    } while (0)

#if CONFIG_ASSERT

#define assert(condition)                                               \
    do {                                                                \
        if (!(condition)) {                                             \
            print_failure("assertion failed: (%s)", #condition);        \
            print_failure("file: %s, line: %d", __FILE__, __LINE__);    \
            print_failure("... sleep(30) before exit(1) ...");          \
            sleep(30);                                                  \
            exit(1);                                                    \
        }                                                               \
    } while (0)

#else /* CONFIG_ASSERT */
#define assert(condition)
#endif /* CONFIG_ASSERT */
#define assert_false(message)                   \
    do {                                        \
        print_failure("error: %s", message);    \
        assert(false);                          \
    } while (0)

#define assert_bsd(statement)                                                                        \
    do {                                                                                             \
        kern_return_t kret = (statement);                                                            \
        if (kret != KERN_SUCCESS) {                                                                  \
            print_failure("bsd error: kret = %d, errno = %d (%s)", kret, errno, strerror(errno));    \
            assert(kret == KERN_SUCCESS);                                                            \
        }                                                                                            \
    } while (0)

#define assert_mach(statement)                                                             \
    do {                                                                                   \
        kern_return_t kret = (statement);                                                  \
        if (kret != KERN_SUCCESS) {                                                        \
            print_failure("mach error: kret = %d (%s)", kret, mach_error_string(kret));    \
            assert(kret == KERN_SUCCESS);                                                  \
        }                                                                                  \
    } while (0)

#define malloc_bzero(size)               \
    ({                                   \
        void* pointer = malloc(size);    \
        assert(pointer != NULL);         \
        bzero(pointer, size);            \
        pointer;                         \
    })

#define bzero_free(pointer, size)    \
    do {                             \
        bzero(pointer, size);        \
        free(pointer);               \
        pointer = NULL;              \
    } while (0)
