## This script has access to 'ev' the debug event
## The get_dll_name is a method ragweed exposes
## These scripts run in the context of the ragweed
## object so you can use self.{ragweed_methods} here
puts "Loaded DLL: #{self.get_dll_name(ev)} @ #{ev.base_of_dll.to_s(16)}"
