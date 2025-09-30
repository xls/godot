Welcome
# Godot + GodotJS
Setup instructions to build Godot + GodotJS (latest from xls dev branch)


## Prerequisites
Follow instructions on how to set up scons and python -> [godot online Documentation](https://docs.godotengine.org/en/latest/engine_details/development/compiling/compiling_for_windows.html)


### Visual Studio 2022
python - 3.9+ and scons
node | npm | pnpm -> [Node installation via NVM](https://github.com/coreybutler/nvm-windows)

### pnpm installation
``` 
npm install -g pnpm
```



## Bootstrap automatic setup for Windows
Script tasks:
* check for prerequisites
* clone godot ➡️ .\godot
* clone GodotJS ➡️ .\godot\modules\GodotJS
* pnpm install ➡️ .\godot\modules\GodotJS
* pnpm build ➡️ .\godot\modules\GodotJS
* scons ➡️ .\godot

*the script only modifies files in the repository (godot\..) and your environment should be untouched.*
*script can be run repeatedly*
```
curl -L -o bootstrap.bat https://raw.githubusercontent.com/xls/godot/refs/heads/4.5-dev/bootstrap.bat && cmd /c bootstrap.bat && del bootstrap.bat
```

### bootstrap.bat script usage

#### Build release binary
```
bootstrap
```
*binaries output in the bin folder.*

#### Open up Visual Studio solution using --vstudio argument
```
bootstrap --vstudio
```
*Visual Studio solution for Godot will open up if script completes successfully.*






## Manual Setup

```
git clone -b 4.5-dev --recursive https://github.com/xls/godot 
cd godot
```

### Clone GodotJS and download v8 dependency to ./modules/GodotJS/v8 
```
pushd
cd modules
git clone -b 4.5-dev --recursive https://github.com/xls/GodotJS
curl -L -o v8_12.9.202.28_v1.0.zip https://github.com/xls/V8-libraries/releases/download/v8_12.9.202.28_v1.0/v8_12.9.202.28_v1.0.zip
tar -xf v8_12.9.202.28_v1.0.zip
del v8_12.9.202.28_v1.0.zip
popd
```
### Generate GodotJS TypeScript files
```
pushd
cd modules\GodotJS
pnpm install
pnpm build
popd
```

### Generate Visual Studio project (debug)
```
scons platform=windows dev\_mode=yes vsproj=yes
```
### Generate binaries (release)
```
scons platform=windows
```

