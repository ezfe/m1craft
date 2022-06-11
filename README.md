# m1craft

Run Minecraft 1.17 and 1.18 without installing any profiles, json files, or jars.

This tool does **not** modify either the Minecraft JAR or LWJGL JARs. The Minecraft JAR is downloaded unmodified from Minecraft, and the LWJGL jars are pre-built 3.3.0 (3.3.1 for 22w16a and later) directly from lwjgl.org

Download: https://m1craft.ezekiel.dev

**Warning:** Do not use the Minecraft fullscreen option, instead use the system one (green button). If you've used the Minecraft one and it's crashing, follow the steps [here](https://github.com/ezfe/m1craft/issues/5#issuecomment-972287174)

<img width="612" alt="Screen Shot 2022-06-11 at 4 58 00 PM" src="https://user-images.githubusercontent.com/1449259/173204665-0cabb812-4e7d-4a94-ba59-d5d63d305b6c.png">

Tip: If you would like to run custom versions that do not appear selectable in the UI, you can set the version to play manually via terminal:
```
defaults write dev.ezekiel.m1craft selected-version "<version here>"
```

Note: 1.18 and later can be run directly from the official Minecraft launcher. Follow instructions [here](https://gist.github.com/ezfe/8bc43a65e16b79c955f81b4d7fa4ae6a) if you'd prefer to do this instead – including if you need to mod the game. However this launcher is still easier (no install steps needed).
