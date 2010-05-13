# Nerve is a cross platform (Win32, Linux, OSX) dynamic tracing tool

## What is it?

    Nerve is based on, and requires, Ragweed http://github.com/tduehr/ragweed

    To learn more about Ragweed, read this:
    http://chargen.matasano.com/chargen/2009/8/27/ruby-for-pentesters-the-dark-side-i-ragweed.html

    Nerve is a dynamic tracing tool for native x86 code. I wrote it specifically to get
    an idea of how much code coverage my fuzzers were getting. It has other uses as a basic
    dynamic hit tracer as well.

    Nerve showcases the best part about Ragweed: cross platform debugging

    With Nerve you can do hit tracing on Win32, OSX and Linux all from the same tool.

## Features

    - Cross platform. It works on Win32 (XP SP2/SP3, Win7), Linux (Ubuntu) and OSX
    - Easy breakpoint configuration via simple csv text files

## Requirements

    Like all complex software, Nerve has a few dependencies. But don't worry, theres no need
    to install an SQL server or compile any code! All dependencies can be installed via Ruby gems
    on any platform.

    Dependencies:

    - ragweed (a cross platform debugger library)
    - http://github.com/tduehr/ragweed
    - gem install -r ragweed

    YES thats it!

## Usage

    Ragweed Nerve 1.0

    -p The pid OR name of the process you want to trace
    -b The breakpoint file
    -o Optional output file for raw tracing data


    Yes, it 'Just Works'! If you want to write more complex tools then I encourage you to look
    at the ragweed library, or extend Nerve's signal handlers with your own methods.

## Breakpoint File Example

    Nerve breakpoint files are a simple CSV format. Here are some examples:

    Win32:
    0x12345678, SomeLabel
    kernel32!CreateFileW, Label

    Linux
    0x12345678, function_name, ncurses.so.5.1

    OS X
    0x12345678, function_name

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
