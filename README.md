# Samsung firmware merge tools

### This script is currently in it's early stages.

### This only works for the S24x and earlier (for now)
#
# How to use MergeAll.sh

Using MergeAll.sh is very simple, all it takes is a few commands to set it up and merging straight away!

If you are using a Debian based disro (such as Ubuntu) then MergeAll installs all the required dependencies for you.

If you are NOT using a Debian based distro the required dependencies are: 

`unzip tar lz4`

Firstly, clone my repo with git

```bash 
git clone https://github.com/EndaDwagon/MergeAll
```

Now CD to the clone

```bash
cd MergeAll
```

Now start merging with the command below!

```bash
./MergeAll.sh [path to ODIN firmware ZIP] [path to update BIN]
```

#

Command to cleanup EVERYTHING if something has failed, or if you want to merge for another device

```bash
./MergeAll.sh cleanup
```

WARNING: The command to cleanup everything WILL delete all of the images and files in the MergeAll folder, excluding the files required to run MergeAll again.
