#!/bin/bash
# Define colors
YELLOW="\033[0;93m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
RED="\033[0;31m"
NC="\033[0m"

CMD_NAME=$0
ROOT_LIST=`ls /`
SHADOW_VERSION="v0.2.2"

QUIET=${QUIET:=""}
KEEP_SHADOW_ENV=${KEEP_SHADOW_ENV:=""}
START_USER=${START_USER:="0"}
WORK_DIR=${WORK_DIR:=$PWD}
IGNORE_LIST=${IGNORE_LIST:="dev proc sys"}
CLEAR_LIST=${CLEAR_LIST:="/mnt /run /var/run"}
SHADOW_FILE=${SHADOW_FILE:="Shadowfile"}
SHADOW_IMG=${SHADOW_IMG:="shadow"}
SHADOW_PERFIX=${SHADOW_PERFIX:="SHADOW-"}
SHADOW_DIR=${SHADOW_DIR:=".shadow"}
SHADOW_ROOT=""
SHADOW_MERGED=""
SHADOW_UPPER=""
SHADOW_WORK=""
SHADOW_LOCK=""
SHADOW_TMP=""
SHADOW_DOCKER=""
SHADOW_EXISTS=""

eEcho () {
	if [ "$QUIET" == "" ]; then
		echo -e "$@"
	fi
}

cEcho () {
	eEcho "${CYAN}[SHADOW]${NC} $*"
}

refreshDirs () {
	SHADOW_ROOT="$PWD/$SHADOW_DIR"
	SHADOW_MERGED="$SHADOW_ROOT/merged"
	SHADOW_UPPER="$SHADOW_ROOT/upper"
	SHADOW_WORK="$SHADOW_ROOT/workdir"
	SHADOW_LOCK="$SHADOW_ROOT/.shadowlock"
	SHADOW_TMP="$SHADOW_MERGED/tmp"
	SHADOW_DOCKER="$SHADOW_MERGED/var/lib/docker"

	ls $SHADOW_ROOT > /dev/null 2> /dev/null
	SHADOW_EXISTS=$?
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

extractGroups () {
	for GROUP in `id $START_USER -G`; do
		echo -n "--group-add $GROUP "
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
	cEcho "This mounts an tmpfs to $SHADOW_DOCKER, otherwise docker inside shadow won't start"

	if [ "SHADOW_EXISTS" != "0" ]; then
		clearDirs $CLEAR_LIST
	fi
}

detatched () {
	if [ -f "$SHADOW_LOCK" ]; then
		docker top `cat $SHADOW_LOCK` > /dev/null 2> /dev/null
		if [ "$?" == "0" ]; then
			cEcho "Container detatched, re-enter with \"sudo shadow\" in $PWD"
			cEcho "If you would like to keep the shadow env after another attach, set KEEP_SHADOW_ENV to \"YES\" to the environment virables when attaching."
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
	fi

	if [ "$KEEP_SHADOW_ENV" == "" ]; then
		rm -rf $SHADOW_ROOT
		cEcho "Temp directory cleared, shadow exited"
	else
		cEcho "Shadow exited, shadow env saved"
		cEcho "If you would like to remove the shadow env after another run, unset \"KEEP_SHADOW_ENV\" when starting."
	fi
}

attachContainer () {
	eEcho "${GREEN}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${NC}"
	docker attach `cat $SHADOW_LOCK`
	eEcho "\n${GREEN}<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<${NC}"
}

startContainer () {
	cEcho "Starting shadow environment..."
	cEcho "${YELLOW}Detatch with sequence Ctrl+P, Ctrl+Q${NC}"

	SHADOW_NAME=$SHADOW_PERFIX$RANDOM
	echo $SHADOW_NAME > $SHADOW_LOCK

	eEcho "${GREEN}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${NC}"
	docker run -it --rm --privileged \
		-w $WORK_DIR \
		-u `id $START_USER -u`:`id $START_USER -g` \
		`extractGroups` \
		--name $SHADOW_NAME \
		--hostname $SHADOW_NAME \
		`extractVolume $ROOT_LIST` \
		$SHADOW_IMG "$@"
	eEcho "\n${GREEN}<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<${NC}"
}

runContainer () {
	# Ask whether to attach if shadow is running
	if [ -f "$SHADOW_LOCK" ]; then
		# Prompt script from:
		# https://stackoverflow.com/questions/226703/how-do-i-prompt-for-yes-no-cancel-input-in-a-linux-shell-script
		cEcho "Shadow in this dir is already running, attatch?"
		select yn in "Yes" "No"; do
			case $yn in
				Yes ) attachContainer; break;;
				No ) exit;;
			esac
		done
	else
		prepareEnv
		startContainer "$@"
	fi

	# Run detatched after all kinds of attachment
	detatched
}

# Args
# Show version
showVersion () {
	echo "Shadow $SHADOW_VERSION"
	exit
}

# Show help
showHelp () {
	echo "Usage: shadow [ARGS...] [CMD...]

| Params                       | Description                               | Default            |
| ---------------------------- | ----------------------------------------- | ------------------ |
| -h, --help                   | Show help message                         | N/A                |
| -v, --version                | Show version of Shadow                    | N/A                |
| -C, --clean                  | Clear shadow env in current directory     | N/A                |
| -s, --start                  | Start shadow env from Shadowfile          | N/A                |
| -g, --generate               | Generate a Shadowfile                     | N/A                |
| -q, --quiet, QUIET           | Set to disable all shadow logs            | (not set)          |
| -k, --keep, KEEP_SHADOW_ENV  | Set to keep the shadow environment        | (not set)          |
| -u, --user, START_USER       | Start as given username or uid            | 0 (root)           |
| -w, --work-dir, WORK_DIR     | Working directory                         | (pwd)              |
| -i, --ignore, IGNORE_LIST    | Paths not to be mounted into a container  | dev proc sys       |
| -c, --clear, CLEAR_LIST      | Paths to clear before container starts    | /mnt /run /var/run |
| -f, --file, SHADOW_FILE      | Filename of the shadowfile                | Shadowfile         |
| -I, --img, SHADOW_IMG        | Name of the image to be used as base      | shadow             |
| -p, --perfix, SHADOW_PERFIX  | Perfix of the shadow container            | SHADOW-            |
| -d, --shadow-dir, SHADOW_DIR | Directory where all shadow env file saves | .shadow            |

Read more at https://github.com/ClassicOldSong/shadow/blob/master/README.md

Report bugs at https://github.com/ClassicOldSong/shadow/issues/new"

	exit
}

# Clean current shadow env
cleanShadow () {
	# Refresh shadow dirs before cleaning
	refreshDirs
	# Set KEEP_SHADOW_ENV empty
	KEEP_SHADOW_ENV=""

	if [ "$SHADOW_EXISTS" != "0" ]; then
		cEcho "Shadow not exists, exit"
		exit
	fi

	if [  -f "$SHADOW_LOCK" ]; then
		cEcho "Stopping container..."
		docker kill `cat $SHADOW_LOCK` > /dev/null 2> /dev/null
	fi
	detatched
	exit
}

# Start with Shadowfile
startShadow () {
	if [ ! -f "$SHADOW_FILE" ]; then
		cEcho "$SHADOW_FILE not found, exit"
		exit 1
	fi

	cEcho "Starting shadow with $SHADOW_FILE..."
	. $SHADOW_FILE
	# Refresh shadow dirs after shadowfile loaded
	refreshDirs
	runContainer "${CMD[@]}"
	exit
}

generateShadowfile () {
	if [ -f "$SHADOW_FILE" ]; then
		echo "$SHADOW_FILE exists, remove it before generating a new one."
		exit 1
	fi

	echo "#!/bin/bash

QUIET=\"$QUIET\"
KEEP_SHADOW_ENV=\"$KEEP_SHADOW_ENV\"
START_USER=\"$START_USER\"
WORK_DIR=\"$WORK_DIR\"
IGNORE_LIST=\"$IGNORE_LIST\"
CLEAR_LIST=\"$CLEAR_LIST\"
SHADOW_IMG=\"$SHADOW_IMG\"
SHADOW_PERFIX=\"$SHADOW_PERFIX\"
SHADOW_DIR=\"$SHADOW_DIR\"
CMD=(\"bash\" \"-c\" \"echo \\\"Change the CMD section of the $SHADOW_FILE to your custom command\\\"\")
" > $SHADOW_FILE

	# Start the editor which user specified
	${EDITOR:-vim} $SHADOW_FILE
	exit
}

# Parse arguments:
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
	-h|--help)
	showHelp
	;;
	-v|--version)
	showVersion
	;;
	-C|--clean)
	cleanShadow
	;;
	-s|--start)
	startShadow
	;;
	-g|--generate)
	generateShadowfile
	;;
	-q|--quiet)
	QUIET="YES"
	shift
	;;
	-k|--keep)
	KEEP_SHADOW_ENV="YES"
	shift
	;;
	-u|--user)
	START_USER=$2
	shift
	shift
	;;
	-w|--work-dir)
	WORK_DIR=$2
	shift
	shift
	;;
	-i|--ignore)
	IGNORE_LIST=$2
	shift
	shift
	;;
	-c|--clear)
	CLEAR_LIST=$2
	shift
	shift
	;;
	-f|--file)
	SHADOW_FILE=$2
	shift
	shift
	;;
	-I|--img)
	SHADOW_IMG=$2
	shift
	shift
	;;
	-p|--perfix)
	SHADOW_PERFIX=$2
	shift
	shift
	;;
	-d|--shadow-dir)
	SHADOW_DIR=$2
	shift
	shift
	;;
	*)
	if [[ $key == -* ]]; then
		echo "Unknown parameter \"$key\". Show help with \"$CMD_NAME --help\""
		exit 1
	else
		break
	fi
	;;
esac
done

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

# Refresh shadow dirs
refreshDirs
# Start container
runContainer "$@"
