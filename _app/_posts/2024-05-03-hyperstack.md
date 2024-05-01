---
title: The Hyperstack!
date: 2024-05-03 07:00:00 -0600
author: joseph
---

About a year ago I talked about developing my own [personal technology]({% post_url 2023-05-12-technology %}).
I wanted a codebase or foundation on which to build, well, literally anything.
Something I could take with me wherever I went.

In many ways, a year is both a long time, yet also not very much time at all.
There's so much that can be done, so many directions to go.
I feel like I accomplished a great deal, yet only barely scratched the surface.

Here's a very brief overview of how I write programs in C.
Honestly, I could discuss any of these things at length.

## Development Environment

My basic development environment is as follows:

```shell
- hyper
- os-obsd
- test-bench
```

The `hyper` library is my base layer, which houses basic primitives and data structures, including strings, queues, and more.
I'll discuss this more down below.

The `os-obsd` library is basically a wrapper around operating system calls and library functions.
As you can see, it's platform-specific, in my case, I'm developing primarily on OpenBSD, though I can foresee needing new libraries for other targets.

I do most of my experiments in the `test-bench` repository, usually to test out ideas or to figure out how a system call works.

I export the following environment variables:

```shell
export C_INCLUDE_PATH=$HYPERSTACK_HOME/hyper/src
export C_INCLUDE_PATH=$C_INCLUDE_PATH:$HYPERSTACK_HOME/os-obsd/src
export LIBRARY_PATH=$HOME/.local/lib
export LD_LIBRARY_PATH=$HOME/.local/lib
```

This allows me to install the above libraries into those directories and dynamically link them from my projects.
I find this most helpful when writing a quick program that I want to run as a script with `rcc` (see below).

However, despite saying that, I don't do much dynamic linking.
Instead, I include the `*.c` files in their own translation unit, say `hyper/lib.c` or `os/lib.c`, in whatever project I'm working on.
I'm bringing in specific modules I need, rather than linking against the entire library.

I also have a specific naming scheme for other libraries:

```shell
- nio-*
- tio-*
- vio-*
```

Network I/O, or `nio-*`, is used for servers listening on TCP or UNIX sockets.
I use `tio-*` for terminal I/O, and `vio-*` for video or viewport I/O, such as when interfacing with an X11 server.

This can, of course, be extended to other sorts of libraries, though I haven't yet written very many.

## Base Layer

Many people say that the C Standard Library is not very good, which is why most people build their own abstractions.
I suppose I agree with them, because I've written my own as well.

I have types like `i32` defined for signed integers and `u32` for unsigned.
There are other `typedefs` here, but I won't go into all of them.
Mostly I use these as semantic indicators, like when I need to indicate that a variable indicates a pointer offset or a size integer or whatever else.

I also have macros defined for simple queues and lists.
I may need to define some for trees or hash tables, though I haven't found the need for this yet.

To manage memory, I primarily use arena allocators (or linear or bump allocators).
I then build off these arenas and build other types of memory management, like freelists or pool allocators.

The `hyper` library doesn't actually make any function calls to `malloc(3)` or `mmap(2)`.
Instead, it accepts pointers to memory that was reserved and committed in `os-obsd`.

I never reallocate memory or request larger chunks of memory in the middle of a program.
Instead, I reserve a huge chunk of memory, enough for whatever my program needs, *at the beginning of runtime*, and recycle this memory over the lifetime of the program.

So much of low-level programming seems to be about manipulating bytes or strings of bytes.
As such, I have data structures for string views, which allows me to indicate how large a string is along with a character pointer.
I only `nil`-terminate these strings when I need to interface with C library functions.

Instead of `printf(3)`, I use I/O buffers that are appended to.
I have most data types covered, including appending integers, signed or unsigned, strings, or whatever else.
Each buffer has its own size and associated `flush` function, which allows calls to I/O to be chunked or amortized.
This can also be called directly, so I can control when the buffer is flushed.

So instead of:

```c
printf("Hello, %s!\n", value);
```

It looks like this:

```c
io8_append_c8a(buffer, "Hello, ");
io8_append(buffer, value);
io8_append_c8(buffer, '!');
io8_newline(buffer);
io8_flush(buffer);
```

It's a bit more verbose, but I enjoy the control it affords.

I can also use these I/O buffers without a flush function, in order to build strings.
I append to these and then just output a string view, whose memory I can use wherever I want.

I find that this works well.

## Build System

I use a non-traditional build system.
I considered using `make(1)`, but I didn't enjoy maintaining a series of more and more complex Makefiles.

Instead I use `redo`, a hypothetical build system designed by Daniel J. Bernstein, though he never published an implementation.
Instead, several others have taken it upon themselves to write their own implementations, each one somewhat different from each other.

It uses a series of shell scripts to handle recursive builds.
This seems easier, but it can be a bit difficult to reason about the dependencies, at least in my mind.

I'm not really happy with how my build system works right now, so I will probably revisit this in the future.

## Projects

Here are a few projects I've built in the past year or so.
They're mostly simple one-off projects to help me understand different system calls, library functions, and so forth.
However, they've been extremely helpful learning experiences!

#### rcc

I like to call this project the **Run C Compiler** program.
I wanted a way to run scripts without invoking a compiler, i.e. `cc test.c && ./a.out`.
So I wrote a program that would compile a `*.c` file and run the program with whatever arguments I passed in.
Similar to an interpreted language, haha.

I have it installed as `c` under `$HOME/.local/bin`.
I just invoke the following:

```shell
c test.c [optional args]
```

And since my `C_INCLUDE_PATH`, `LD_LIBRARY_PATH`, and `LIBRARY_PATH` environment variables are already exported, I can use my own libraries when running thse "C scripts".

#### xio-wmstatus

A simpler replacement for `slstatus`.
It writes fuzzy time into the X11 root window's `WM_NAME`, which works well with my tiling window manager.
It also reads from `apm(4)`, so I can tell how much battery is left or whether the battery is plugged in when the program is running on my laptops.

Here's what it usually outputs into `WM_NAME`:

```
WM_NAME(STRING) = "Wednesday May 3rd, ten past six"
```

#### xio-plug

I needed a way to detect when a monitor was plugged on or off of my machine.
This program waits for those events from the X11 server and runs a script, passing those displays and whether they're `connected` or `disconnected` as arguments

#### nio-stream

This is my base library for running TCP servers, though it could probably be adapted to listen on UNIX sockets as well.
Instead of `pthreads(3)`, it uses `kqueue(2)` in order to multiplex non-blocking I/O.
I've used this to build HTTP servers as well as simple pastebin upload servers, similar to [termbin.com](https://termbin.com).

#### nio-http

Data structures for parsing HTTP messages from a string of bytes.
Obviously, it's not as feature complete as the actual protocol, but I don't need it to be.
I basically use these servers to pass messages back and forth, while a public endpoint, in some other language like Ruby, serves as a router to these other HTTP servers.
As I'm in control of these servers, and they aren't public-facing, I can basically get away with a less robust implementation.

## Caveats

Obviously, this is how *I* do things.

I'm not really aiming to interface with other people or work with their code.
Nor am I looking to make this code public.

I'm mostly interested in tinkering around on my own, forming a foundation of solid code off which I can build my own applications, whatever those may be.

Even though I'm using C99, I kind of think of this as my own dialect of C.

## TODO

A few things I'd like to do in the future are:

- My own build system!
- Text editor
- Graphics/animation library
- Figure out audio, i.e. `sndio(7)`
- Build a more complex graphical application with `libxcb`
- Work with a different platform, i.e. `os-linux`
- Move away from `libc`
- And one day, build a video game!!
