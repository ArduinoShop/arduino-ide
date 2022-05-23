#!/bin/sh

############################################################################
##  Linux install script for Arduino IDE 2.0 - contributed by Art Sayler  ##
##  https://github.com/arduinoshop                                        ##
##
##
############################################################################

echo "\nLinux install script for the Arduino IDE 2.0 ${SCRIPT_PATH}\n"

MODE=U
YN=n
RESOURCE_NAME=cc.arduino.IDE2
RED='\033[0;31m'
NOCOLOR='\033[0m'

if [ -z $1 ]
then
	echo no option selected - defaulting to single user instalation
	echo "usage: ./Linux_Install.sh [local] | [ulocal]"
	echo "        local   - installs IDE for user $USER only ( default if no option given )"
	echo "        ulocal  - uninstall IDE from user $USER"
	echo "usage: sudo ./Linux_Install.sh [system] | [usystem]"	
	echo "        system  - install IDE systemwide for all users (Currently not supported)"
	echo "        usystem - uninstall IDE systemwide from all users\n"
	echo "Both local and system installations may be used on the same computer"
	echo "for example - a stable release installed systemwide and a nightly for a development user"
	echo "The icons are the same but a mouse-over will reveal the difference\n"

	MSG="Install IDE 2.0 for user $USER only?"

elif [ $1 = local ]
then
		MSG="Install IDE 2.0 for user $USER only?"
elif [ $1 = ulocal ]
then
		MSG="UnInstall IDE 2.0 from user $USER?"
		MODE=u
elif [ $1 = usystem ]
then
		MSG="UnInstall IDE 2.0 system wide (all users will be affected)?"
		MODE=s
elif [ $1 = system ]
then
		MSG="Install IDE 2.0 system wide (all users will have access)?"
		MODE=S
fi
	
# Get absolute path from which this script file was executed
# (Could be changed to "pwd -P" to resolve symlinks to their target)
SCRIPT_PATH=$( pwd -P )
LIB_PATH=$SCRIPT_PATH
EXE_PATH=$SCRIPT_PATH
# echo S_PATH = $SCRIPT_PATH

# Install by simply copying desktop file
simple_install_f() {
	echo
#	 Using Simple - MODE = $MODE
###### Remove local user installation
	
	if [ $MODE = u ]
	then
		echo Uninstalling IDE 2.0 from user $USER
		echo "Deleting ${HOME}/.local/share/applications/${RESOURCE_NAME}.desktop"
		rm   ${HOME}/.local/share/applications/${RESOURCE_NAME}.desktop
		
		echo "Deleting ${HOME}/.local/lib/${RESOURCE_NAME}"
		rm -rf ${HOME}/.local/lib/${RESOURCE_NAME}
		
		echo "Deleting ${HOME}/.local/bin/${RESOURCE_NAME}"
		rm   ${HOME}/.local/bin/${RESOURCE_NAME}				
		
#		echo "Installation directory and it's contents including this script can be removed"
#		read -p "Delete directory ${SCRIPT_PATH}? (YES for the affirmative)" YN
#		if [ -z $YN ]
#		then
#			echo exiting; exit
#		elif [ $YN = YES ]
#		then
#			echo "Removing Directory ${SCRIPT_PATH}"
#		fi
	fi

###### Perform local user only installation	
	if [ $MODE = U ]
	then
		
		LIB_PATH=${HOME}/.local/lib/${RESOURCE_NAME}
		EXE_PATH=${HOME}/.local/bin
			
		if [ $YN = Y ] || [ $YN = y ]
		then
			mkdir -p $LIB_PATH
			echo -n "Copying AppImage file... "
			cp -rf * ${HOME}/.local/lib/${RESOURCE_NAME}
			echo "File copied...\n"
		fi
		
		mkdir -p "${HOME}/.local/bin"
		rm -f ${HOME}/.local/bin/${RESOURCE_NAME}
		cp ${HOME}/.local/lib/${RESOURCE_NAME}/*.AppImage ${HOME}/.local/bin/${RESOURCE_NAME}
#		ln -s ${HOME}/.local/lib/${RESOURCE_NAME}/arduino-ide_nightly-20220521_Linux_64bit.AppImage ${HOME}/.local/bin/${RESOURCE_NAME}
#		a link would be more elegant but can't link *.AppImage
	
		# Create a temp dir accessible by all users
		TMP_DIR=`mktemp --directory`

		# Create *.desktop file using the existing template file
		sed -e "s,<BINARY_LOCATION>,${EXE_PATH}/${RESOURCE_NAME},g" \
	    -e "s,<id>,local,g" \
        -e "s,<ICON_NAME>,${LIB_PATH}/${RESOURCE_NAME}.png,g" "${SCRIPT_PATH}/desktop.template" > "${TMP_DIR}/${RESOURCE_NAME}.desktop"

		mkdir -p "${HOME}/.local/share/applications"
		cp "${TMP_DIR}/${RESOURCE_NAME}.desktop" "${HOME}/.local/share/applications/"
		echo "Installing Launcher and Icon"
  
		# mkdir -p "${HOME}/.local/share/metainfo"
		# cp "${SCRIPT_PATH}/lib/appdata.xml" "${HOME}/.local/share/metainfo/${RESOURCE_NAME}.appdata.xml"

gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/.$//), '${RESOURCE_NAME}']"
		# Clean up temp dir
		rm "${TMP_DIR}/${RESOURCE_NAME}.desktop"
		rmdir "${TMP_DIR}"

		echo
		echo 'The IDE 2 icon should now appear in the "Show Application" menu (Super+A) - probably in last position.'
		echo 'You could right-click on this icon and "Add to Favorites" to add it to the Dock.'
	fi

######## System Wide Install / UnInstall
	if [ $MODE = s ] || [ $MODE = S ]
	then
		if [ $USER != root ]
		then
			echo "$RED You must be SuperUser to make SystemWide changes$NOCOLOR\007"
			echo "Use sudo ./Linux_Install.sh [option]\n"
			exit
		fi	
	fi

######## System Wide UnInstall
	
	if [ $MODE = s ]
	then
		echo Uninstalling IDE 2.0 systemwide
		
		if [ -f /usr/local/share/applications/${RESOURCE_NAME}s.desktop ]
		then	
			echo "Deleting /usr/local/share/applications/${RESOURCE_NAME}.desktop"
			rm   /usr/local/share/applications/${RESOURCE_NAME}.desktop
		fi
		
		if [ -f /usr/local/bin/${RESOURCE_NAME}.AppImage ]
			then	
				echo "Deleting /usr/local/bin/${RESOURCE_NAME}.AppImage"
				rm   /usr/local/bin/${RESOURCE_NAME}.AppImage
		fi	

		if [ -d /usr/local/lib/${RESOURCE_NAME} ]
		then	
			echo "Deleting Directory /usr/local/lib/${RESOURCE_NAME}"
			rm -rf /usr/local/lib/${RESOURCE_NAME}
		else
			echo "/usr/local/lib/${RESOURCE_NAME} does not exist"
		fi
		exit		
	fi

###### Perform SystemWide installation	
	if [ $MODE = S ]
	then

		Ver=`lsb_release -d`
		Ver=`echo $Ver | sed -e "s,Description: ,,g"`
		Rev=`echo $Ver | sed -e "s,Ubuntu ,,g" \
	    -e "s, LTS,,g"`
		
		if [ "$Rev" = "22.04" ]; then
			echo "$Ver detected"
			echo "$RED Ubuntu $Rev had a known bug in early releases$NOCOLOR thah would not allow AppImages to run"
			echo "If you find that the IDE will not start you may wish to try"
			echo "adding the FUSE library by running:"
			echo " sudo apt install libfuse2 "
			echo "Ref: https://itsfoss.com/cant-run-appimage-ubuntu"
			echo
			echo "You may perform this installation and update the FUSE libray later,"
			echo "a system reboot after installing the FUSE lib is recommended."
			echo
		fi
		
		echo -n "Copying downloaded files to /usr/local/lib... "
		
		LIB_PATH=/usr/local/lib/${RESOURCE_NAME}
		EXE_PATH=/usr/local/bin
		mkdir -p $LIB_PATH	
		cp -rf * $LIB_PATH
#		rm -f $EXE_PATH/${RESOURCE_NAME}
#		cp ${HOME}/.local/lib/${RESOURCE_NAME}/*.AppImage ${HOME}/.local/bin/${RESOURCE_NAME}
		cp $LIB_PATH/*.AppImage $EXE_PATH/${RESOURCE_NAME}.AppImage
		cp -rf $LIB_PATH/undefined $EXE_PATH
		echo "Files copied...\n"
#	fi
	
		# Create a temp dir accessible by all users
		TMP_DIR=`mktemp --directory`

		# Create *.desktop file using the existing template file
		sed -e "s,<BINARY_LOCATION>,${EXE_PATH}/${RESOURCE_NAME}.AppImage,g" \
	    -e "s,<id>,system,g" \
        -e "s,<ICON_NAME>,${LIB_PATH}/${RESOURCE_NAME}.png,g" "${SCRIPT_PATH}/desktop.template" > "${TMP_DIR}/${RESOURCE_NAME}s.desktop"

		cp "${TMP_DIR}/${RESOURCE_NAME}s.desktop" "/usr/local/share/applications/"
		echo "Launcher and Icon Installed\n"
		echo "Go to \"Show Application\" ( button in lower left / \"Windows Key\")"
		echo "Search for \"Arduino\" - you will see an Icon labeled \"2.0 system\""
		echo "click on this icon to run the IDE or right-click to add it to the Dock\n"
		
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/.$//), '${RESOURCE_NAME}']"		
  
		# Clean up temp dir
		rm "${TMP_DIR}/${RESOURCE_NAME}s.desktop"
		rmdir "${TMP_DIR}"
	fi
 }

# --- main Script starts here ---

read -p "$MSG (Y/N) " YN

if [ -z $YN ]
then
	echo OK - exiting
	exit	
elif [ $YN = n ]
then
	echo OK - No is No... exiting
	exit
fi	

simple_install_f

exit
