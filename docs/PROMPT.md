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

  The image /Volumes/KnulliBuild/output/h700/images/knulli/images/rg34xx-sp/knulli-h700-rg34xx-sp-scarab-20260926_boot.tar.gz is not booting. Has it been set up with the correct boot sector and file systems?

  It booted.
  What was the issue with missing keys?

To clarify - I do not yet have a scraper key
  ## Bug fixes
  - ssh and samba do not work on anything but ext4 partitions
  - Screenscarper does not work on ext4
  - WiFi does not reliably connect or stay connected on WPA2 ssid

  ToDo
  - Test WPA3, ssh & samna
  - Implement
    - Scraper
    - DS Plus

    ## Diskimage

    Creating disk image
  Now in startup

  ## DS Plus

Are there any DS build options so far?
The Anberic image is here: /Volumes/KnulliBuild/anbernic/RG-DS-PLUS-EN16GB-20260915.zip