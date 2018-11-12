// DISCLAIMER: might have inaccurancies/typos/etc. Code was not decompiled with the intention of being reused

int remountRootFS() {
    status("Attempting to remount rootFS...\n");
    
    uint64_t rootvnode = getRootVnodeAddr();
    printf("Actual vnode address is 0x%llx\n", rootvnode);
    
    struct vnode *vp;
    readKernelMemory(rootvnode, sizeof(struct vnode), &vp);
    
    debug("here...\n");
    debug("THE ROOT VNODE IS 0%llx\n", rootvnode);
    hexDump(vp, sizeof(struct vnode), rootvnode);
    
    struct mount *mp;
    readKernelMemory(vp->v_mount, sizeof(struct mount), &mp);
    
    debug("OFFSET OF v_mount: 0x%x - Data follows: \n", offsetof(struct vnode, v_mount));
    hexDump(mp, sizeof(struct mount), vp->v_mount);
    debug("Mount flags (0x%llx + 0x70) : %x\n", vp->v_mount, mp->mnt_flag);
    fprintf(stderr, "MY UID: %d\n", getuid());
    
    struct statfs fs;
    memset(&fs, 0, sizeof(struct statfs));
    if (statfs("/", &fs) < 0) perror("statfs");
    printf("Present mount opts/flags: 0x%x\n", fs->f_flags);
    
    uint64_t *mnt_data_addr;
    readKernelMemory(vp->v_mount + offsetof(struct mount, mnt_data), 8,  &mnt_data_addr);
    
    void *mnt_data;
    readKernelMemory(*mnt_data_addr, 0x2000, &mnt_data);
    
    printf("ORIGINAL MNT DATA (from %llx): \n", *mnt_data_addr);
    hexDump(mnt_data, 0x2000, *mnt_data_addr);
    
    struct hfs_mount_args mntargs;
    memset(&mntargs, 0, sizeof(struct hfs_mount_args));
    mntargs.fspec = "/dev/disk0s1s1";
    mntargs.hfs_mask = 1;
    gettimeofday(NULL, &mntargs.hfs_timezone);
    
    struct vnode *devvp;
    readKernelMemory(mp->mnt_devvp, sizeof(struct vnode), &devvp);
    debug("THE dev VNODE IS 0x%llx\n", mnt->mnt_devvp);
    uint64_t devvnode = getVnodeByPathName("/dev/disk0s1s1");
    debug("THE dev VNODE IS now 0x%llx\n", devvnode);
    hexDump(devvp, sizeof(struct vnode), mnt->devvp);
    
    struct specinfo *si;
    readKernelMemory(devvp->v_un.vu_specinfo, 80, &si);
    
    printf("SPECINFO:\n");
    hexDump(si, 80, devvp->v_un.vu_specinfo);
    
    long flags = 0;
    writeKernelMemory(devvp->v_un.vu_specinfo + offsetof(struct specinfo, si_flags), 8, &flags);
    
    printf("SPECINFO NOW:\n");
    hexDump(si, 80, devvp->v_un.vu_specinfo);
    
    char *path = strdup("/private/var/mobile/tmp");
    mkdir(path, 777);
    if (access(path, 0)) printf("mount point does not exist\n");
    else printf("mount point EXISTS\n");
    
    debug("Try secondary mount\n");
    int rv = mount("apfs", path, 0, &mntargs);
    
    while (rv < 0) {
        perror("mount....");
        sync();
        rv = mount("apfs", path, 32, &mntargs);
        sleep(1);
    }
    
    debug("Secondary mount worked!\n");
    
    uint64_t mntvnode = getVnodeByPathName(path);
    struct vnode *mntvp;
    readKernelMemory(mntvnode, sizeof(struct vnode), &mntvp);
    printf("NEW MP MOUNT IS AT 0x%llx\n", mntvp->v_mount);
    
    struct mount *mntmp;
    readKernelMemory(mntvp->v_mount, sizeof(struct mount), &mntmp);
    
    printf("NEW MOUNT DATA IS:\n");
    hexDump(mntmp, sizeof(struct mount), mntvp->v_mount);
    printf("NEW MNT DATA is at 0x%llx\n", mntmp->mnt_data);
    
    void *new_mnt_data;
    readKernelMemory(mntmp->mnt_data, 0x2000, &new_mnt_data);
    hexDump(new_mnt_data, 0x2000, mntmp->mnt_data);
    
    printf("---------------------\n");
    uint32_t new_mnt_flag = mp->mnt_flag & 0xFFFFBFFE;
    uint32_t mnt_flag_addr = vp->v_mount + offsetof(struct mount, mnt_flag);
    writeKernelMemory(mnt_flag_addr, 4, &new_mnt_flag);
    
    char *dev = strdup("/dev/disk0s1s1");
    rv = mount("apfs", "/", 0x40010000, &dev);
    if (rv) {
        printf("Mount RC: %d (flags 0x%x) %s \n", rv, new_mnt_flag, strerror(errno));
    }
    
    new_mnt_flag |= 0x4000;
    writeKernelMemory(mnt_flag_addr, 4, &new_mnt_flag);
    writeKernelMemory(vp->v_mount + offsetof(struct mount, mnt_data), 8, &new_mnt_data);
    
    fprintf(stderr, "reread\n");
    readKernelMemory(rootvnode, sizeof(struct vnode), &vp);
    debug("reread dat folows Data follows from %llx: \n", rootvnode);
    hexDump(mp, sizeof(struct mount), vp->v_mount);
    
    fprintf(stderr, "Overwriting new mp mount data at 0x%llx to 0x%llx\n", mntmp->mnt_data + 0x1a0, vp->v_mount);
    writeKernelMemory(mntmp->mnt_data + 0x1a0, vp->v_mount);
    
    int fd = open("/test.txt", 1536);
    if (fd < 0) {
        printf("Root remount seems to have failed.. %s\n", strerror(errno));
        return 1;
    }
    else {
        unlink("/test.txt");
        status("Mounted / as read write :-)\n");
        debug("remounted ok!");
        return 0;
    }
}
