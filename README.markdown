# Nerve is a simple cross platform (Win32, Linux, OSX) x86 hit tracer

## What is it?

    Nerve is based on, and requires, Ragweed http://github.com/tduehr/ragweed

    To learn more about Ragweed, read this:
    http://chargen.matasano.com/chargen/2009/8/27/ruby-for-pentesters-the-dark-side-i-ragweed.html

    Nerve is a dynamic tracing tool for native x86 code.

    Nerve showcases the best part about Ragweed: cross platform debugging. I originally
    wrote Nerve as a small Ragweed script that kept stats on the functions my fuzzers
    were triggering in my target process. This let me know what code paths my fuzzer was
    reaching and which ones it wasn't. It only took a few hours to make it work on all Ragweed
    supported platforms, and since then it has grown into a better tool. It now supports
    breakpoint configuration files, ruby scripts per breakpoint and more.

## Supported Platforms

    Nerve is supported and has been tested on the following platforms:

    Windows 7
    Windows XP
    Linux Ubuntu 10.4
    Linux Ubuntu 9.10
    Mac OS X 10.6
    Mac OS X 10.5

    At this time only Ruby 1.8.x has been tested. We are actively investigating both 64 bit
    support for each platform and support for Ruby 1.9.x. Unfortunately both of these things
    require changes to Ragweed.

## Features

    - Cross platform (see above)
    - Easy breakpoint configuration files you can write by hand or generate using our tools
    - Run Ruby scripts with full access to the debugger when breakpoints are hit
    - Extend Nerve with your own event handling methods in handlers.rb
    - Extend Nerves output with your own methods in common/output.rb

## Todo

	Nerve is a simple tool, but we plan to grow it with optional add ons:

    - Helper methods and better named instance variables for making breakpoint scripts easier to write
    - Better output such as graphviz, statistics, function arguments etc...
    - An HTML5 canvas output mode
	- A basic RubyWX GUI
	- Redis database support
    - Nerve is helping us find the areas of Ragweed that need the most improvement
  
## Requirements

    Nerve has one small dependency. But don't worry, theres no need to install an SQL server
    or compile any code! The dependency, Ragweed, can be installed via Ruby gems on any platform.

    - Ragweed (a cross platform debugger library)
    - http://github.com/tduehr/ragweed
    - gem install -r ragweed

    YES thats it!

    If you want to run the bleeding edge stuff we commit to github everyday then I suggest
    checking out the github repositories of both Nerve and Ragweed and executing a 'git pull'
    before using the tool.

## Usage

    $ ruby nerve.rb -h

    Ragweed Nerve 1.2 (Use -h for help)

    -p, --pid PID/Name               Attach to this pid OR process name (ex: -p 12345 | -p gcalctool)
    -b, --breakpoint_file FILE       Read all breakpoints from this file
    -o, --output FILE                Dump all output to a file
    -f                               Optional flag indicates whether or not to trace forked child processes (Linux only)

    Yes, it 'Just Works'! If you want to write more complex tools then I encourage you to look
    at the ragweed library, or extend Nerve's signal handlers with your own methods.

## Breakpoint File Example

    Keywords in breakpoint files:
    (order does not matter)

    bp - An address (or a symbolic name for Win32) where the debugger should set a breakpoint
    name - A name describing the breakpoint, typically a symbol or function name
    lib - An optional library name indicating where the symbol can be found, only useful with Linux/OSX
    bpc - Number of times to let this breakpoint hit before uninstalling it
    code - Location of a script that holds ruby code to be executed when this breakpoint hits    

    --

    Win32 Breakpoint Configuration:
    bp=0x12345678, name=SomeFunction, bpc=2, code=scripts/SomeFunctionAnalysis.rb
    bp=kernel32!CreateFileW, name=CreateFileW, code=scripts/CreateFileW_Analysis.rb

    Linux Breakpoint Configuration:
    bp=0x12345678, name=function_name, lib=ncurses.so.5.1, bpc=1, code=scripts/ncurses_trace.rb
    name=malloc, lib=/lib/tls/i686/cmov/libc-2.11.1.so, bpc=10, bp=0x006ff40 code=scripts/malloc_linux.rb

    OS X  Breakpoint Configuration:
    bp=<Address>, name=<Function Name>, bpc=2
    bp=0x12345678, name=function_name, bpc=6

## Breakpoint Scripts

    Nerve supports breakpoint scripts that run when a breakpoint you have specified is executed. These
    can be specified using the 'code=' keyword in your breakpoint configuration file (see above).
    These scripts run within the scope of Nerve and the Ragweed breakpoint. This means your scripts
    have access to all the helper methods and instance variables Ragweed makes available. Documenting
    each of these is going to take a bit of time.

    Helper Methods:

    (please refer to Ragweed sources for now http://github.com/tduehr/ragweed)

    Instance Variables:

    @rw - The Ragweed instance, use this to call all Ragweed methods

    Win32 Specific:
        evt - A debugger event
        ctx - A context structure holding registers
        dir - a string indicating function 'enter' or 'leave'

## Examples

    Heres some example output from Nerve.

    chris@ubuntu:/# ruby nerve.rb -b example_breakpoint_files/generic_ubuntu_910_libc_trace.txt -p test
    Nerve ...
    Setting breakpoint: [0x01ccff0,write@/lib/tls/i686/cmov/libc-2.10.1.so]
    Setting breakpoint: [0x01ccf70,read@/lib/tls/i686/cmov/libc-2.10.1.so]
    Setting breakpoint: [0x017f760,free@/lib/tls/i686/cmov/libc-2.10.1.so]
    Setting breakpoint: [0x018b460,wmemcpy@/lib/tls/i686/cmov/libc-2.10.1.so]
    Setting breakpoint: [0x017f840,malloc@/lib/tls/i686/cmov/libc-2.10.1.so]
    Setting breakpoint: [0x0185010,memcpy@/lib/tls/i686/cmov/libc-2.10.1.so]
    ^CDumping stats
    0x01ccff0 hit 5 times
    0x01ccf70 hit 0 times
    0x017f760 hit 2 times
    0x018b460 hit 0 times
    0x017f840 hit 3 times
    0x0185010 hit 0 times
    ... Done!

    Nerve running on Windows 7 and debugging an example program that calls HeapAlloc. For this test
    program we want to run a simple ruby script each time HeapAlloc is entered and exited.

    Test Program:

    ...
    #include <stdio.h>
    #include <windows.h>

    int main(int argc, char *argv[])
    {
       void *a;
       HANDLE h1 = HeapCreate(0, 1024, 1024);
       int i = atol(argv[1]);

       while(1)
       {
           a = HeapAlloc(h1, HEAP_ZERO_MEMORY, i);
           HeapFree(h1, 0, a);
       }

        return 0;
    }
    ...

    Here is the breakpoint configuration file:

    ...
    bp=ntdll!RtlAllocateHeap, name=RtlAllocateHeap, code=scripts/RtlAllocateHeap.rb
    ...

    And here is the scripts/RtlAllocateHeap.rb referenced in the breakpoint config file:

    ...
    ## This script is for Win32 RtlAllocateHeap

    if dir.to_s =~ /enter/
        puts "Size requested #{@rw.process.read32(ctx.esp+12)}"
        puts "Heap handle is @ #{@rw.process.read32(ctx.esp+4).to_s(16)}"
    else
        puts "Heap chunk returned @ #{ctx.eax.to_s(16)}"
    end
    ...

    Below is the output of hooking the malloc.exe program:

    PS C:\My Dropbox\Nerve> ruby .\nerve.rb -p malloc.exe -b .\example_breakpoint_files\Win32_notepad.txt
    Nerve ...
    Setting breakpoint: [ ntdll!RtlAllocateHeap, RtlAllocateHeap ]
    Size requested 1024
    Heap handle is @ 750000
    Heap chunk returned @ 750590
    Size requested 1024
    Heap handle is @ 750000
    Heap chunk returned @ 750590
    Size requested 1024
    Heap handle is @ 750000
    Heap chunk returned @ 750590                    <- This is where I CTRL+C the test program
    Size requested 24
    Heap handle is @ 470000
    Heap chunk returned @ 47f640
    -----------------------------------------------------------------------
    CONTEXT:
    EIP: 77b564f4

    EAX: 000000c0
    EBX: 7ffd3000
    ECX: 77b6350f
    EDX: 00000000
    EDI: 00000000
    ESI: 002af704
    EBP: 002af728
    ESP: 002af6c0
    EFL: 00000000000000000000001000000010 cvvavrxniiodItszxaxpXc
    Dumping stats
    Pid is 3224
    Tid is 4048
    ntdll!RtlAllocateHeap - RtlAllocateHeap | 4 hit(s)

## Who

Nerve was written by Chris Rohlf, and is also developed by Alex Rad

Ragweed was written by Thomas Ptacek, ported to OSX by Timur Duehr and ported to Linux by Chris Rohlf
