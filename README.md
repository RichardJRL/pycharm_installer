# pycharm_installer

Bash script to install JetBrains PyCharm on Linux.

## Functions
- Install PyCharm in /usr/local/bin
- Modify permissions so that all users can run it
- Add an entry, with icon, for PyCharm to the "Development" section of the desktop environment's application menu

## Requirements
- Script must be run as root
- Script must be supplied with one of the following as a command line argument:
  - EITHER: an absolute path to an already-downloaed PyCharm tar.gz archive
  - OR:     an URL to download the PyCharm tar.gz archive from

## Where to get PyCharm
[https://www.jetbrains.com/pycharm/download/#section=linux](https://www.jetbrains.com/pycharm/download/#section=linux)
