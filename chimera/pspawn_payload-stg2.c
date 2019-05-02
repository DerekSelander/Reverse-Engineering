
#include <sys/spawn.h>

#define CS_OPS_STATUS 0

struct substitute_image {
    intptr_t slide;
    void *dlhandle;
    const void *image_header;
};

struct substitute_function_hook {
    void *function;
    void *replacement;
    void *old_ptr;
    int options;
};

enum {
    SUBSTITUTE_NO_THREAD_SAFETY = 1,
};

int substitute_find_private_syms(struct substitute_image *handle, const char **__restrict names, void **__restrict syms, size_t nsyms);
int substitute_hook_functions(const struct substitute_function_hook *hooks, size_t nhooks, void **recordp, int options);
struct substitute_image *substitute_open_image(const char *filename);

enum sandbox_filter_type {
    SANDBOX_FILTER_NONE,
    SANDBOX_FILTER_PATH,
    SANDBOX_FILTER_GLOBAL_NAME,
    SANDBOX_FILTER_LOCAL_NAME,
    SANDBOX_FILTER_APPLEEVENT_DESTINATION,
    SANDBOX_FILTER_RIGHT_NAME,
};
extern const enum sandbox_filter_type SANDBOX_CHECK_NO_REPORT __attribute__((weak_import));
int sandbox_check(pid_t pid, const char *operation, enum sandbox_filter_type type, ...);

// used to trigger the CoreTrust bypass
int jbd_file_op(mach_port_t port, char a2, uint64_t a3, char *path, unsigned int len);
signed long long jbd_call(mach_port_t port, char a2, int a3);

int (*old_fcntl)(int fd, int b);
int fake_fcntl(int fd, int b) {
    if (b == F_ADDFILESIGS_RETURN) return -1;
    if (b == F_CHECK_LV) return 0;
    return old_fcntl(fd, b);
}

int (*old_fcntl2)(int fd, int b);
int fake_fcntl2(int fd, int b) {
    if (b == F_CHECK_LV) {
        errno = 0;
        return 0;
    }
    return old_fcntl2(fd, b);
}

int csops(pid_t pid, unsigned int ops, void* useraddr, size_t usersize);
int csops_audittoken(pid_t pid, unsigned int  ops, void* useraddr, size_t usersize, audit_token_t* token);

int (*old_csops)(pid_t pid, unsigned int ops, unsigned int *useraddr, size_t usersize);
int fake_csops(pid_t pid, unsigned int ops, unsigned int *useraddr, size_t usersize) {
    int orig = old_csops(pid, ops, useraddr, usersize);
    
    if (ops == CS_OPS_STATUS) {
        if (useraddr) {
            *useraddr &= 0xefffffff;
            *useraddr |= 1;
        }
    }
    return orig;
}

int (*old_csops_audittoken)(pid_t pid, unsigned int  ops, unsigned int* useraddr, size_t usersize, audit_token_t* token);
int fake_csops_audittoken(pid_t pid, unsigned int  ops, unsigned int* useraddr, size_t usersize, audit_token_t* token) {
    int orig = old_csops_audittoken(pid, ops, useraddr, usersize, token);
    
    if (ops == CS_OPS_STATUS) {
        if (useraddr) {
            *useraddr &= 0xefffffff;
            *useraddr |= 1;
        }
    }
    return orig;
}

// getting rid of signaures? hmm

const char *(*ImagePath)(void);
uint64_t (*old_hasCodeSignature)(uint64_t a, uint64_t b, uint64_t c);
uint64_t fake_hasCodeSignature(uint64_t a, uint64_t b, uint64_t c) {
    const char *path = ImagePath();
    if (!strcmp(path, "/usr/lib/libobjc-trampolines.dylib") || !strcmp(path, "/usr/lib/libpmsample.dylib") || !strcmp(path, "/usr/lib/libstdc++.6.0.9.dylib") || !strcmp(path, "/usr/lib/libSystem.B_asan.dylib") || !strncmp(path, "/System", 7)) {
        return old_hasCodeSignature(a, b, c);
    }
    else return 0;
}

uint64_t (*old_hasCdHash)(uint64_t a, uint64_t b);
uint64_t fake_hasCdHash(uint64_t a, uint64_t b) {
    const char *path = ImagePath();
    if (!strcmp(path, "/usr/lib/libobjc-trampolines.dylib") || !strcmp(path, "/usr/lib/libpmsample.dylib") || !strcmp(path, "/usr/lib/libstdc++.6.0.9.dylib") || !strcmp(path, "/usr/lib/libSystem.B_asan.dylib") || !strncmp(path, "/System", 7)) {
        return old_hasCdHash(a, b);
    }
    else return 0;
}

mach_port_t jbd_port;
kern_return_t bootstrap_look_up(mach_port_t  bootstrap_port, char *service_name, mach_port_t *service_port);

// something is LIKELY wrong but idc that much
int (*old_pspawn)(pid_t *restrict, const char *restrict, const posix_spawn_file_actions_t *, const posix_spawnattr_t *restrict, char *const *restrict __argv, char *const *restrict __envp);
int fake_pspawn(pid_t *restrict pid , const char *restrict path, const posix_spawn_file_actions_t *actions, const posix_spawnattr_t *restrict attr, char *const *restrict argv, char *const *restrict envp) {
    
    if (!jbd_port && bootstrap_look_up(bootstrap_port, "org.coolstar.jailbreakd", (mach_port_t *)&jbd_port)) {
        return old_pspawn(pid, path, actions, attr, argv, envp);
    }
    
    size_t len, size, sz;
    char **arr;
    signed int i;
    int slen;
    unsigned int num1, num2;
    int num3;
    
    char *stg2 = strdup("/usr/lib/pspawn_payload-stg2.dylib");
    struct stat st;
    if (!stg2 || stat(stg2, (struct stat *)&st)) {
        return old_pspawn(pid, path, actions, attr, argv, envp);
    }
    
    char **envp2, **envp3;
    char *env, *envar;
    if (envp && (env = *envp) != 0) {
        
        num1 = 0;
        num3 = 0;
        envp2 = (char **)envp;
        
        do {
            if (strstr(env, "DYLD_INSERT_LIBRARIES=")) {
                free(stg2);
                
                char *str = strdup(*envp + 22);
                char ch = *str;
                
                num2 = num1;
                envp3 = envp2;
                
                if (ch) {
                    size_t l = strlen(str);
                    if (l <= 1) len = 1;
                    else len = l;
                    size = (8 * len + 8) & 0x7fffffff8;
                }
                else {
                    size = 8;
                }
                
                arr = (char **)malloc(size);
                bzero(arr, size);
                
                char *tok = strtok(str, ":");
                if (tok) {
                    i = 0;
                    slen = 0;
                    
                    do {
                        if (strcmp(tok, "/usr/lib/pspawn_payload-stg2.dylib")) {
                            arr[i] = strdup(tok);
                            slen += strlen(tok);
                            i++;
                        }
                        tok = strtok(NULL, ":");
                    }
                    while (tok);
                }
                else {
                    slen = 0;
                    i = 0;
                }
                free(str);
                
                sz = slen + i + 34 + 1;
                stg2 = (char *)malloc(sz);
                bzero(stg2, sz);
                strncpy(stg2, "/usr/lib/pspawn_payload-stg2.dylib", 34);
                
                if (i >= 1) {
                    int i2 = i;
                    char **arr2 = arr;
                    size_t pos = 34;
                    
                    do {
                        strncpy(&stg2[pos], ":", 1);
                        
                        char *s = &stg2[pos + 1];
                        char *d = *arr2;
                        size_t l = strlen(d);
                        strncpy(s, d, l);
                        d = *arr2;
                        arr2++;
                        pos = strlen(d) + pos + 1;
                        free(d);
                        i2--;
                    } while (i2);
                }
                free(arr);
                num1 = num2;
                envp2 = envp3;
            }
            else num3++;
            num1++;
            envar = envp2[1];
            envp2++;
            env = envar;
        }
        while (envar);
    }
    else {
        num1 = 0;
        num3 = 0;
    }
    
    char **buf = (char **)malloc((signed long long)((uint64_t)(unsigned int)(num3 + 2) << 32) >> 29);
    int idx = 0;
    size_t num;
    
    if (num1) {
        num = num1;
        do {
            char *en = *envp;
            if (!strstr(*envp, "DYLD_INSERT_LIBRARIES")) buf[idx++] = en;
            envp++;
            num--;
        }
        while (num);
    }
    
    size_t l = strlen(stg2);
    char *new = (char *)malloc(l + 23);
    *new = 0;
    strcat(new, "DYLD_INSERT_LIBRARIES=");
    strcat(new, stg2);
    free(stg2);
    
    char **arr_ = &buf[idx];
    *arr_ = new;
    arr_[1] = NULL;
    
    short flags;
    
    posix_spawnattr_t newattr;
    if (attr) {
        posix_spawnattr_getflags((posix_spawnattr_t *)attr, &flags);
        flags |= POSIX_SPAWN_START_SUSPENDED;
        posix_spawnattr_setflags((posix_spawnattr_t *)attr, flags);
        flags = 0;
        posix_spawnattr_getflags((posix_spawnattr_t *)attr, &flags);
    }
    else {
        posix_spawnattr_init(&newattr);
        posix_spawnattr_setflags(&newattr, POSIX_SPAWN_START_SUSPENDED);
        flags = 0;
    }
    
    char real[MAXPATHLEN];
    int ret;
    
    if (stat(path, (struct stat *)&st) != -1) {
        bzero(real, MAXPATHLEN);
        realpath(path, real);
        
        ret = jbd_file_op(jbd_port, 1, st.st_ino, real, (unsigned int)strlen(real));
        if ((unsigned int)(ret - 0x10000003) > 1) {
            if (!ret) {
            loop:;
                while (1) {
                    mach_port_t jbd = *((mach_port_t *)&NDR_record + 202);
                    ret = jbd_file_op(jbd, 2, st.st_ino, real, (unsigned int)strlen(real));
                    if (!ret) {
                        break;
                    }
                    usleep(0x64);
                }
                goto label;
            }
            // assume this is os_log: NSLog(@"%d Unknown return value for preflight: 0x%x", smth, smth);
        }
        else {
            jbd_port = 0;
            bootstrap_look_up(bootstrap_port, "org.coolstar.jailbreakd", (mach_port_t *)&jbd_port);
            ret = jbd_file_op(jbd_port, 1, st.st_ino, real, (unsigned int)strlen(real));
        }
        if (ret) {
            goto label;
        }
        goto loop;
    }
label:;
    if (flags & POSIX_SPAWN_SETEXEC) {
        if ((unsigned int)jbd_call(jbd_port, 3, getpid()) - 0x10000003 <= 1) {
            jbd_port = 0;
            bootstrap_look_up(bootstrap_port, "org.coolstar.jailbreakd", (mach_port_t *)&jbd_port);
            jbd_call(jbd_port, 3, getpid());
        }
        ret = old_pspawn(pid, path, actions, newattr, argv, buf);
        free(new);
        free(buf);
    }
    else {
        int p;
        ret = old_pspawn(&p, path, actions, newattr, argv, buf);
        free(new);
        free(buf);
        
        if (pid) {
            *pid = p;
        }
        
        if ((unsigned int)jbd_call(jbd_port, 2, p) - 268435459 <= 1) {
            jbd_port = 0;
            bootstrap_look_up(bootstrap_port, "org.coolstar.jailbreakd", (mach_port_t *)&jbd_port);
            jbd_call(jbd_port, 3, p);
        }
    }
    return ret;
}

int (*old_execve)(const char *__file, char *const *__argv, char *const *__envp);
int fake_execve(const char *__file, char *const *__argv, char *const *__envp) {
    if (!jbd_port) {
        bootstrap_look_up(bootstrap_port, "org.coolstar.jailbreakd", &jbd_port);
    }
    
    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETEXEC);
    int ret = posix_spawn(NULL, __file, NULL, &attr, __argv, __envp);
    if (ret) {
        errno = ret;
    }
    
    return -1;
};

void init() {
    task_dyld_info_data_t output;
    size_t cnt = 5;
    
    task_info(mach_task_self(), TASK_DYLD_INFO, (void *)&output, (mach_msg_type_number_t *)&cnt);
    struct dyld_all_image_infos *all_image_info = (struct dyld_all_image_infos *)output.all_image_info_addr;
    const struct mach_header *dyld_load_addr = all_image_info->dyldImageLoadAddress;
    
    struct substitute_image image;
    image.slide = -1;
    image.dlhandle = 0;
    image.image_header = dyld_load_addr;
    
    const char *symbol = "_fcntl";
    void *sym_addr = NULL;
    substitute_find_private_syms(&image, &symbol, &sym_addr, 1);
    
    uint32_t flags;
    csops(1, CS_OPS_STATUS, &flags, 0);
    
    int error = errno;
    if (sandbox_check(getpid(), "process-fork", SANDBOX_CHECK_NO_REPORT)) {
        if (error == EPERM) {
            struct substitute_function_hook hook[0];
            
            hook[0].function = &sym_addr;
            hook[0].replacement = fake_fcntl;
            hook[0].old_ptr = &old_fcntl;
            hook[0].options = 0;
            
            substitute_hook_functions(hook, 1, NULL, SUBSTITUTE_NO_THREAD_SAFETY);
        }
        else {
            struct substitute_function_hook hook[3];
            
            hook[0].function = &csops;
            hook[0].replacement = fake_csops;
            hook[0].old_ptr = &old_csops;
            hook[0].options = 0;
            
            hook[1].function = &csops_audittoken;
            hook[1].replacement = fake_csops_audittoken;
            hook[1].old_ptr = &old_csops_audittoken;
            hook[1].options = 0;
            
            hook[2].function = &sym_addr;
            hook[2].replacement = fake_fcntl;
            hook[2].old_ptr = &old_fcntl;
            hook[2].options = 0;
            
            substitute_hook_functions(hook, 3, NULL, SUBSTITUTE_NO_THREAD_SAFETY);
        }
    }
    else {
        struct substitute_function_hook hook[6];
        
        hook[0].function = &csops;
        hook[0].replacement = fake_csops;
        hook[0].old_ptr = &old_csops;
        hook[0].options = 0;
        
        hook[1].function = &csops_audittoken;
        hook[1].replacement = fake_csops_audittoken;
        hook[1].old_ptr = &old_csops_audittoken;
        hook[1].options = 0;
        
        hook[2].function = &sym_addr;
        hook[2].replacement = fake_fcntl;
        hook[2].old_ptr = &old_fcntl;
        hook[2].options = 0;
        
        hook[3].function = &posix_spawn;
        hook[3].replacement = fake_pspawn;
        hook[3].old_ptr = &old_pspawn;
        hook[3].options = 0;
        
        hook[4].function = &execve;
        hook[4].replacement = fake_execve;
        hook[4].old_ptr = &old_execve;
        hook[4].options = 0;
        
        hook[5].function = &vfork;
        hook[5].replacement = &fork;
        hook[5].old_ptr = NULL;
        hook[5].options = 0;
        
        substitute_hook_functions(hook, 6, NULL, SUBSTITUTE_NO_THREAD_SAFETY);
    }
    
    struct substitute_image *dyld = substitute_open_image("/usr/lib/system/libdyld.dylib");
    if (dyld) {
        const char *syms[] = { "_gUseDyld3", "__ZNK5dyld37closure5Image16hasCodeSignatureERjS2_", "__ZNK5dyld37closure5Image9hasCdHashEPh", "__ZNK5dyld37closure5Image4pathEv" };
        void *sym_addrs[4];
        substitute_find_private_syms(dyld, syms, sym_addrs, 4);
        
        if (sym_addrs[0]) {
            ImagePath = sym_addrs[3];
            
            struct substitute_function_hook hook[3];
            
            hook[0].function = &fcntl;
            hook[0].replacement = fake_fcntl2;
            hook[0].old_ptr = &old_fcntl2;
            hook[0].options = 0;
            
            hook[1].function = sym_addrs[1];
            hook[1].replacement = fake_hasCodeSignature;
            hook[1].old_ptr = &old_hasCodeSignature;
            hook[1].options = 0;
            
            hook[2].function = sym_addrs[2];
            hook[2].replacement = fake_hasCdHash;
            hook[2].old_ptr = &old_hasCdHash;
            hook[2].options = 0;
            
            substitute_hook_functions(hook, 3, NULL, SUBSTITUTE_NO_THREAD_SAFETY);
        }
    }
}

