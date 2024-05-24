{ ... }:
{
  name = "test-lxc";
  uuid = "b208ceff-2501-4903-98eb-7421a4e1a895";
  os = {
    type = "exe";
    arch = "x86_64";
    init = /bin/systemd;
    initarg = "--unit emergency.service";
  };
  features = {
    privnet = {};
    capabilities = {
      policy = "default";
      audit_control.state = false;
      audit_read.state = true;
      audit_write.state = false;
      block_suspend.state = false;
      bpf.state = false;
      checkpoint_restore.state = false;
      dac_override.state = false;
      dac_read_search.state = false;
      fowner.state = false;
      fsetid.state = false;
      ipc_lock.state = false;
      ipc_owner.state = false;
      kill.state = true;
      lease.state = false;
      linux_immutable.state = false;
      mac_admin.state = false;
      mac_override.state = false;
      mknod.state = false;
      net_admin.state = false;
      net_bind_service.state = false;
      net_broadcast.state = true;
      net_raw.state = false;
      perfmon.state = false;
      setfcap.state = false;
      setgid.state = false;
      setpcap.state = false;
      setuid.state = true;
      syslog.state = true;
      sys_admin.state = true;
      sys_boot.state = false;
      sys_chroot.state = false;
      sys_module.state = false;
      sys_nice.state = true;
      sys_pacct.state = false;
      sys_ptrace.state = false;
      sys_rawio.state = false;
      sys_resource.state = false;
      sys_time.state = true;
      sys_tty_config.state = false;
      wake_alarm.state = false;
    };
  };
}
