# KNULLI-LINUX - fork - try to build Anbernic DS Plus (H700 variant)
## Initialize CLAUDE, AGENTS, CHAT ETC

Intialize the AGENTIC work environment brought over from another project
- CLAUDE
- AGENTS
- DECISIONS

Pull upstream branches, switch to Development and handle the potential conflict.

Update .gitignore and add all my workspace files.
Push all the changes to Development

What is your recommended Docker solution?
- OrbStack
- Native Apple
    brew install container
    container system start
    container build -t buildenv .
    container run -it --rm -c 8 -m 16G -v "$PWD":/build buildenv

 ==> findutils
All commands have been installed with the prefix "g".
If you need to use these commands with their normal names, you
can add a "gnubin" directory to your PATH from your bashrc like:
  PATH="/opt/homebrew/opt/findutils/libexec/gnubin:$PATH"
==> coreutils
Commands also provided by macOS and the commands dir, dircolors, vdir have been installed with the prefix "g".
If you need to use these commands with their normal names, you can add a "gnubin" directory to your PATH with:
  PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"


## First build
  Start docker and do an intial build.
  Debug indendently untili it completes