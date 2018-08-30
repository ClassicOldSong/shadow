# shadow
Run shadow clones of your system parallely with Docker

**!! USE AT YOUR OWN RISK !!**

## Requirements
- Linux kernel with OverlayFS support
- Docker

## Installation/Upgrade
```
curl -L https://git.io/fAnmd | sh
```

## Usage
```
sudo shadow [CMD...]
```

## Flag(s)
| Flag            | Description                               | Default            |
| --------------- | ----------------------------------------- | ------------------ |
| KEEP_SHADOW_ENV | Set to keep the shadow environment        | (not set)          |
| IGNORE_LIST     | Paths not to be mounted into a container  | dev proc sys       |
| CLEAR_LIST      | Paths to clear before container starts    | /mnt /run /var/run |
| SHADOW_IMG      | Name of the image to be used as base      | shadow             |
| SHADOW_PERFIX   | Perfix of the shadow container            | SHADOW-            |
| SHADOW_DIR      | Directory where all shadow env file saves | .shadow            |

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

Run some dangerous commands withoud actually hurting your system
```
sudo shadow rm -rf / --no-preserve-root
```

Keep environment after container detatched
```
sudo KEEP_SHADOW_ENV=1 shadow [CMD...]
```

## License
MIT
