#!/bin/bash
# Script to download and install pycharm from JetBrains on OpenSuSE.
# Installs to a subdirectory of /usr/local/bin/ , fixes permissions
# issues and creates an Application Launcher entry

# Command Line Arguments:
# Requires:
#   EITHER: an absolute path to an already-downloaed PyCharm tar.gz archive
#   OR: an URL to download the PyCharm tar.gz archive from

# Example URLs:
# https://download.jetbrains.com/python/pycharm-professional-2021.2.3.tar.gz
# https://download.jetbrains.com/python/pycharm-community-2021.2.3.tar.gz

# User configurable variables:
INSTALLDIR='/usr/local/bin'
TEMPDIR='/tmp'

# Check if the script is being run as the root user, otherwise exit
if [ "$(whoami)" != 'root' ]
then
	echo 'Script must be run as root to install JetBrains PyCharm'
	exit 1;
else
	echo 'Excellent, you are running this script as root'
fi

# Check $TEMPDIR exists else issue warning and exit
if [ -d "$TEMPDIR" ]
then
	# Additionally check $TEMPDIR is writable
	if [ -w "$TEMPDIR" ]
	then
		echo "Temporary directory $TEMPDIR exists and is writable, continuing..."
	else
		echo "Temporary directory $TEMPDIR exists but is not writable"
		echo "Please make it writable and re-run the script"
		exit 1;
	fi
else
	echo "Temporary directory $TEMPDIR does not exist"
	echo "Please create it and re-run the script"
	exit 1;
fi

# Check $INSTALLDIR exists else issue warning and exit
if [ -d "$INSTALLDIR" ]
then
	# Additionally check $INSTALLDIR is writable
	if [ -w "$INSTALLDIR" ]
	then
		echo "Installation directory $INSTALLDIR exists and is writable, continuing..."
	else
		echo "Installation directory $INSTALLDIR exists but is not writable"
		echo "Please make it writable and re-run the script"
		exit 1;
	fi
else
	echo "Installation directory $INSTALLDIR does not exist"
	echo "Please create it and re-run the script"
	exit 1;
fi

# Check if the script has been supplied with a command line argument
# If not, exit with a message
if [ -z "$1" ]
then
	echo 'Script must be supplied with:'
	echo 'EITHER: an absolute path to an already-downloaed PyCharm tar.gz archive'
	echo 'OR:     an URL to download the PyCharm tar.gz archive from'
	exit 1;
fi

MATCHTARGZ='^\/.*\.tar\.gz$'
MATCHURL='^http.*\.tar\.gz$'
MATCHPATH=''
# Check path/url supplied as a command line argument is for a .tar.gz file
if [[ "$1" =~ $MATCHTARGZ ]]
then
	echo 'Absolute path to a tar.gz archive file detected, continuing...'
elif [[ "$1" =~ $MATCHURL ]]
then
	echo 'URL detected, continuing...'
else
	echo 'Script must be supplied with:'
	echo 'EITHER: an absolute path to an already-downloaed PyCharm tar.gz archive'
	echo 'OR:     an URL to download the PyCharm tar.gz archive from'
	exit 1;
fi

# copy file to TEMPDIR or download file from supplied url to TEMPDIR
FILENAME=''
if [[ "$1" =~ $MATCHURL ]]
then
	FILENAME=$(basename "$1" .tar.gz)
	echo "Command line argument $1 identified as an URL"
	echo "Setting download directory to $TEMPDIR"
	echo "FILENAME is $FILENAME"
	echo "Downloading $FILENAME now..."
	wget -c -P "$TEMPDIR" "$1"
elif [[ "$1" =~ $MATCHPATH ]]
then
	echo "Command line argument '$1' identified as an absolute path"
	FILENAME=$(basename "$1" .tar.gz)
	echo "FILENAME is $FILENAME"
	echo "Copying $FILENAME to $TEMPDIR"
	cp "$1" "$TEMPDIR/"
else
	echo "Command line argument $1 NOT identified as either a path or an url"
        echo 'Script must be supplied with:'
        echo 'EITHER: an absolute path to an already-downloaed PyCharm tar.gz archive'
        echo 'OR:     an URL to download the PyCharm tar.gz archive from'
	exit 1;
fi

cd "$TEMPDIR" || exit 1;

# check if the version this script has been asked to install is already installed
# the professional version does not have 'professional' in its directory name
# whereas the community version does retain 'community' in its directory name
# INSTALLEDNAME=$(echo "$FILENAME" | sed 's/professional-//')
INSTALLEDNAME="${FILENAME//professional-/}"
if [ -z "$INSTALLEDNAME" ]
then
	echo "The name of the installation directory is NULL. This is wrong; exiting..."
	exit 1;
fi
echo "Installation base directory is $INSTALLDIR"
echo "Installation subdirectory is $INSTALLEDNAME"
# ls "$INSTALLDIR" | grep -E "^$INSTALLEDNAME\$"
# if [ $? -eq 0 ]
if ls "$INSTALLDIR" | grep -E "^$INSTALLEDNAME\$"
then
	echo "The version of PyCharm you are asking to be installed is already installed"
	echo "If the current install of this version is broken, please manually delete it"
	echo "before re-running the script. The following command can be used to delete it:"
	echo "'sudo rm -r $INSTALLDIR/$INSTALLEDNAME'"
	exit 1;
else
	echo "Proceeding with installation..."
fi

# keep a list of versions of PyCharm already installed and inform the user
# $EXISTINGVERSIONS is also used later on...
# EXISTINGVERSIONS=$(ls "$INSTALLDIR" | grep -E 'pycharm-')
EXISTINGVERSIONS=$(find "$INSTALLDIR" -mindepth 1 -maxdepth 1 -type d -name 'pycharm*')
# Carry out a sed substitution on EXISTINGVERSIONS to remove the INSTALLDIR path
EXISTINGVERSIONS=$(echo "$EXISTINGVERSIONS" | sed "s|$INSTALLDIR/||")
# Iterate through all values stored in $EXISTINGVERSIONS and number them sequentially
echo "The following versions of PyCharm are already installed: $EXISTINGVERSIONS"
VERSIONCOUNTER=1;
for i in $EXISTINGVERSIONS
do
	echo "$VERSIONCOUNTER: $i"
	VERSIONCOUNTER=$(($VERSIONCOUNTER+1))
done

# extract the pycharm .tar.gz file to /usr/local/bin
tar -xzf "$TEMPDIR/$FILENAME.tar.gz" -C "$INSTALLDIR"
rm "$TEMPDIR/$FILENAME.tar.gz"

# work on changing permissions to let any user run PyCharm
# by default, files extracted from the tar.gz archive have permissions 640
# and directories extracted from the tar.gz archive have permissions 750

cd "$INSTALLDIR" || exit 1;
chmod 755 "$INSTALLDIR/$INSTALLEDNAME"
cd "$INSTALLDIR/$INSTALLEDNAME" || exit 1;
# directories are simple, all are 750, change all to 755
find "$INSTALLDIR/$INSTALLEDNAME" -type d -execdir chmod o+rx {} \;
# differentiate between executable and non-executable files
find "$INSTALLDIR/$INSTALLEDNAME" -type f -perm 640 -execdir chmod o+r {} \;
find "$INSTALLDIR/$INSTALLEDNAME" -type f -perm 750 -execdir chmod o+rx {} \;

# create or update link between $INSTALLDIR/pycharm and $INSTALLDIR/$INSTALLEDNAME/bin/pycharm.sh
if [ -L $INSTALLDIR/pycharm ]
then
	# echo "Symbolic link $INSTALLDIR/pycharm already exists and points to PyCharm version $(ls -l $INSTALLDIR/pycharm | cut -d ' ' -f 12)"
	echo "Symbolic link $INSTALLDIR/pycharm already exists and points to PyCharm version $(find "$INSTALLDIR" -type l -name pycharm | cut -d ' ' -f 12)"
	echo "Updating symbolic link $INSTALLDIR/pycharm to $INSTALLDIR/$INSTALLEDNAME/bin/pycharm.sh"
	ln -sf "$INSTALLDIR/$INSTALLEDNAME/bin/pycharm.sh" "$INSTALLDIR/pycharm"
else
	echo "Creating symbolic link $INSTALLDIR/pycharm to $INSTALLDIR/$INSTALLEDNAME/bin/pycharm.sh"
        ln -sf "$INSTALLDIR/$INSTALLEDNAME/bin/pycharm.sh" "$INSTALLDIR/pycharm"
fi

# Create Application Launcher entry for PyCharm in folder /usr/local/share/applications/
# mime types found in /etc/mime.types
SHORTCUTDIR="/usr/local/share/applications"
DESKTOPFILE="$TEMPDIR/JetBrains-PyCharm.desktop"

if [ ! -d "$SHORTCUTDIR" ]
then
	mkdir -p "$SHORTCUTDIR"
else
	if [[ "$FILENAME" =~ 'professional' ]]
	then
		NICENAME='PyCharm Professional Edition'
	elif [[ "$FILENAME" =~ 'community' ]]
	then
		NICENAME='PyCharm Community Edition'
	else
		NICENAME='PyCharm'
	fi
	echo '[Desktop Entry]'          > "$DESKTOPFILE"
	echo "Name=$NICENAME"           >> "$DESKTOPFILE"
	echo 'GenericName=JetBrains Python IDE' >> "$DESKTOPFILE"
	echo 'Comment=Python IDE'       >> "$DESKTOPFILE"
	echo "Exec=$INSTALLDIR/pycharm %F" >> "$DESKTOPFILE"
	echo 'Terminal=false'           >> "$DESKTOPFILE"
	echo 'Type=Application'         >> "$DESKTOPFILE"
	echo "Icon=$INSTALLDIR/$INSTALLEDNAME/bin/pycharm.svg"  >> "$DESKTOPFILE"
	echo 'StartupNotify=true'       >> "$DESKTOPFILE"
	echo 'Categories=Development;'  >> "$DESKTOPFILE"
	echo 'MimeType=application/x-python-bytecode;text/x-python' >> "$DESKTOPFILE"
fi

chmod 644 "$DESKTOPFILE"

# Regenerate Application Launcher to include the new PyCharm entry (KDE specific)
#kbuildsycoca5

# Regenerate Application Launcher to include the new PyCharm entry (Desktop Environment-agnostic)
xdg-desktop-menu install --mode system "$DESKTOPFILE"
xdg-desktop-menu forceupdate --mode system
rm "$DESKTOPFILE"


echo "Added an entry for PyCharm to the 'Development' category of the application menu system"

# Print list of previously installed versions that have been retained
if [ -n "$EXISTINGVERSIONS" ]
then
	echo "List of previously installed versions of PyCharm:"
	echo "$EXISTINGVERSIONS"
fi
echo "Current installed version is now $FILENAME and is ready to use"
echo "It may be necessary to log-out and log-in again for the PyCharm entry in the Applicaiton Menu to become visible"
