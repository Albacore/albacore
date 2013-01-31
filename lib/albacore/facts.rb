# -*- encoding: utf-8 -*-

module Albacore
  module Facts
    
    def self.processor_count
      case RbConfig::CONFIG['host_os']
      when /darwin9/
        `hwprefs cpu_count`.to_i
      when /darwin/
        ((`which hwprefs` != '') ? `hwprefs thread_count` : `sysctl -n hw.ncpu`).to_i
      when /linux/
        `cat /proc/cpuinfo | grep processor | wc -l`.to_i
      when /freebsd/
        `sysctl -n hw.ncpu`.to_i
      when /mswin|mingw/
        require 'win32ole'
        # http://msdn.microsoft.com/en-us/library/windows/desktop/aa394373%28v=vs.85%29.aspx
        wmi = WIN32OLE.connect("winmgmts://")
        cpu = wmi.ExecQuery("select NumberOfLogicalProcessors from Win32_Processor")
        cpu.to_enum.first.NumberOfLogicalProcessors
      end
    end
  end
end