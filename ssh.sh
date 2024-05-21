#!/bin/bash

# A simple script to setup SSH for lab machines
# Run this on your local machine
# Download a copy using the "Raw" button on GitHub
# Or by entering these commands into your terminal (replace <username> by your username, e.g. ./ssh.sh kss22):
#   curl https://raw.githubusercontent.com/Gum-Joe/some-tools/master/ssh.sh -o ./ssh.sh
#   chmod +x ./ssh.sh
#   ./ssh.sh <username>

# Usage: ./ssh.sh <username>
# E.g. ./ssh.sh kss22

# By Kishan Sambhi (kss22) (kishansambhi@hotmail.co.uk)
# Created with the help of GitHub Copilot

# MIT License
#
# Copyright (c) Kishan Sambhi
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Version info
VERSION="1.1.0"
LAST_UPDATED="2023-10-18"
AUTHOR="Kishan Sambhi"
AUTHOR_CONTACT="kishansambhi@hotmail.co.uk"
AUTHOR_CONTACT_IMPERIAL="kss22@ic.ac.uk"
REPO_SCRIPT_URL="https://github.com/Gum-Joe/some-tools/blob/master/ssh.sh"
YEAR=$(date +%Y)
TODAY=$(date)

ENABLE_HSK_FLAG="--experimental-hsk"

# Constants
# These define where we're going to write various things
SSH_KEY_NAME="doclab"
SSH_KEY_SCHEME_DEFAULT="ecdsa"
SSH_KEY_SCHEME=$SSH_KEY_SCHEME_DEFAULT
SSH_BITS="521"

# If experiment HSK support is enabled, use it
if [ "$2" = $ENABLE_HSK_FLAG ]; then
  echo "Experimental HSK support enabled."
  echo "PLEASE NOTE: This is untested, proceed at your own risk!"
  SSH_KEY_SCHEME="$SSH_KEY_SCHEME_DEFAULT-sk"
  SSH_BITS="256"
fi

SSH_KEY_BASEPATH="$HOME/.ssh/${SSH_KEY_NAME}_${SSH_KEY_SCHEME}"
SSH_PRIVATE_KEY="${SSH_KEY_BASEPATH}"
SSH_PRIVATE_JUMP_KEY="${SSH_KEY_BASEPATH}_jump"
SSH_PUB_KEY="${SSH_KEY_BASEPATH}.pub"
SSH_PUB_JUMP_KEY="${SSH_PRIVATE_JUMP_KEY}.pub"

# Randomise shell used in case this script becomes popular and we hit one machine
SHELL_NUMBER=$(( (RANDOM % 5) + 1 ))
SHELL_USED="shell$SHELL_NUMBER.doc.ic.ac.uk"

# A simple script to setup SSH for lab machines
# STEPS:
# 1. Create keys locally
# 2. Copy keys to shell
# 3. append to authorized_keys2
# 4. Copy private & pub key to shell server
# 5. Setup ~/.ssh/config
# 6. test
#
# USAGE: ./ssh.sh <username>

############ BEGIN PREAMBLE ############
######
# Here we define some thing that I had to bodge/patch in for fixes etc.
######
# Validate the SSH config works (used by later parts)
validate_ssh_config() {
  echo "Validating...."
  echo "Testing anylab..."
  if echo "echo SSH > /dev/null; exit" | ssh -T anylab > /dev/null; then
    echo "SSH succeeded!"
  else
    echo "SSH failed. This means something went wrong with the script!"
    echo "Please report this to the script creator."
    exit 1
  fi
  echo "Testing vscodelab..."
  if ssh vscodelab "echo 'SSH Auth Successful!' > /dev/null"; then
    echo "SSH succeeded!"
  else
    echo "SSH failed. This means something went wrong with the script!"
    echo "Please report this to the script creator."
    exit 1
  fi
}

USER_FIX_01=$2

# Fix for issue #1, where POSIX paths were used in SSH config files on Windows
# And Windows SSH doesn't like this :(
# We use patch becuase I'm scared awk will modify the wrong thing
# And doing smart analysis to find the right thing is hard!
ISSUE_01_PATH="
--- config_old	2023-06-01 22:39:41.939197300 +0100
+++ config_new	2023-06-01 22:38:37.729020700 +0100
@@ -5,27 +5,27 @@
 Host shell1.doc.ic.ac.uk
   User $USER_FIX_01
   HostName shell1.doc.ic.ac.uk
-  IdentityFile $HOME/.ssh/doclab_ecdsa
+  IdentityFile ~/.ssh/doclab_ecdsa
 
 Host shell2.doc.ic.ac.uk
   User $USER_FIX_01
   HostName shell2.doc.ic.ac.uk
-  IdentityFile $HOME/.ssh/doclab_ecdsa
+  IdentityFile ~/.ssh/doclab_ecdsa
 
 Host shell3.doc.ic.ac.uk
 	User $USER_FIX_01
 	HostName shell3.doc.ic.ac.uk
-	IdentityFile $HOME/.ssh/doclab_ecdsa
+	IdentityFile ~/.ssh/doclab_ecdsa
 
 Host shell4.doc.ic.ac.uk
   User $USER_FIX_01
   HostName shell4.doc.ic.ac.uk
-  IdentityFile $HOME/.ssh/doclab_ecdsa
+  IdentityFile ~/.ssh/doclab_ecdsa
 
 Host shell5.doc.ic.ac.uk
   User $USER_FIX_01
   HostName shell5.doc.ic.ac.uk
-  IdentityFile $HOME/.ssh/doclab_ecdsa
+  IdentityFile ~/.ssh/doclab_ecdsa
 
 # Use this target to SSH into a lab machine with VSCode
 # Fixes a specific machine to SSH into
@@ -47,6 +47,6 @@
   # Explanation of the below: 
 	RemoteCommand ssh -i ~/.ssh/doclab_ecdsa -o StrictHostKeyChecking=no \$(/vol/linux/bin/freelabmachine)
 	RequestTTY yes
-	IdentityFile $HOME/.ssh/doclab_ecdsa
+	IdentityFile ~/.ssh/doclab_ecdsa
 ### END GENERATED BY SSH.SH SCRIPT SECTION ###
" 

fix_issue_01() {
  if [ -z "$1" ]
    then
      echo "Please remember to enter a username as the 2nd argument."
      echo "E.g. ./ssh.sh --fix-windows-ssh kss22"
      exit 1
  fi

  # Safe territory - a username is defined
  USER=$1

  if [ "$USER" = "<username>" ]; then
    echo "ERROR: Please replace <username> with your actual username (imperial shortcode)."
    echo "Example usage: ./ssh.sh --fix-windows-ssh kss22"
    exit 1
  fi
  echo "Attempting fix via patch...."
	echo "Note that we attempt patching several times just in case this script has been ran multiple times."
	echo "Once patch complains about having nothing to patch, we are done."
  echo
	echo -e "\033[1mIF THE PATCH DOESN'T WORK OR FAILS FOR ANY REASON, or you are still asked for your password every time when using VSCode remote SSH:\033[0m You'll need to manually replace all instance of $HOME with ~ (a tilde character) in your SSH config."
  echo "A backup of the unmodified SSH config file before attempting this fix will be at $HOME/.ssh/config.orig"
	echo
  # Run patch several times (JIC script was ran multiple times)
  # Eventually patch fails
  patch_output_1=0
  while [ $patch_output_1 == 0 ]; do
		echo "Patching..."
    patch -sNub $HOME/.ssh/config <(echo "$ISSUE_01_PATH")
    patch_output_1=$?
  done
	echo
  echo "Patch applied!"
  echo "Testing..."
  validate_ssh_config
	echo
	echo "Fix applied & working. My apologies for the inconvenience."
}
############ END PREAMBLE ############


#############################################################
########### BEGIN SCRIPT BODY ###############################
#############################################################
# Prints the help message
echo "Unofficial SSH DoC Imperial setup script, version $VERSION"
echo "Starting SSH setup...."
echo
printhelp() {
  echo "Usage: ./ssh.sh <username>"
  echo "This script sets up SSH for Imperial DoC lab machines for <username>"
  echo "Example usage: ./ssh.sh kss22"
  echo 
  echo "ADDITIONAL OPTIONS:"
  echo "  ./ssh.sh --help - Prints this help message"
  echo "  ./ssh.sh --version - Output version & about info"
  echo "  ./ssh.sh --fix-windows-ssh <username> - Fixes an issue where previous versions of this script prior to 2023-06-01 would generate SSH config files that Windows SSH doesn't like (see issue #1 on GitHub)."
  echo "  ./ssh.sh <username> $ENABLE_HSK_FLAG - Enable experimental support for using hardware security keys to secure SSH keys over a passkey (e.g. YubiKey, Windows Hello etc. NOT TouchID). EXPERIMENTAL, PROCEED AT YOUR OWN RISK."
}

# HACK: Jump to patching my mistake in #1
if [ "$1" = "--fix-windows-ssh" ]; then
  echo "Skipping normal execution to fix windows ssh (issue number #1 on GitHub)..."
  fix_issue_01 $USER_FIX_01
  exit 0
fi

# Some other flag jumps
if [ "$1" = "--help" ]; then
  printhelp
  exit 0
fi
if [ "$1" = "--version" ]; then
  echo "ssh.sh script - used to easily setup SSH into lab machines of Imperial's Department of Computing Science from student's local machines."
  echo 
  echo "Version: $VERSION"
  echo "Last updated: $LAST_UPDATED"
  echo "Author: $AUTHOR <$AUTHOR_CONTACT>"
  echo "Author contact: $AUTHOR_CONTACT"
  echo "Author contact - imperial email: $AUTHOR_CONTACT_IMPERIAL"
  echo "Repo Script URL: $REPO_SCRIPT_URL"  
  echo "(c) $AUTHOR $YEAR"
  echo "Licensed under the MIT License (see script header)."
  exit 0
fi

if [ -z "$1" ]
    then
      echo "---- Please remember to enter a username. ----"
      echo
      printhelp
      exit 0
fi

if [ ! -d "$HOME/.ssh" ]; then
	echo "ERROR: No SSH dir present"
	echo "Creating one..."
  mkdir -p "$HOME/.ssh"
fi

# Safe territory - a username is defined
USER=$1

if [ "$USER" = "<username>" ] || [ "$USER" = $ENABLE_HSK_FLAG ]; then
  echo "ERROR: Please replace <username> with your actual username (imperial shortcode), and ensure it is the first argument."
  echo "Example usage: ./ssh.sh kss22"
  exit 1
fi

echo "Starting Lab SSH Setup for user $USER..."
echo "========================================"
echo "PHASE 1: Local SSH Key Generation"
echo "========================================"
echo "
What's going to happen: 
  We are going to generate SSH keys locally, used to login to the lab machines 
"
echo "Generating SSH keys..."
echo "You will be prompted several times - read the prompts and follow them"
echo "Hit enter to use the default (usually written in () at the end of the prompt) - generally this is what you want to do"
echo
echo "You will also be prompted for a passphrase. This is optional, but recommended. You should not enter one if using experimental HSK support." # Personally I don't have this
echo
ssh-keygen -t $SSH_KEY_SCHEME \
  -b $SSH_BITS \
  -C "$USER@doc.ic.ac.uk Generated by ssh.sh script" \
  -f "$SSH_PRIVATE_KEY"

echo ""
echo "Generating jump key at $SSH_PRIVATE_JUMP_KEY..."
ssh-keygen -t $SSH_KEY_SCHEME_DEFAULT \
  -b $SSH_BITS \
  -C "$USER@doc.ic.ac.uk Generated by ssh.sh script for jump to imperial" \
  -f "$SSH_PRIVATE_JUMP_KEY" \
  -N ""

echo "========================================"
echo "WHAT JUST HAPPENED:"
# Explanation to user of the SSH keys just created, and why they are needed
echo "  We just generated a public and private key pair. The public key is used to identify you to the server, and the private key is used to decrypt messages sent using the public key."
echo "  The public key is stored on the server, and the private key is stored locally. The private key may be encrypted with a passphrase (if you chose one), which you will be prompted for when you login."
echo "  When you login, rather than be prompting for your imperial password, SSH will use these keys automatically to login into the server."
echo "  NEVER SHARE YOUR PRIVATE KEY WITH ANYONE. \
    If you do, they can login to the server as you."
echo "========================================"

# Shouldn't get here!
if [ ! -f "$SSH_PUB_KEY" ]; then
  echo "Error: $SSH_PUB_KEY does not exist."
  exit 1
fi

if [ ! -f "$SSH_PRIVATE_KEY" ]; then
  echo "Error: $SSH_PRIVATE_KEY does not exist."
  exit 1
fi

if [ ! -f "$SSH_PUB_JUMP_KEY" ]; then
  echo "Error: $SSH_PUB_JUMP_KEY does not exist."
  exit 1
fi

if [ ! -f "$SSH_PRIVATE_JUMP_KEY" ]; then
  echo "Error: $SSH_PRIVATE_JUMP_KEY does not exist."
  exit 1
fi


# Copy keys
echo "========================================"
echo "PHASE 2: Copy SSH keys to shell & authorise accross machines"
echo "========================================"
echo "Using ssh-copy-id to copy keys to shell entry points for DoC servers..."
echo "If you see a message like 'Are you sure you want to continue connecting (yes/no/[fingerprint])?', enter 'yes'."
echo "Please enter your REGULAR IMPERIAL LOGIN PASSWORD when prompted the password for $USER@$SHELL_USED (this should be the last time you enter it for an SSH session, from then on use the passcode set for the SSH key if you set one)"
if command -v ssh-copy-id &> /dev/null
then
  # BEGIN: ed8c6549bwf9
    if ssh-copy-id -i "$SSH_PRIVATE_KEY" $USER@$SHELL_USED; then
      echo "SSH key copy succeeded!"
    else
      echo "SSH key copy failed. This means something went wrong with the script!"
      echo "Please report this to the script creator."
      exit 1
    fi
  # END: ed8c6549bwf9
else
  echo
  echo "ssh-copy-id NOT FOUND."
  echo "Falling back to manual alternative..."
  echo
  # From https://stackoverflow.com/questions/22700818/what-exactly-does-ssh-copy-id-do
  cat "$SSH_PUB_KEY" | ssh $USER@$SHELL_USED 'cat >> ~/.ssh/authorized_keys'
fi

# Test auth
echo "Testing SSH auth..."
echo
if ssh -i "$SSH_PRIVATE_KEY" $USER@$SHELL_USED "echo 'SSH Auth Successful!' > /dev/null"; then
  echo "SSH succeeded!"
else
  echo "SSH failed. This means something went wrong with the script!"
  echo "Please report this to the script creator."
  exit 1
fi
echo



# We now attempt to ssh into the shell machine, and copy the keys to the other machines via authorised_keys2
echo "Copying jump keys to shell machine so we can jump for shell machines to DoC machines.."
# Use SCP to copy SSH_PRIVATE_KEY and SSH_PUB_KEY to SHELL_USED using these keys to login
scp -i "$SSH_PRIVATE_KEY" "$SSH_PRIVATE_JUMP_KEY" $USER@$SHELL_USED:~/.ssh/

if [ $? -eq 0 ]; then
  echo "Private key copy done."
else
  echo "Failed to copy keys to shell machine. Exiting..."
  exit 1
fi

scp -i "$SSH_PRIVATE_KEY" "$SSH_PUB_JUMP_KEY" $USER@$SHELL_USED:~/.ssh/

if [ $? -eq 0 ]; then
  echo "Public key copy done."
else
  echo "Failed to copy keys to shell machine. Exiting..."
  exit 1
fi

# We also need to set correct permission
echo "Setting approriate permissions for private keys..."
echo "Setting permission locally (Owner read, write; everyone else: no perms)..."
chmod 600 "$SSH_PRIVATE_KEY"
chmod 600 "$SSH_PRIVATE_JUMP_KEY"
if [ $? -eq 0 ]; then
  echo "Local permission set done."
else
  echo "Failed to set permissions locally. Exiting..."
  exit 1
fi
echo "Setting permissions on shell machines (Owner read, write; everyone else: no perms)..." 
ssh -i "$SSH_PRIVATE_KEY" $USER@$SHELL_USED "chmod 600 ~/.ssh/$(basename "$SSH_PRIVATE_KEY"); chmod 600 ~/.ssh/$(basename "$SSH_PRIVATE_JUMP_KEY");"
if [ $? -eq 0 ]; then
  echo "Remote permission set done."
else
  echo "Failed to set permissions on shell machine for private key. Exiting..."
  exit 1
fi


# Next: Append on machine to authroized_keys2
echo "Appending keys to authorized_keys2 on shell machine..."
echo "This will allow you to login to other DoC machines without having to enter your password."
if ssh -i "$SSH_PRIVATE_KEY" $USER@$SHELL_USED "cat ~/.ssh/$(basename "$SSH_PUB_JUMP_KEY") >> ~/.ssh/authorized_keys2"; then
  echo "Key append done."
else
  echo "Failed to append keys to authorized_keys2 on shell machine. Exiting..."
  exit 1
fi

echo
echo "The necessary presetup is now done - we have created our SSH keys and placed them onto the machines."
echo "We can now SSH into the machines! However we still need to SSH into shell, then the lab to get to lab machine"
echo "Let's make that more convienient by setting up a config file so it's only one command to get to the lab machine."
echo "========================================"
echo "PHASE 3: Setup SSH config file"
echo "========================================"

# Func to pick a lab machine for VSCode to lock onto
choose_lab_machine() {
  echo "Picking a random lab machine to use for VSCode etc...."
  LAB_MACHINE=$(ssh -i "$SSH_PRIVATE_KEY" $USER@$SHELL_USED \"/vol/linux/bin/freelabmachine\")
  if [ $? -eq 0 ]; then
    echo "Picked $LAB_MACHINE"
  else
    echo "Failed to pick a lab machine. Exiting..."
    exit 1
  fi
  SELECTED_LAB_MACHINE=$LAB_MACHINE
}

# Pick lab machine
choose_lab_machine

# TEMPLATE
# There's an issue on Git Bash where it uses POSIX like paths, which windows SSH doesn't like
# So we just use ~ directly!
SSH_PRIVATE_KEY_FILENAME=$(basename "$SSH_PRIVATE_KEY")
SSH_PRIVATE_KEY_FILE_FOR_CONFIG="~/.ssh/$SSH_PRIVATE_KEY_FILENAME"
complete_config="
### GENERATED BY SSH.SH SCRIPT ###
# ssh.sh available at $REPO_SCRIPT_URL
# ssh.sh Version: $VERSION
# ssh.sh last update: $LAST_UPDATED
# Generated on: $TODAY

# These allow us to easily SSH into the shell machines
Host shell1.doc.ic.ac.uk
	User $USER
	HostName shell1.doc.ic.ac.uk
	IdentityFile \"$SSH_PRIVATE_KEY_FILE_FOR_CONFIG\"

Host shell2.doc.ic.ac.uk
	User $USER
	HostName shell2.doc.ic.ac.uk
	IdentityFile \"$SSH_PRIVATE_KEY_FILE_FOR_CONFIG\"

Host shell3.doc.ic.ac.uk
	User $USER
	HostName shell3.doc.ic.ac.uk
	IdentityFile \"$SSH_PRIVATE_KEY_FILE_FOR_CONFIG\"

Host shell4.doc.ic.ac.uk
	User $USER
	HostName shell4.doc.ic.ac.uk
	IdentityFile \"$SSH_PRIVATE_KEY_FILE_FOR_CONFIG\"

Host shell5.doc.ic.ac.uk
	User $USER
	HostName shell5.doc.ic.ac.uk
	IdentityFile \"$SSH_PRIVATE_KEY_FILE_FOR_CONFIG\"

# Use this target to SSH into a lab machine with VSCode
# Fixes a specific machine to SSH into
Host vscodelab
	User $USER
	# Change the machine name below to select a different machine
	# randomly selected at time of script run.
	HostName $SELECTED_LAB_MACHINE
	# randomly selected at time of script run - uses this to get to the lab machine
	ProxyJump $SHELL_USED 
	IdentityFile ~/.ssh/$(basename "$SSH_PRIVATE_JUMP_KEY")

# This one selects a random lab machine to SSH into
# Unfortunately, in my testing it does not work with VSCode
# So the VSCode one has to be fixed to a specific machine
Host anylab
	User $USER
	HostName $SHELL_USED
	# Explanation of the below: 
	RemoteCommand ssh -i ~/.ssh/$(basename "$SSH_PRIVATE_JUMP_KEY") -o StrictHostKeyChecking=no \$(/vol/linux/bin/freelabmachine)
	RequestTTY yes
	IdentityFile \"$SSH_PRIVATE_KEY_FILE_FOR_CONFIG\"
### END GENERATED BY SSH.SH SCRIPT SECTION ###
"

echo "Writing SSH Config file..."
echo "$complete_config" >> "$HOME/.ssh/config"

validate_ssh_config
echo "SSH SETUP COMPLETE!"


# Contributions to automate this are welcome
print_manual_vscode_setting() {
  echo
  echo -e "\033[1mIMPORTANT ADDENUM:\033[0m Getting VSCode Remote SSH to work."
  echo "Unfortunately we're not quite done yet: VSCode Remote SSH will not work properly until you make a small change to your VSCode settings."
  echo "I would make this change automatically, however modifying the settings in a bash script is really hard, and not guaranteed to work accross platforms, and might mess up the settings file if done improperly (contributions to make this automated are welcome)."
  echo "Follow these steps:"
  echo "  1. Open VSCode"
  echo '  2. Open settings (the GUI for settings): keyboard shortcut is "Command+," or "Ctrl+,"'
  echo -e "  3. Search for 'remote.SSH.useLocalServer'. Make sure this is \033[1mUNTICKED\033[0m"
  echo -e "  4. Search for 'remote.SSH.remotePlatform'. Add a new entry called \033[1m'vscodelab'\033[0m with the value \033[1m'linux'\033[0m"
  echo "  5. Your settings save automatically, and now lab machine SSH should work!"
  echo
  echo "========================================"
}

echo "========================================"
echo "Files generated:"
echo "  Your SSH private key is located at: $SSH_PRIVATE_KEY"
echo "  Your SSH public key is located at: $SSH_PUB_KEY"
echo "  Your SSH config file is located at: ~/.ssh/config"
echo "========================================"
echo
echo -e "\033[1mNOW READ THE BELOW:\033[0m"
echo "You can now SSH into the shell machines using the following commands:"
echo
echo -e "\033[1mTO ACCESS LAB MACHINES (the important bit):\033[0m"
echo "  ssh anylab"
echo "  IMPORTANT: This SSH target will NOT work with VSCode or most other SSH dependent tools"
echo 
echo -e "\033[1mVSCODE NOTE: TO ACCESS LAB MACHINES WITH THE \033[4mVSCODE\033[0m\033[1m REMOTE DEV EXTENSION, or in anything that's not a regular linux shell:\033[0m"
echo "(if you don't have this extension, look it up - it lets you use VSCode on your machine as if you are on a remote machine via SSH!)"
echo "Select vscodelab as the target machine when setting up VSCode remote dev"
echo "  ssh vscodelab"
echo
echo -e "\033[1mVSCODE NOTE 2:\033[0m Remote Dev SSH might not immediately work - please see the addenum printed after this section for how to get VSCode Remote Dev SSH to work properly with lab machines"
echo
echo "TO ACCESS LAB SHELLS (these are the shells, not the lab machines themselves! Never work out of these!):"
echo "  ssh shell1.doc.ic.ac.uk"
echo "  ssh shell2.doc.ic.ac.uk"
echo "  ssh shell3.doc.ic.ac.uk"
echo "  ssh shell4.doc.ic.ac.uk"
echo "  ssh shell5.doc.ic.ac.uk"
echo 
echo "NOTE: To get vscodelab to work, we had to pick a specific lab machine to SSH into."
echo "This is fixed (unlike anylab which will pick a random machine each time)"
echo "You can change it in ~/.ssh/config"
echo " Your randomly selected machine was: $SELECTED_LAB_MACHINE"
echo
echo "========================================"
print_manual_vscode_setting
echo "Done."
