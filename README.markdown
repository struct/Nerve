# Nerve is a simple cross platform (Win32, Linux, OSX) x86 hit tracer

## What is it?

    Nerve is based on, and requires, Ragweed http://github.com/tduehr/ragweed

    To learn more about Ragweed, read this:
    http://chargen.matasano.com/chargen/2009/8/27/ruby-for-pentesters-the-dark-side-i-ragweed.html

    Nerve is a dynamic tracing tool for native x86 code. I wrote it specifically to get
    an idea of how much code coverage my fuzzers were getting. It has other uses as a basic
    dynamic hit tracer as well.

    Nerve showcases the best part about Ragweed: cross platform debugging. I originally
    wrote Nerve as a small Ragweed script that kept stats on the functions my fuzzers
    were triggering in my target process. This helped me gauge what code paths my fuzzer was
    reaching and which ones it wasn't. It only took a few hours to make it work on all Ragweed
    supported platforms, and since then I have used it more than once. Hopefully the code
    will help other people write better Ragweed tools. I do plan to keep Nerve updated with
    newer features such as better output. I have some utility scripts on the way that help
    generate the breakpoint files required by Nerve, but for now you will have to build them
    by hand.

## Features

    - Cross platform. It works on Win32 (XP SP2/SP3, Win7), Linux (Ubuntu) and OSX
    - Easy breakpoint configuration via simple csv text files

## Todo

	Nerve is a simple tool, but we plan to grow it ...

    - Better output such as graphviz, statistics, function arguments etc...
	- A basic RubyWX GUI (this will be optional)
	- Redis database support (this will be optional)
    - Nerve is helping us find the areas of Ragweed that need the most improvement
  
## Requirements

    Nerve has one small dependency. But don't worry, theres no need to install an SQL server
    or compile any code! The dependency, Ragweed, can be installed via Ruby gems on any platform.

    - Ragweed (a cross platform debugger library)
    - http://github.com/tduehr/ragweed
    - gem install -r ragweed

    YES thats it!

## Usage

    $ ruby nerve.rb -h

    Ragweed Nerve 1.1 (Use -h for help)

    -p, --pid PID/Name               Attach to this pid OR process name (ex: -p 12345 | -p gcalctool)
    -b, --breakpoint_file FILE       Read all breakpoints from this file
    -o, --output FILE                Dump all output to a file
    -f                               Optional flag indicates whether or not to trace forked child processes (Linux only)

    Yes, it 'Just Works'! If you want to write more complex tools then I encourage you to look
    at the ragweed library, or extend Nerve's signal handlers with your own methods.

## Breakpoint File Example

    Win32 Breakpoint Configuration
    break=<Address or Function!Library>, name=<Function Name>, bpc=<Breakpoint Count (Optional)>
    break=0x12345678, name=SomeFunction, bpc=2
    break=kernel32!CreateFileW, name=SomeFunction

    Linux Breakpoint Configuration
    break=<Address>, name=<Function Name>, lib=<LibraryName (optional)>, bpc=<Breakpoint Count (Optional)>
    break=0x12345678, name=function_name, lib=ncurses.so.5.1, bpc=1
    break=0x12345678, name=function_name

    OS X  Breakpoint Configuration: 
    break=<Address>, name=<Function Name>, bpc=<Breakpoint Count (Optional)>
    break=0x12345678, name=function_name, bpc=6

## Examples

    Heres some example output from Nerve. Please keep in mind the tool is merely a shell
    and it will grow as Ragweed matures.

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

    Nerve running on Windows XP and debugging notepad.exe:

    PS Z:\Nerve> ruby nerve.rb -b example_breakpoint_files\Win32_notepad.txt -p notepad.exe
    Nerve ...
    Setting breakpoint: [kernel32!ReadFile,ReadFile]
    Setting breakpoint: [kernel32!WriteFile,WriteFile]
    Setting breakpoint: [kernel32!CreateFileW,CreateFileW]
    Setting breakpoint: [kernel32!DeviceIoControl,DeviceIOControl]
    Pid is 3440
    Tid is 3496
    -----------------------------------------------------------------------
    CONTEXT:
    EIP: 7c90e514

    EAX: 000000c0
    EBX: 00000000
    ECX: 01020228
    EDX: 010201d8
    EDI: 7c97e440
    ESI: 7c97e420
    EBP: 00e8ffb4
    ESP: 00e8ff70
    EFL: 00000000000000000000001010000110 cvvavrxniiodItSzxaxPXc

    Dumping stats
    kernel32!ReadFile - 82 hit(s)
    kernel32!WriteFile - 0 hit(s)
    kernel32!CreateFileW - 122 hit(s)
    kernel32!DeviceIoControl - 90 hit(s)


## Who

Nerve was written by Chris Rohlf, and is also developed by Alex Rad

Ragweed was written by Thomas Ptacek, ported to OSX by Timur Duehr and ported to Linux by Chris Rohlf
