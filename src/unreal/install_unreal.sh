#!/usr/bin/env bash
set -ex
SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"

apt-get update
apt-get install -y p7zip-full jq unshield coreutils

mkdir -p /opt/unreal
wget https://raw.githubusercontent.com/OldUnreal/FullGameInstallers/master/Linux/install-unreal.sh
chmod +x install-unreal.sh

printf 'Y\n' | ./install-unreal.sh --destination=/opt/unreal/ --ui-mode=none --desktop-shortcut=skip --application-entry=skip

rm install-unreal.sh

cat >/opt/unreal/launch.sh <<EOL
#!/usr/bin/env bash
ARCH=\$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')
if [ "\$ARCH" == "arm64" ] ; then
  export LD_LIBRARY_PATH=/opt/unreal/SystemARM64:\$LD_LIBRARY_PATH
  if [ -f /opt/VirtualGL/bin/vglrun ] && [ ! -z "\${KASM_EGL_CARD}" ] && [ ! -z "\${KASM_RENDERD}" ] && [ -O "\${KASM_RENDERD}" ] && [ -O "\${KASM_EGL_CARD}" ] ; then
    echo "Starting Unreal with GPU Acceleration on EGL device \${KASM_EGL_CARD}"
    vglrun -d "\${KASM_EGL_CARD}" /opt/unreal/SystemARM64/unreal-bin-arm64 "\$@"
  else
      echo "Starting Unreal"
      /opt/unreal/SystemARM64/unreal-bin-arm64 "\$@"
  fi
else
  export LD_LIBRARY_PATH=/opt/unreal/System64:\$LD_LIBRARY_PATH
  if [ -f /opt/VirtualGL/bin/vglrun ] && [ ! -z "\${KASM_EGL_CARD}" ] && [ ! -z "\${KASM_RENDERD}" ] && [ -O "\${KASM_RENDERD}" ] && [ -O "\${KASM_EGL_CARD}" ] ; then
    echo "Starting Unreal with GPU Acceleration on EGL device \${KASM_EGL_CARD}"
    vglrun -d "\${KASM_EGL_CARD}" /opt/unreal/System64/unreal-bin-amd64 "\$@"
  else
      echo "Starting Unreal"
      /opt/unreal/System64/unreal-bin-amd64 "\$@"
  fi
fi
EOL

# Previous Symlinks needed
#cd /opt/unreal/System64/
#ln -s libSDL3-3.0.so.0 libSDL3.so.0
#ln -s libSDL3_ttf-3.0.so.0 libSDL3_ttf.so.0

#cd /opt/unreal/SystemARM64/
#ln -s libSDL3-3.0.so.0 libSDL3.so.0
#ln -s libSDL3_ttf-3.0.so.0 libSDL3_ttf.so.0

chmod +x /opt/unreal/launch.sh

sed -i 's/StartupFullscreen=True/StartupFullscreen=False/' /opt/unreal/System64/DefaultLinux.ini
sed -i 's/UseFullscreen=True/UseFullscreen=False/' /opt/unreal/System64/DefaultLinux.ini
sed -i 's/UseJoystick=False/UseJoystick=True/' /opt/unreal/System64/DefaultLinux.ini

sed -i 's/StartupFullscreen=True/StartupFullscreen=False/' /opt/unreal/System/Default.ini
sed -i 's/UseFullscreen=True/UseFullscreen=False/' /opt/unreal/System/Default.ini
sed -i 's/UseJoystick=False/UseJoystick=True/' /opt/unreal/System/Default.ini

sed -i 's/StartupFullscreen=True/StartupFullscreen=False/' /opt/unreal/System/DefaultLinux.ini
sed -i 's/UseFullscreen=True/UseFullscreen=False/' /opt/unreal/System/DefaultLinux.ini
sed -i 's/UseJoystick=False/UseJoystick=True/' /opt/unreal/System/DefaultLinux.ini

# Drop back to standard OpenGL otherwise the game wont run without a GPU
sed -i 's/^GameRenderDevice=.*/GameRenderDevice=OpenGLDrv.OpenGLRenderDevice/' /opt/unreal/System64/DefaultLinux.ini
sed -i 's/^GameRenderDevice=.*/GameRenderDevice=OpenGLDrv.OpenGLRenderDevice/' /opt/unreal/System/DefaultLinux.ini

cp /opt/unreal/System/DefaultLinux.ini /opt/unreal/SystemARM64/
cp /opt/unreal/System/DefUser.ini /opt/unreal/SystemARM64/


chown -R 1000:1000 /opt/unreal

cat >$HOME/Desktop/unreal.desktop <<EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=Unreal
GenericName=Game
Comment=Unreal
Exec=/opt/unreal/launch.sh %F
Path=/opt/unreal/
Terminal=false
MimeType=text/plain;
Icon=/opt/unreal/Help/Unreal.ico
Categories=Graphics;Utility;
StartupNotify=true
EOL

chmod +x $HOME/Desktop/unreal.desktop
chown 1000:1000 $HOME/Desktop/unreal.desktop