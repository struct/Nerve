## Crash is a partial MSEC (!exploitable) WinDbg extension
## ported to use the ragweed debugging library. It has been
## test with the Nerve debugger,
##
## Usage:
## 
## Catch a bad debug event like segfault or illegal instruction
## then pass your ragweed instance to this class:
##
## Crash.new(@ragweed).exploitable?
## 
## Thats it! The class will use your ragweed instance to
## determine the state of the process. This is done examining
## the last signal or debug event the process received and
## the register states.

## THIS CODE IS EXPERIMENTAL AND UNFINISHED :)

require 'rubygems'
require 'ragweed'

class Crash
    EXPLOITABLE = 1
    POSSIBLY_EXPLOITABLE = 2
    NOT_EXPLOITABLE = 3
    UNKNOWN = 4

    attr_accessor :state, :status, :ragweed

    def initialize(rw)
        @ragweed = rw
        status = UNKNOWN

        case
            when RUBY_PLATFORM =~ WINDOWS_OS
                crash_win32
            when RUBY_PLATFORM =~ LINUX_OS
                crash_linux
            when RUBY_PLATFORM =~ OSX_OS
                crash_osx
        end
    end

    ## Crash.exploitable?
    ## Who needs !exploitable when you've got exploitable?
    def exploitable?
        return true if status == EXPLOITABLE or status == POSSIBLY_EXPLOITABLE
        return false
    end

    def crash_win32
        event = @ragweed.event
        context = @ragweed.context(event)

        ## !! unused !!
        @state = OpenStruct.new
        @state.crash_address
        @state.raw_instruction
        @state.stack_trace

        status = reg_check(context.eip)

        if event.exception_code == Ragweed::Wrap32::ExceptionCodes::ILLEGAL_INSTRUCTION
            puts "Illegal instruction indicates attacker controlled code flow - EXPLOITABLE"
            status = EXPLOITABLE
        end

        if event.exception_code == Ragweed::Wrap32::ExceptionCodes::PRIV_INSTRUCTION
            puts "Privileged instruction indicates attacker controlled code flow - EXPLOITABLE"
            status = EXPLOITABLE
        end

        if event.exception_code == Ragweed::Wrap32::ExceptionCodes::ON_GUARD_PAGE
            puts "Guard page violation - EXPLOITABLE"
            status = EXPLOITABLE
        end

        if event.exception_code == Ragweed::Wrap32::ExceptionCodes::BUFFER_OVERRUN
            puts "/GS stack cookie has been corrupted - EXPLOITABLE"
            status = EXPLOITABLE
        end

        if event.exception_code == Ragweed::Wrap32::ExceptionCodes::HEAP_CORRUPTION
            puts "Heap corruption has been detected - EXPLOITABLE"
            status = EXPLOITABLE
        end

        if event.exception_code == Ragweed::Wrap32::ExceptionCodes::ACCESS_VIOLATION and
            event.exception_information[0] == Ragweed::Wrap32::ExceptionSubTypes::ACCESS_VIOLATION_TYPE_DEP and
            event.exception_address > 0x1000
            puts "DEP Access Violation not near NULL - EXPLOITABLE"
            status = EXPLOITABLE
        end

        if event.exception_code == Ragweed::Wrap32::ExceptionCodes::ACCESS_VIOLATION and
            event.exception_information[0] == Ragweed::Wrap32::ExceptionSubTypes::ACCESS_VIOLATION_TYPE_DEP and
            event.exception_address < 0x1000
            puts "DEP Access Violation near NULL - NOT EXPLOITABLE"
            status = NOT_EXPLOITABLE
        end

        if event.exception_code == Ragweed::Wrap32::ExceptionCodes::ACCESS_VIOLATION and
            event.exception_information[0] == Ragweed::Wrap32::ExceptionSubTypes::ACCESS_VIOLATION_TYPE_WRITE and
            event.exception_address > 0x1000
            puts "Write Access Violation not near NULL - EXPLOITABLE"
            status = EXPLOITABLE
        end

        if event.exception_code == Ragweed::Wrap32::ExceptionCodes::ACCESS_VIOLATION and
            event.exception_information[0] == Ragweed::Wrap32::ExceptionSubTypes::ACCESS_VIOLATION_TYPE_WRITE and
            event.exception_address < 0x1000
            puts "Write Access Violation near NULL - NOT EXPLOITABLE"
            status = NOT_EXPLOITABLE
        end

        if event.exception_code == Ragweed::Wrap32::ExceptionCodes::ACCESS_VIOLATION and
            event.exception_information[0] == Ragweed::Wrap32::ExceptionSubTypes::ACCESS_VIOLATION_TYPE_READ and
            event.exception_address > 0x1000
            puts "Read Access Violation not near NULL - EXPLOITABLE"
            status = EXPLOITABLE
        end

        if event.exception_code == Ragweed::Wrap32::ExceptionCodes::ACCESS_VIOLATION and
            event.exception_information[0] == Ragweed::Wrap32::ExceptionSubTypes::ACCESS_VIOLATION_TYPE_READ and
            event.exception_address < 0x1000
            puts "Read Access Violation near NULL - NOT EXPLOITABLE"
            status = NOT_EXPLOITABLE
        end

        if event.exception_code == Ragweed::Wrap32::ExceptionCodes::DIVIDE_BY_ZERO
            puts "Divide by zero - NOT EXPLOITABLE"
            status = NOT_EXPLOITABLE
        end
    end

    def crash_linux
        r = @ragweed.get_registers
        status = reg_check(r.eip)
        status = reg_check(r.ebp)

        case ragweed.signal
            when Ragweed::Wraptux::Signal::SIGILL
                puts "Illegal instruction indicates attacker controlled code flow - EXPLOITABLE"
                status = EXPLOITABLE
            when Ragweed::Wraptux::Signal::SIGIOT
                puts "IOT Trap may indicate an exploitable crash (stack cookie?) - POSSIBLY EXPLOITABLE"
                status = POSSIBLY_EXPLOITABLE
            when Ragweed::Wraptux::Signal::SIGSEGV
                puts "A segmentation fault may be exploitable, needs further analysis - POSSIBLY EXPLOITABLE"
                status = POSSIBLY_EXPLOITABLE
        end
    end

    def crash_osx
        ## TODO
    end

    def get_stack_trace
        ## Not implemented yet
    end

    ## Really only works in Linux right now
    def reg_check(reg)
        ## TODO: Uhh these are not yet implemented in ragweed
        ## Win32 - TEB Parsing
        stack_range = @ragweed.get_stack_range
        heap_range = @ragweed.get_heap_range

        case reg
            when stack_range.first..stack_range.last
                puts "Executing instructions from the stack - EXPLOITABLE"
                return EXPLOITABLE

            when 0x41414141
                puts "Register is controllable AAAA... - EXPLOITABLE"
                return EXPLOITABLE

            when heap_range.first..heap_range.last
                puts "Executing instructions from the heap - EXPLOITABLE"
                return EXPLOITABLE

            when 0x0..0x1000
                puts "NULL Pointer dereference - NOT EXPLOITABLE (unless you control the offset from NULL)"
                return NOT_EXPLOITABLE
        end
    end
end
