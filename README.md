# m1craft

Run Minecraft 1.17 and 1.18 without installing any profiles, json files, or jars.

This tool does **not** modify either the Minecraft JAR or LWJGL JARs. The Minecraft JAR is downloaded unmodified from Minecraft, and the LWJGL jars are pre-built 3.3.0 directly from lwjgl.org

Head on over to the [releases](https://github.com/ezfe/m1craft/releases) page to download.

**Warning:** Do not use the Minecraft fullscreen option, instead use the system one (green button). If you've used the Minecraft one and it's crashing, follow the steps [here](https://github.com/ezfe/m1craft/issues/5#issuecomment-972287174)

<img width="612" alt="Screen Shot 2021-11-16 at 9 29 01 PM" src="https://user-images.githubusercontent.com/1449259/142104275-2a26e5c8-8ef0-4bf1-a3a2-dd5938650b52.png">

Tip: If you would like to run custom versions that do not appear selectable in the UI, you can set the version to play manually via terminal:
```
defaults write dev.ezekiel.m1craft selected-version "<version here>"
```
This will only work with 19w11a and later, which includes 1.14.

Note: 1.18 and later can be run directly from the official Minecraft launcher. Follow instructions [here](https://gist.github.com/ezfe/8bc43a65e16b79c955f81b4d7fa4ae6a) if you'd prefer to do this instead – including if you need to mod the game. However this launcher is still easier (no install steps needed).
