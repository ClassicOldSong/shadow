#!/bin/sh
# Define colors
YELLOW="\033[0;93m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
RED="\033[0;31m"
NC="\033[0m"

ROOT_LIST=`ls /`
IGNORE_LIST="dev proc sys"
CLEAR_LIST="/mnt /run /boot /var/run"
SHADOW_ROOT="$PWD/.shadow"
SHADOW_MERGED="$SHADOW_ROOT/merged"
SHADOW_UPPER="$SHADOW_ROOT/upper"
SHADOW_WORK="$SHADOW_ROOT/workdir"
SHADOW_TMP="$SHADOW_MERGED/tmp"
SHADOW_DOCKER="$SHADOW_MERGED/var/lib/docker"

ls $SHADOW_ROOT > /dev/null 2> /dev/null
SHADOW_EXISTS=$?

cEcho () {
	echo -e "${CYAN}[SHADOW]${NC} $*"
}

IMG_NAME="shadow"
docker images | grep $IMG_NAME > /dev/null

if [ "$?" != "0" ]; then
	BUILD_DIR="/tmp/shadow_build"

	cEcho "Shadow image \"$IMG_NAME\" not found, trying to build..."

	mkdir -p $BUILD_DIR
	echo -e "FROM scratch\nCMD /bin/sh\n" > $BUILD_DIR/Dockerfile

	pushd $BUILD_DIR > /dev/null
	docker build -t $IMG_NAME . > /dev/null
	popd > /dev/null

	rm -rf $BUILD_DIR
	cEcho "Build complete"
fi

if [[ "$KEEP_SHADOW_ENV" == "" && "$SHADOW_EXISTS" == "0" ]]; then
  cEcho "Overlay $SHADOW_ROOT already exists! exiting..."
  exit 1
fi

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

cEcho "Starting shadow environment..."
cEcho "${YELLOW}DO NOT DETATCH THIS CONTAINER INSTANCE${NC}"
echo -e "${GREEN}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${NC}"
docker run --rm --privileged --hostname SHADOW-$HOSTNAME -it `extractVolume $ROOT_LIST` $IMG_NAME "$@"

echo -e "${GREEN}<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<${NC}"
cEcho "Container stoped"
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
	cEcho "To restore a saved shadow env, set \"KEEP_SHADOW_ENV\" again on next run."
fi
