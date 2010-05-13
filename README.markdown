# Nerve is a cross platform (Win32, Linux, OSX) dynamic tracing tool

## What is it?

    Nerve is based on, and requires, Ragweed http://github.com/tduehr/ragweed

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

