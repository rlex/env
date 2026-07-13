# Dotfiles

My dotfiles. 
I started properly curating them... Idk, maybe in 2010? 
So you probably will find weird stuff nobody uses today.

## Main stuff

### Deploy script

1. Can deploy dotfiles using both gnu and bsd coreutils - pure shell, no external dependencies
2. Manages mise install
3. Manages homebrew installs
4. And keep all of this up-to-date in one command!

### Shells

1. I keep only certain shell-specific features in .bashrc and .zshrc to keep them as small as possible.
2. All "generic" settings are placed in sh.d folder - which is sourced from .bashrc/.zshrc.
3. Support for mise and homebrew
4. Prompt color change based on previous quit signal
5. Bunch of random functions and aliases
6. Zsh supports showing current git branch, ssh session state and kubernetes context
7. Bash is intentially left pretty minimal - i only use it as fallback shell
8. Awk calculator (haha)

### Mise

Main powerhorse of that setup.  
Installs tons of tools, allowing to keep versions up-to-date on my two main systems - linux and osx.  
I used to use asdf back when it was written in pure shell, but eventually settled with mise. It's amazing.

### Homebrew

While i'm not a fan of homebrew, it's definitely useful.  
I absolutely hate downloading DMGs and PKGs and installing them manually.  
I have single Brewfile which installs everything i want on new OSX machine and keeps it updated.  

### Kitty

My main terminal emulator choice.  
Used to use iterms2 and yeahconsole+rxvt, but yeahconsole is dead and iterm2 is slower.  
Plus kitty supports both osx and linux.  
Quake-style dropdown terminal option, simple theme, transparency hotkey, custom statusline.

### Vim

Honestly i can't remember all things i installed in vim, but here is some of them:

1. Addons management with vim-plug
2. Powerful autocompletion
3. Additional filetypes useful for sysadmins - nginx/nagios/interfaces/etc
4. Syntax checking
5. And generic stuff like statusbar, bindings, aliases, etc, etc, etc.

### Mutt

Yeah, it's 2026 and i still use mutt. You will find:

1. 256-color theme (yay!)
2. Support for GPG
3. Support for encrypting passwords and profiles using GPG
4. Sourcing system with gitignored file. See .mutt/.localprofile.example
5. A lot of aliases and generic settings (as usual)

### Screen

Pretty generic screen config with compact statusbar and some hacks to avoid known bugs.

### Tmux

Same as screen - pretty simple config with 256 color scheme

### Git

Some additional aliases for better logs and graphs, more color and more minimalistic output.
Oh, and if you will use this config - **change name, mail and signing key to yours**

### Binaries

I keep some big pieces of code in .bin folder, for example:

1. ack. It's better than grep!
2. speedtest
... And so on.

This folder is added to $PATH, so all apps will be available in shell

### LLM skills

While i'm not a fan of so-called "AI" and i absolutely despise media GenAI it's hard to ignore useful tool.  
There is some agent skills in .agents folder - mostly integrations with tools i use and some generic stuff.  
I try to give proper credits to authors, but sometimes i just find random skill on random website without any credits.

### Small stuff

1. Colored top (linux only)
2. Simple openbox+tint2 config with numix gtk theme
3. More friendly htop
4. Some settings for ack
5. Some settings for mc
6. Unfinished mailcap
7. Generic dircolors
8. Some things i can't remember

## Legacy

### X server settings

I used to use linux desktop as my main OS, i'm not anymore but i kept this settings just in case.
My main apps were yeahconsole, awesome WM, and rxvt terminal. So, in .Xdefaults you will find:

1. Soft colorscheme for xterm and urxvt
2. Terminus font for terminal - obviously, should be installed separately
3. Yeahconsole config - quake-style urxvt-backed terminal

### Awesome WM

(Notice: not working with awesome 3.5. I loved awesome, but i grew a bit tired from fixing lua config every time devs changed API. Plus plasma became much better over years.)

Awesome WM is, uh, awesome tiling window manager. Things you will find in my config:

1. Tiny menubar to maximize usable space. Supports sound, battery and load widgets, but you can add anything here with a bit of LUA code
2. Dynamic tiling - why keep tiles without any windows?
3. Fallback mode - if you will break your awesome config, WM will just load with default - so you can quickly fix your code.
4. Some pre-defined tiles and binds.
