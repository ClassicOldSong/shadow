# shadow
Run shadow clones of your system parallely with Docker

**!! USE AT YOUR OWN RISK !!**

## Requirements
- Linux kernel with OverlayFS support
- Docker
- Bash
- Git (Only for installation)
- Vim (Or other editor $EDITOR sets to)

## Installation/Upgrade
```
curl -L https://git.io/fAnmd | sh
```

## Usage
```
sudo shadow [ARGS...] [CMD...]
```

## Params
| Arguments                    | Description                               | Default            |
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

**NOTE:** `--clean`, `--start` and `--generate` should always be put at the end of the arguments, otherwise other arguments won't be parsed.

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
sudo shadow -w / /sbin/init
```

Run some dangerous commands withoud actually hurting your system
```
sudo shadow rm -rf / --no-preserve-root
```

Keep environment after container detatched
```
sudo shadow --keep [CMD...]
```

Generate a `Shadowfile`
```
shadow [ARGS...] -g
```

Start shadow from `Shadowfile`
```
sudo shadow [ARGS...] -s
```

## License
MIT
