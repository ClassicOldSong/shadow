#!/bin/sh

echo "Cloning repo..."
git clone --depth 1 https://github.com/ClassicOldSong/shadow.git /tmp/shadow > /dev/null
echo "Installing..."
sudo cp /tmp/shadow/shadow.sh /usr/bin/shadow
sudo chmod 755 /usr/bin/shadow
echo "Removing tmp files..."
rm -rf /tmp/shadow
echo "Done!"
