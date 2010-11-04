## This script keeps a log of DLLs that were loaded by a
## process at runtime. Over several executions of a target
## it will show you which DLL's are ASLR'd and which are not

dlls = Hash.new { |k,v| k[v] = [] }

## Get the DLL name and its base address
dll_name = self.get_dll_name(ev)
dll_base = ev.dll_base.to_s(16)

## Save the DLLs hash to yaml
dlls[dll_name] << dll_base
File.open('aslr_hash.yaml', 'a').write(dlls.to_yaml)

## Save a log file
File.open('aslr_log.txt', 'a').write("#{dll_name} @ #{dll_base}")
