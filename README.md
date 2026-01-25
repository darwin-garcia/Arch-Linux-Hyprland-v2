# Arch Linux (Hyprland/Wayland)

Arch Linux Ricing with Hyprland (Basic Settings) for ThinkPad Laptops
👉[Haz clic aqui](https://github.com/darwin-garcia/Arch-Linux-Hyprland/tree/main/Instrucciones) para ver mas instrucciones de instalacion de Arch Linux

<p> Este repositorio tiene las configuraciones sencillas y minimas para ajustar el entorno de Escritorio a una maquina con Arch Linux instalado desde cero.</p>

[Haz Clic Aqui](https://github.com/darwin-garcia/Arch-Linux-Hyprland/tree/main/Instrucciones/Hyprland) para ver las Instrucciones de Instalacion de mi entorno con Hyprland

## 🖼 Screenshots
![Desktop.](https://raw.githubusercontent.com/darwin-garcia/Arch-Linux-Hyprland-v2/refs/heads/main/Screenshots/Desktop%20Full%20v2.png)
![Terminal.](https://raw.githubusercontent.com/darwin-garcia/Arch-Linux-Hyprland-v2/refs/heads/main/Screenshots/Desktop%20Terminal.png)
![Fetch.](https://raw.githubusercontent.com/darwin-garcia/Arch-Linux-Hyprland-v2/refs/heads/main/Screenshots/Fastfetch.png)
![Lock Screen.](https://raw.githubusercontent.com/darwin-garcia/Arch-Linux-Hyprland-v2/refs/heads/main/Screenshots/Lock%20Screen.png)

## 📽 Video

https://github.com/user-attachments/assets/b4a7a4a3-628c-465a-9f9b-964d6b4e1d70

## ⚙ My Settings (Mis Configuraciones)

Official Repo
* [Waybar](https://github.com/Alexays/Waybar): Taskbar on top
* [Rofi](https://github.com/davatorium/rofi): Start Menu Launcher
* [Kitty](https://sw.kovidgoyal.net/kitty/): Terminal App
* [Ranger](https://github.com/ranger/ranger): File Explorer on Terminal 
* [LazyVim](https://www.lazyvim.org/): Text Editor IDE based
* [OhMyZSH](https://ohmyz.sh/#install): Terminal Shell

Este escritorio fue rediseñado del primer repositorio publicado anteriormente

#### Mas sobre Instalacion de Arch Linux
👉[Haz clic aqui](https://github.com/darwin-garcia/Arch-Linux-Hyprland/tree/main/Instrucciones) para ver mas instrucciones de instalacion de Arch Linux

#### ⚠️ Detalles a tener en cuenta
La instalación realizada, responderá mejor en una máquina física. Las máquinas virtuales suelen dar más problemas en Hyprland excepto con la virtualización KVM. Este repositorio esta enfocado en laptops/portatiles para aprovechar todo los componentes configurados.

### Instalar el AUR
`sudo pacman -Syu && git clone https://aur.archlinux.org/yay-git.git && cd yay-git && makepkg -si`

### ⚠ ¡OhMyZSH! 😲🤖
1. Instalar el ZSH: `sudo pacman -S zsh zsh-completions`
2. Elegir el shell por defecto `chsh -s /bin/zsh` o `chsh -s $(which zsh)`. Luego cierra la sesion y todas las terminales abiertas para que los cambios tengan efecto. Puedes consultar el shell actual: `chsh -l`
3. Instalar el [OhMyZSH](https://ohmyz.sh/#install)
4. Instalar los [plugins](https://github.com/ohmyzsh/ohmyzsh/wiki/plugins) de [OhMyZSH](https://ohmyz.sh/#install). [Mas información](https://catalins.tech/zsh-plugins/) o [Más completa](https://travis.media/blog/top-10-oh-my-zsh-plugins-for-productive-developers/). Utilizo los siguientes plugins:
   * `zsh-autosuggestions` => `git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions`
   * `zsh-syntax-highlighting` o `zsh-fast-syntax-highlighting` => `git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting`
   * `zsh-history-substring-search` => `git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search`
   * `colored-man-pages` => `plugins=(..., colored-man-pages)`
6. Actualizar: `omz update`
7. (opcional) Copia y pega el archivo `.zshrc` de tu usuario `/home/$USER` que se ubica en este repositorio

GUI instalado en mi Arch Linux
(DM) Desktop Manager
Cinnamon
Pantheon
(WM) Window Manager
BSPWM
Hyprland

Probado en Julio 2025 👨‍💻 ©MMXXV. Darwin Garcia. 🇨🇴

