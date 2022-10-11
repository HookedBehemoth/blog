+++
title = "UDON: A post mortem"
date = 2022-10-10
description = "A story about a horrible bytecode interpreter"
+++

Note: 
This is my first blog post, so be forgiving.

## Introduction
VRChat is a social VR platform built on [Unity3D](https://unity.com/).
Its users can upload their 3D assets, such as Avatars and Worlds.
To provide interaction, a scripting language is provided.
It’s called UDON.

When I was introduced to VRChat, I eventually got invited to learn the Japanese tile game [Riichi Mahjong](https://riichi.wiki/Main_Page) in the [Chiitoitsu Parlor](https://vrchat.com/home/world/wrld_553fc2ff-d875-4eb0-98a1-70531b8c7ae2).
The game is best played with three or four players.
The table [Prefab](https://docs.unity3d.com/Manual/Prefabs.html) allows you to stack up players with CPU-controlled bots/NPCs (non-player characters).

Over time I got annoyed by the bad performance I had to endure while playing this game.

## About UDON
Udon is an interpreted bytecode language for client-sided functionality in VRChat environments.
Each script is bound to an object where one player implicitly or explicitly takes ownership.

It consists of a fixed-size heap, a stack and nine variable-length instructions (4 or 8 bytes).
These are as follows:

| Instruction | Description |
|-|-|
| NOP | Nothing |
| PUSH | Pushes a heap index to the stack |
| POP | Removes the last index from the stack |
| JUMP_IF_FALSE | Jumps to a set instruction if the last value on the stack evaluates to true |
| JUMP | Jump to a set instruction |
| EXTERN | Call an exported function outside the VM |
| ANNOTATION | Prints a variable of the heap |
| JUMP_INDIRECT | Loads an index of the heap and jumps to this instruction |
| COPY | Copy one value of the heap to another index |

`NOP`, `POP` and `ANNOTATION` aren’t commonly used, so we are only left with six useful instructions.

The interpreter is implemented as a simple switch in a loop, like such
```rs
loop {
    match code[pc] {
        NOP => { /* ... */ }
        PUSH { idx } => { stack.push(idx) }
        POP => { stack.pop() }
        /* ... */
    }
}
```

Since you wouldn’t want to write assembly directly, you can choose higher-level languages and compilers.

### Node Graphs
{{ image(path="/blog/udon/graph.png") }}

The VRChat team made this one.
Unfortunately, it’s still 1very limited.
Function calls and recursion are very clunky.

This caused the community to develop alternatives.

### UdonPieCompiler
```py
from .UdonPie import *

def _start():
    res = func(3, 23)
    Debug.Log(Object(res))

def func(lhs: Int32, rhs: Int32) -> Int32:
    lhs * rhs
```
This one uses a limited python language subset. Function calls are easy here but it comes with it's own issues.
For example, `EXTERN` function signatures need to be manually updated and python doesn't integrate well into the Unity Editor.

[Source Code](https://github.com/zz-roba/UdonPieCompiler)

### UdonSharp
```cs
public class SpinningCubes : UdonSharpBehaviour {
    private void Update() {
        transform.Rotate(Vector3.up, 1f);
    }
}
```
Inspired by UdonPieCompiler, MerlinVR developed a C# compiler.
Since traditional Unity scripting is done in this language, this is a well fit.
In addition, most previous issues have been resolved, and even recursion is possible.

Merlin is also well known for releasing various tools to help VRChat world creators like [USharpVideo](https://github.com/MerlinVR/USharpVideo), which uses UdonSharp.
To this date it is the most used compiler and most shared assets require it.
Merlin has since been hired by VRChat with the intention of improving UDON.

[Source Code](https://github.com/MerlinVR/UdonSharp)

### Katsudon
An honerable mention goes out to Katsudon which I haven't looked into enough.

[Source Code](https://github.com/Xytabich/Katsudon)

## Slow down
However, all these are compiled down to the assembly language mentioned above.
Six instructions isn’t a lot compared to other Virtual Machines.
Java's JVM currently has [203](https://en.wikipedia.org/wiki/List_of_Java_bytecode_instructions).
Microsoft's CIL, used by C#, has [229](https://en.wikipedia.org/wiki/List_of_CIL_instructions).
Your CPU runs on over a thousand different instructions.

If you are familiar with how any of these work, you might wonder how basic arithmetic operations function.

### EXTERN
To get anything to happen, UDON code uses its sixth instruction to call into external functions. A simple float addition in UDON looks like this:
```asm
PUSH lhs
PUSH rhs
PUSH output
EXTERN "SystemSingle.__op_Addition__SystemSingle_SystemSingle__SystemSingle"
```

This is **slow**. How slow? In my testing, running against the same C# code running in a mono runtime, **200 times** slower.
This might not be an issue for UDON’s intended use case, but the creative world moves on, and simple buttons and switches aren’t the only things around.
The Mahjong prefab we are using consists of over 6'000 lines of code and compiles to roughly 28'000 instructions. Of those, over 4'000 are "EXTERN" calls.

{{ side_note(text="You could probably consider UDON harmful for the environment") }}

The slowdown caused by this is especially noticeable and irritating in VR.

# Part Two
This second part of the post is about my own work and more subjective.
If you want to call it a day here, just take this one lesson with you:

**Don't roll your own scripting language.**

Use [lua](https://www.lua.org/) like everyone in the industry or [web assembly](https://webassembly.org/), which seems very promissing.
Both of those are on the roadmap for [ChilloutVR](https://store.steampowered.com/app/661130/ChilloutVR/), another social VR platform.

## Go fast
To mitigate these issues, I had to come up with a solution.
Or three.
They are listed here in chronological order.

Having obtained a copy of the [Mahjong table](https://booth.pm/en/items/2300392), I went to work.

### Hooking
2021.06.05

If you aren't familiar with this practice, hooking refers to a practice in modding where you insert a piece of code into the original code that branches into your own code. After your code executes, you can then continue at the intended location or return, preventing the original code from executing.

I could now wait for the VM to execute, check if I need to intervene and run the heavy workload outside the slow UDON runtime.
This helped mitigate the stutter issues I had with the Mahjong CPU.

The good:
- 100% compatibility:
This worked fine in all tested Worlds that integrated the table. World creators never adjusted this portion and if they had, nobody would notice.

The bad:
- limited to specific segments:
Since I could only intervene before the VM spins up I had a very rough control over what code I could replace.
- careful patches:
A lot had to be changed about the original script to make it compatible.
- couldn't mitigate all slowdown:
In the end, to preserve compatibility, I had to skip the first frame of the CPU's turn and only 13/14 lags were mitigated

### Theseus ship
2021.08.09
{{ side_note(text="Is it still UDON if I replace all its parts?") }}

This requires a going a bit deeper into implementation side.
As mentioned above, VRChat is a Unity3D game.
Game logic is written in C# as it's the primary scripting language of Unity.
The default runtime is mono, a CIL interpreter and JIT.

Unity also provides an alternative compiler and runtime called il2cpp.
IL refers to the bytecode language C# compiles to.
il2cpp as such, takes this bytecode language and converts it to C++ code which is then again compiled to native machine code.

This allows Unity games to run on platforms where JIT compilation isn't allowed and interpreting is too slow.
Another side effect is, that the game becomes significantly harder to mod or reverse engineer.

In early 2020 VRChat switched to il2cpp. 

#### Result
See for yourself:

{{ video(url="/blog/udon/fast.webm", width=640, height=360) }}

In this video you can see four table with four Mahjong bots each playing simultaneously. Even with those all running, the game is perfectly playable, if you can tolerate the noise.

- +Massive Speedup:
The Mahjong table execution is sped up by **factor 200**
- +Generally applicable:
Adding new scripts requires no changes to the code
- -Huge inital effort: The initial investment was large
- -Can't adapt to small changes

{{ side_note(text="Noticed how the tiles are clipping into the table?") }}

I published all the glue code as a library in November 2021 [here](https://github.com/HookedBehemoth/UdonUtils) and let it rest.

At the end of December I got messaged by Kitlith, who found the repository and also was interested in speeding up Udon overall.
He started recreating the VM in C# but could only get ~80% of the speed of the original code.

(Explain il2cpp modding barrier?)

Through [Advent of Code](https://adventofcode.com/) I had recently learned Rust which I used to write an [interpreter](https://github.com/kitlith/vrc_udon_shit/blob/target-codegen/native/src/vm/interpreter.rs). Without any special optimization it imediately surpassed the original VM by 5-15%.

### JIT
A Just-in-Time compiler describes a runtime element that compiles code at runtime. Such compilers are found in most scripting languages, such as JavaScript, Ruby or Lua, but also in bytecode VMs like the JVM or mono.

The next attempt to write such a JIT compiler that converts UDON assembly into x86_64 machine code.


Check out our code, [here](https://github.com/kitlith/vrc_udon_shit)

The progress has slowed down over time as I've mostly stopped playing VRChat and only rarely played Mahjong and Kitlith (TODO?).

## The end?
On 2022.07.25, VRChat announced that they will ship the next version with Epic Games' "Easy Anti-Cheat". This would effectively prevent all of these efforts from ever working ingame again.

#### TODO
advise use lua or wasm
