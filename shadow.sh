#!/bin/bash
# Define colors
YELLOW="\033[0;93m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
RED="\033[0;31m"
NC="\033[0m"

ROOT_LIST=`ls /`
KEEP_SHADOW_ENV=${KEEP_SHADOW_ENV:=""}
IGNORE_LIST=${IGNORE_LIST:="dev proc sys"}
CLEAR_LIST=${CLEAR_LIST:="/mnt /run /var/run"}
SHADOW_IMG=${SHADOW_IMG:="shadow"}
SHADOW_PERFIX=${SHADOW_PERFIX:="SHADOW-"}
SHADOW_DIR=${SHADOW_DIR:=".shadow"}
SHADOW_ROOT="$PWD/$SHADOW_DIR"
SHADOW_MERGED="$SHADOW_ROOT/merged"
SHADOW_UPPER="$SHADOW_ROOT/upper"
SHADOW_WORK="$SHADOW_ROOT/workdir"
SHADOW_LOCK="$SHADOW_ROOT/.shadowlock"
SHADOW_TMP="$SHADOW_MERGED/tmp"
SHADOW_DOCKER="$SHADOW_MERGED/var/lib/docker"

ls $SHADOW_ROOT > /dev/null 2> /dev/null
SHADOW_EXISTS=$?

cEcho () {
	echo -e "${CYAN}[SHADOW]${NC} $*"
}

# contains method from:
# https://stackoverflow.com/questions/8063228/how-do-i-check-if-a-variable-exists-in-a-list-in-bash
extractVolume () {
	for DIR in "$@"; do
		# Ignore dirs in ignore list
		[[ $IGNORE_LIST =~ (^|[[:space:]])$DIR($|[[:space:]]) ]] \
		&& continue \
		|| echo -n "-v $SHADOW_MERGED/$DIR:/$DIR "
	done
}

clearDirs () {
	for DIR in "$@"; do
		SHADOWDIR=$SHADOW_MERGED$DIR
		rm -rf $SHADOWDIR
		mkdir -p $SHADOWDIR
		cEcho "Cleared shadow dir $DIR"
	done
}

prepareEnv () {
	if [ "$SHADOW_EXISTS" != "0" ]; then
		cEcho "Preparing temp directories at $SHADOW_ROOT ..."
		mkdir -p $SHADOW_MERGED $SHADOW_UPPER $SHADOW_WORK
		cEcho "Done"
	fi

	cEcho "Mounting shadow directories"
	mount -t overlay overlay -olowerdir=/,upperdir=$SHADOW_UPPER,workdir=$SHADOW_WORK $SHADOW_MERGED
	cEcho "Overlay mounted at $SHADOW_ROOT"
	mount -t tmpfs tmpfs -orw,nosuid,nodev $SHADOW_TMP
	cEcho "Tmp mounted"
	mount -t tmpfs tmpdocker -osize=2g $SHADOW_DOCKER
	cEcho "Docker mounted"
	cEcho "This mounts an empty fs to $SHADOW_DOCKER, otherwise will cause problems"

	if [ "SHADOW_EXISTS" != "0" ]; then
		clearDirs $CLEAR_LIST
	fi
}

detatched () {
	docker top `cat $SHADOW_LOCK` > /dev/null 2> /dev/null
	if [ "$?" == "0" ]; then
		cEcho "Container detatched, re-enter with \"sudo shadow\" in $PWD"
		cEcho "If you would like to keep the shadow env after another attach, add \"KEEP_SHADOW_ENV\" to the environment virables when attaching."
		exit
	fi

	cEcho "Container stoped"
	rm -f $SHADOW_LOCK
	umount -l $SHADOW_DOCKER
	cEcho "Docker unmounted"
	umount -l $SHADOW_TMP
	cEcho "Tmp unmounted"
	umount -l $SHADOW_MERGED
	cEcho "Overlay unmounted"

	if [ "$KEEP_SHADOW_ENV" == "" ]; then
		rm -rf $SHADOW_ROOT
		cEcho "Temp directory cleared, shadow exited"
	else
		cEcho "Shadow exited, shadow env saved"
		cEcho "If you would like to remove the shadow env after another run, do not add \"KEEP_SHADOW_ENV\" to the environment virables when starting."
	fi
}

attachDocker () {
	echo -e "${GREEN}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${NC}"
	docker attach `cat $SHADOW_LOCK`
	echo -e "\n${GREEN}<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<${NC}"
}

startDocker () {
	cEcho "Starting shadow environment..."
	cEcho "${YELLOW}Detatch with sequence Ctrl+P, Ctrl+Q${NC}"

	SHADOW_NAME=$SHADOW_PERFIX$RANDOM
	echo $SHADOW_NAME > $SHADOW_LOCK

	echo -e "${GREEN}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${NC}"
	docker run -it --rm --privileged \
		-w $PWD \
		--name $SHADOW_NAME \
		--hostname $SHADOW_NAME \
		`extractVolume $ROOT_LIST` \
		$SHADOW_IMG "$@"
	echo -e "\n${GREEN}<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<${NC}"
}

# Args
# Show version
if [ "$1" == "--version" ]; then
	echo "Shadow v0.1.1"
	exit
fi

# Show help
if [ "$1" == "--help" ]; then
	echo "Usage: shadow [CMD...]"
	echo
	echo "  --version  Print out version of Shadow"
	echo "  --clear    Clear shadow env in current directory"
	echo "  --help     Print out this message"
	echo
	echo "Read more at https://github.com/ClassicOldSong/shadow/blob/master/README.md"
	echo
	echo "Report bugs at https://github.com/ClassicOldSong/shadow/issues/new"
	exit
fi

# Clear current shadow env
if [ "$1" == "--clear" ]; then
	if [ "$SHADOW_EXISTS" != "0" ]; then
		cEcho "Shadow not exists, exit"
		exit
	fi

	if [  -f "$SHADOW_LOCK" ]; then
		cEcho "Stopping container..."
		docker kill `cat $SHADOW_LOCK` > /dev/null
	fi
	detatched
	exit
fi

# Check if this is a shadow already
echo $HOSTNAME | grep "^$SHADOW_PERFIX" > /dev/null
if [ "$?" == "0" ]; then
	cEcho "Already inside a shadow, exit"
	exit 1
fi

# Build shadow image if not exists
docker images | grep $SHADOW_IMG > /dev/null
if [ "$?" != "0" ]; then
	BUILD_DIR="/tmp/shadow_build"

	cEcho "Shadow image \"$SHADOW_IMG\" not found, trying to build..."

	mkdir -p $BUILD_DIR
	echo -e "FROM scratch\nCMD /bin/sh\n" > $BUILD_DIR/Dockerfile

	pushd $BUILD_DIR > /dev/null
	docker build -t $SHADOW_IMG . > /dev/null
	popd > /dev/null

	rm -rf $BUILD_DIR
	cEcho "Build complete"
fi

# Ask whether to attach if shadow is running
if [ -f "$SHADOW_LOCK" ]; then
	# Prompt script from:
	# https://stackoverflow.com/questions/226703/how-do-i-prompt-for-yes-no-cancel-input-in-a-linux-shell-script
	cEcho "Shadow in this dir is already running, attatch?"
	select yn in "Yes" "No"; do
	    case $yn in
	        Yes ) attachDocker; break;;
	        No ) exit;;
	    esac
	done
else
	prepareEnv
	startDocker "$@"
fi

# Run detatch after all kinds of attachment
detatched
