# shadow
Run shadow clones of your system parallely with Docker

**!! USE AT YOUR OWN RISK !!**

## Requirements
- Linux kernel with OverlayFS support
- Docker
- Bash
- Git (Only for installation)
- Vim (Or other editor $EDITOR sets to)
- Tar (For saving and loading shadow env)

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
| -S, --save                   | Save current shadow env to a tarball      | N/A                |
| -L, --load                   | Load shadow env from a tarball            | N/A                |
| -U, --upgrade                | Upgrade shadow to it's latest version     | N/A                |
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

Run some dangerous commands without actually hurting your system
```
sudo shadow rm -rf / --no-preserve-root
```

Keep environment after container detached
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

Start shadow from `myShadowfile`
```
sudo shadow [ARGS...] -f myShadowfile -s
```

Save a shadow env
```
shadow -S shadowenv.tar
```

Save a shadow env with gzip
```
shadow -S | gzip -9 > shadowenv.tar.gz
```

Load a shadow env from a tarball to the current directory
```
shadow -L shadowenv.tar.gz
```

Load a shadow env from a tarball to another directory
```
shadow -L shadowenv.tar.gz /another/directory
```

## License
MIT
