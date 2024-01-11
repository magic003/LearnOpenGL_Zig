# learnopengl.com code in Zig
This repo contains the code I wrote when reading the Learn OpenGL [book](https://learnopengl.com/) using Zig.

## Code organization
The code is organized according to the parts and chapters in the book. For example, `I_Getting_Started/4_1_hello_window`.

The shared libraries live in the `libs` folder.

## Zig version
The code was tested using Zig 0.12.0-dev.1856+94c63f31f and above. It will keep up with the master version.

## How to run it
To run a particular sample, just go to its folder and run `zig build run`.

```shell
LearnOpenGL_Zig % cd I_Getting_Started/4_1_hello_window
4_1_hello_window % zig build run
```

## Dependencies
This repo depends on the following external libraries:
* [mach_glfw](https://machengine.org/pkg/mach-glfw/): GLFW bindings for Zig.
* [zig-opengl](https://github.com/MasterQ32/zig-opengl): used to generate the OpenGL bindings for Zig.
* [stb-image.h](https://github.com/nothings/stb/blob/master/stb_image.h): a single-file public domain library for image in C/C++.
* [zmath](https://github.com/zig-gamedev/zig-gamedev/tree/main/libs/zmath): SIMD math library for game developers in Zig. It's replacement of glm for Zig.

## References
* [JoeyDeVries/LearnOpenGL](https://github.com/JoeyDeVries/LearnOpenGL): the official repo for code samples of the book. This repo tries to keep the structure and style as close as it.
* [zig_learn_opengl](https://github.com/craftlinks/zig_learn_opengl): an existing repo for the code samples in Zig. This repo learns a lot from it, especially which Zig library to use.
