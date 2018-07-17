
uint64_t offset_vfs_context_current, offset_vnode_lookup, offset_vnode_put;

int getOffsets(uint64_t kaslr) {
    char v3; //??
    printf("Initializing offsetfinder...\n");
    tihmstar::offsetfinder64::offsetfinder64(
                                             (tihmstar::offsetfinder64 *)&v3,
                                             "/System/Library/Caches/com.apple.kernelcaches/kernelcache"
                                             );
    printf("Initialized offsetfinder\n");
    
    offset_vfs_context_current = tihmstar::offsetfinder64::find_sym(
                                                                    (tihmstar::offsetfinder64 *)&v3,
                                                                    "_vfs_context_current"
                                                                    );
    offset_vnode_lookup = tihmstar::offsetfinder64::find_sym(
                                                             (tihmstar::offsetfinder64 *)&v3,
                                                             "_vnode_lookup"
                                                             );
    offset_vnode_put = tihmstar::offsetfinder64::find_sym(
                                                          (tihmstar::offsetfinder64 *)&v3,
                                                          "_vnode_put");
    
    printf("vfs_context_current: %p\n", offset_vfs_context_current);
    printf("vnode_lookup: %p\n", offset_vnode_lookup);
    printf("vnode_put: %p\n", offset_vnode_put);
    offset_vfs_context_current += kaslr;
    offset_vnode_lookup += kaslr;
    offset_vnode_lookup += kaslr;
    
    tihmstar::offsetfinder64::~offsetfinder64((tihmstar::offsetfinder64 *)&v3);
    
    return 1; //always 1??
}

int list_snapshots(const char *vol)
{
    int dirfd = open(vol, O_RDONLY, 0);
    if (dirfd < 0) {
        perror("get_dirfd");
        return -1;
    }
    
    struct attrlist alist = { 0 };
    char abuf[2048];
    
    alist.commonattr = ATTR_BULK_REQUIRED;
    
    int count = fs_snapshot_list(dirfd, &alist, &abuf[0], sizeof (abuf), 0);
    if (count < 0) {
        perror("fs_snapshot_list");
        return -1;
    }
    
    char *p = &abuf[0];
    for (int i = 0; i < count; i++) {
        char *field = p;
        uint32_t len = *(uint32_t *)field;
        field += sizeof (uint32_t);
        attribute_set_t attrs = *(attribute_set_t *)field;
        field += sizeof (attribute_set_t);
        
        if (attrs.commonattr & ATTR_CMN_NAME) {
            attrreference_t ar = *(attrreference_t *)field;
            char *name = field + ar.attr_dataoffset;
            field += sizeof (attrreference_t);
            (void) printf("%s\n", name);
        }
        
        p += len;
    }
    
    return (0);
}

char *copyBootHash() {
    io_registry_entry_t chosen = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/chosen");
    
    unsigned char buf[1024];
    uint32_t size = 1024;
    char *hash;
    
    if (chosen && chosen != -1) {
        kern_return_t ret = IORegistryEntryGetProperty(chosen, "boot-manifest-hash", (char*)buf, &size);
        IOObjectRelease(chosen);
        
        if (ret) {
            printf("Unable to read boot-manifest-hash\n");
            hash = NULL;
        }
        else {
            char *result = (char*)malloc((2 * size) | 1); // even number | 1 = that number + 1, just because why not
            memset(result, 0, (2 * size) | 1);
            
            int i = 0;
            while (i < size) {
                unsigned char ch = buf[i];
                sprintf(result + 2 * i++, "%02X", ch);
            }
            printf("Hash: %s\n", result);
            hash = strdup(result);
        }
    }
    else {
        printf("Unable to get IODeviceTree:/chosen port\n");
        hash = NULL;
    }
    return hash;
}


int vnode_lookup(const char *path, int flags, uint64_t *vnode, uint64_t vfs_context) {
    
    size_t len = strlen(path) + 1;
    uint64_t ptr = kalloc(8);
    uint64_t ptr2 = kalloc(len);
    kwrite(ptr2, path, len);
    
    if (kexecute(offset_vnode_lookup, ptr2, flags, ptr, vfs_context, 0, 0, 0)) {
        return -1;
    }
    *vnode = rk64(ptr);
    kfree(ptr2, len);
    kfree(ptr, 8);
    return 0;
}

uint64_t get_vfs_context() {
    return zm_fix_addr(kexecute(offset_vfs_context_current, 1, 0, 0, 0, 0, 0));
}

int vnode_put(uint64_t vnode) {
    return kexecute(offset_vnode_put, vnode, 0, 0, 0, 0, 0, 0);
}

uint64_t getVnodeAtPath(uint64_t vfs_context, const char *path) {
    uint64_t *vnode_ptr = (uint64_t *)malloc(8);
    if (vnode_lookup(path, 0, vnode_ptr, vfs_context)) {
        printf("unable to get vnode from path for %s\n", path);
        return -1;
    }
    else {
        uint64_t vnode = *vnode_ptr;
        free(vnode_ptr);
        return vnode;
    }
}

char *find_system_snapshot() {
    const char *hash = copyBootHash();
    size_t len = strlen(hash);
    char *str = (char*)malloc(len + 29);
    memset(str, 0, len + 29); //fill it up with zeros?
    if (!hash) return 0;
    sprintf(str, "com.apple.os.update-%s", hash);
    printf("System snapshot: %s\n", str);
    return str;
}

int remountRootAsRW(uint64_t kaslr, uint64_t kernproc, uint64_t ourproc, int snapshots) {
    if (kCFCoreFoundationVersionNumber > 1451.51 && snapshots) { //the second check makes it only run once; on iOS 11.3+ Electra creates no other snapshots;
        if (getOffsets(kaslr)) {
            uint64_t kern_ucred = rk64(kernproc + offsetof_p_ucred);
            uint64_t our_ucred = rk64(ourproc + offsetof_p_ucred);
            
            uint64_t context = get_vfs_context();
            uint64_t devVnode = getVnodeAtPath(path, "/dev/disk0s1s1");
            uint64_t specinfo = rk64(devVnode + offsetof_v_specinfo);
            
            wk32(specinfo + offsetof_si_flags, 0); //if you're coming from my code, that's offsetof_specflags, = to 0x10
            
            if (file_exists("/var/rootfsmnt"))
                rmdir("/var/rootfsmnt");
            
            mkdir("/var/rootfsmnt", 0777);
            chown("/var/rootfsmnt", 0);
            
            printf("Temporarily setting kern ucred\n");
            wk64(ourproc + offsetof_p_ucred, kern_ucred);
            
            int rv = -1, ret;
            
            if (mountDevAsRWAtPath("/dev/disk0s1s", "/var/rootfsmnt")) {
                printf("Error mounting root at %s\n", "/var/rootfsmnt");
            }
            else {
                printf("Disabling the APFS snapshot mitigations\n");
                char *snap = find_system_snapshot("/var/rootfsmnt");
                if (snap && !do_rename("/var/rootfsmnt", snap, "orig-fs")) {
                    rv = 0;
                    unmount("/var/rootfsmnt", 0);
                    rmdir("/var/rootfsmnt");
                }
            }
            printf("Restoring our ucred\n");
            wk64(ourproc + offsetof_p_ucred, our_ucred);
            vnode_put(devVnode);
            
            if (rv) {
                printf("Failed to disable the APFS snapshot mitigations\n");
            }
            else {
                printf("Disabled the APFS snapshot mitigations\n");
                printf("Restarting\n");
                restarting();
                sleep(2);
                do_restart();
            }
            ret = -1;
        }
        else ret = -1;
    }
    else ret = remountRootAsRW_old(kaslr, kernproc, selfproc); //args get used nowhere, \shrug
    
    return ret;
}

int start_electra() {
    ...
    locknvram();
    printf("APFS Snapshots: \n");
    printf("=========\n");
    int snapshots = list_snapshots("/");
    printf("=========\n");
    int rv = remountRootAsRW(kaslr, kernproc, selfproc, snapshots);
    ...
}
