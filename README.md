# shadow
Run a shadow clone of your system parallely with Docker

**!! USE AT YOUR OWN RISK !!**

## Requirements
- Linux kernel with OverlayFS support
- Docker

## Installation
``` shell
git clone https://github.com/ClassicOldSong/shadow.git /tmp/shadow
sudo cp /tmp/shadow/shadow.sh /usr/bin/shadow
sudo chmod 755 /usr/bin/shadow
rm -rf /tmp/shadow
```

## Usage
```
sudo shadow [CMD]
```

## Flag(s)
`KEEP_SHADOW_ENV` Keep the shadow environment

## Example
This enters a shadow shell
```
sudo shadow
```

This enters a shadow bash shell
```
sudo shadow bash
```

This starts python in a shadow environment
```
sudo shadow python
```

This starts the shadow system from beginning (may cause tty conflict)
```
sudo shadow /sbin/init
```

Run some dangerous commands withoud hurting your actuall system
```
sudo shadow rm -rf / --no-preserve-root
```

## License
MIT
