# Docker container for MakeMKV

This is a Docker container for [MakeMKV](http://www.makemkv.com/). Based on this [container](https://github.com/jlesage/docker-makemkv).

The GUI of the application is accessed through a modern web browser (no installation or configuration needed on the client side) or via [Xpra](https://xpra.org) over SSH.

A fully automated mode is also available: insert a DVD or Blu-ray disc into an optical drive and let MakeMKV rips it without any user interaction.

---

[![MakeMKV logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/makemkv-icon.png&w=200)](http://www.makemkv.com/)[![MakeMKV](https://dummyimage.com/400x110/ffffff/575757&text=MakeMKV)](http://www.makemkv.com/)

MakeMKV is your one-click solution to convert video that you own into free and
patents-unencumbered format that can be played everywhere. MakeMKV is a format
converter, otherwise called "transcoder". It converts the video clips from
proprietary (and usually encrypted) disc into a set of MKV files, preserving
most information but not changing it in any way. The MKV format can store
multiple video/audio tracks with all meta-information and preserve chapters.

---

## Table of Content

   * [Docker container for MakeMKV](#docker-container-for-makemkv)
      * [Table of Content](#table-of-content)
      * [Quick Start](#quick-start)
      * [Usage](#usage)
         * [Environment Variables](#environment-variables)
         * [Data Volumes](#data-volumes)
         * [Ports](#ports)
         * [Changing Parameters of a Running Container](#changing-parameters-of-a-running-container)
      * [Docker Compose File](#docker-compose-file)
      * [Docker Image Update](#docker-image-update)
         * [Synology](#synology)
         * [unRAID](#unraid)
      * [User/Group IDs](#usergroup-ids)
      * [Accessing the GUI](#accessing-the-gui)
      * [Reverse Proxy](#reverse-proxy)
         * [Apache](#apache)
         * [Nginx](#nginx)
      * [Shell Access](#shell-access)
      * [Access to Optical Drive(s)](#access-to-optical-drives)
      * [Automatic Disc Ripper](#automatic-disc-ripper)
      * [Troubleshooting](#troubleshooting)
         * [Expired Beta Key](#expired-beta-key)
         
## Quick Start

**NOTE**: The Docker command provided in this quick start is given as an example
and parameters should be adjusted to your need.

Launch the MakeMKV docker container with the following command:
```
docker run -d \
    --name=makemkv \
    -p 2200:22 \
    -p 10000:10000
    -v /docker/appdata/makemkv:/config:rw \
    -v $HOME:/storage:ro \
    -v $HOME/MakeMKV/output:/output:rw \
    --device /dev/sr0 \
    --device /dev/sg2 \
    .
```

Where:
  - `/docker/appdata/makemkv`: This is where the application stores its configuration, log and any files needing persistency.
  - `$HOME`: This location contains files from your host that need to be accessible by the application.
  - `$HOME/MakeMKV/output`: This is where extracted videos are written.
  - `/dev/sr0`: This is the first Linux device file representing the optical drive.
  - `/dev/sg2`: This is the second Linux device file representing the optical drive.

Browse to `http://your-host-ip:10000` to access the MakeMKV GUI.
Files from the host appear under the `/storage` folder in the container.

## Usage

```
docker run [-d] \
    --name=makemkv \
    [-e <VARIABLE_NAME>=<VALUE>]... \
    [-v <HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]]... \
    [-p <HOST_PORT>:<CONTAINER_PORT>]... \
    .
```
| Parameter | Description |
|-----------|-------------|
| -d        | Run the container in the background.  If not set, the container runs in the foreground. |
| -e        | Pass an environment variable to the container.  See the [Environment Variables](#environment-variables) section for more details. |
| -v        | Set a volume mapping (allows to share a folder/file between the host and the container).  See the [Data Volumes](#data-volumes) section for more details. |
| -p        | Set a network port mapping (exposes an internal container port to the host).  See the [Ports](#ports) section for more details. |

### Environment Variables

To customize some properties of the container, the following environment
variables can be passed via the `-e` parameter (one for each variable).  Value
of this parameter has the format `<VARIABLE_NAME>=<VALUE>`.

| Variable       | Description                                  | Default |
|----------------|----------------------------------------------|---------|
|`UID`| ID of the user the application runs as.  See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`GID`| ID of the group the application runs as.  See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`SUP_GROUP_IDS`| Comma-separated list of supplementary group IDs of the application. | (unset) |
|`UMASK`| Mask that controls how file permissions are set for newly created files. The value of the mask is in octal notation.  By default, this variable is not set and the default umask of `022` is used, meaning that newly created files are readable by everyone, but only writable by the owner. See the following online umask calculator: http://wintelguy.com/umask-calc.pl | (unset) |
|`TZ`| [TimeZone] of the container.  Timezone can also be set by mapping `/etc/localtime` between the host and the container. | `Etc/UTC` |
|`MAKEMKV_KEY`| MakeMKV registration key to use.  The key is written to the configuration file during container startup.  When set to `BETA`, the latest beta key is automatically used.  When set to `UNSET`, no key is automatically written to the configuration file. | `BETA` |
|`AUTO_DISC_RIPPER`| When set to `1`, the automatic disc ripper is enabled. | `0` |
|`AUTO_DISC_RIPPER_EJECT`| When set to `1`, disc is ejected from the drive when ripping is terminated. | `0` |
|`AUTO_DISC_RIPPER_PARALLEL_RIP`| When set to `1`, discs from all available optical drives are ripped in parallel.  Else, each disc from optical drives is ripped one at time. | `0` |
|`AUTO_DISC_RIPPER_INTERVAL`| Interval, in seconds, the automatic disc ripper checks for the presence of a DVD/Blu-ray discs. | `5` |
|`AUTO_DISC_RIPPER_MIN_TITLE_LENGTH`| Titles with a length less than this value are ignored.  Length is in seconds.  By default, no value is set, meaning that value from MakeMKV's configuration file is taken. | (unset) |
|`AUTO_DISC_RIPPER_BD_MODE`| Rip mode of Blu-ray discs.  `mkv` is the default mode, where a set of MKV files are produced.  When set to `backup`, a copy of the (decrypted) file system is created instead. **NOTE**: This applies to Blu-ray discs only.  For DVD discs, MKV files are always produced. | `mkv` |
|`AUTO_DISC_RIPPER_FORCE_UNIQUE_OUTPUT_DIR`| When set to `0`, files are written to `/output/DISC_LABEL/`, where `DISC_LABEL` is the label/name of the disc.  If this directory exists, then files are written to `/output/DISC_LABEL-XXXXXX`, where `XXXXXX` are random readable characters.  When set to `1`, the `/output/DISC_LABEL-XXXXXX` pattern is always used. | `0` |
|`AUTO_DISC_RIPPER_NO_GUI_PROGRESS`| When set to `1`, progress of discs ripped by the automatic disc ripper is not shown in the MakeMKV GUI. | `0` |

### Data Volumes

The following table describes data volumes used by the container.  The mappings
are set via the `-v` parameter.  Each mapping is specified with the following
format: `<HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]`.

| Container path  | Permissions | Description |
|-----------------|-------------|-------------|
|`/config`| rw | This is where the application stores its configuration, log and any files needing persistency. |
|`/storage`| ro | This location contains files from your host that need to be accessible by the application. |
|`/output`| rw | This is where extracted videos are written. |

### Ports

Here is the list of ports used by the container.  They can be mapped to the host
via the `-p` parameter (one per port mapping).  Each mapping is defined in the
following format: `<HOST_PORT>:<CONTAINER_PORT>`.  The port number inside the
container cannot be changed, but you are free to use any port on the host side.

| Port | Mapping to host | Description |
|------|-----------------|-------------|
| 10000 | Mandatory | Port used to access the application's GUI via the web interface. |
| 22 | Optional | Port used to access the application's GUI via the SSH using Xpra. |

### Changing Parameters of a Running Container

As can be seen, environment variables, volume and port mappings are all specified
while creating the container.

The following steps describe the method used to add, remove or update
parameter(s) of an existing container.  The general idea is to destroy and
re-create the container:

  1. Stop the container (if it is running):
```
docker stop makemkv
```
  2. Remove the container:
```
docker rm makemkv
```
  3. Create/start the container using the `docker run` command, by adjusting
     parameters as needed.

**NOTE**: Since all application's data is saved under the `/config` container
folder, destroying and re-creating a container is not a problem: nothing is lost
and the application comes back with the same state (as long as the mapping of
the `/config` folder remains the same).

## Docker Compose File

Here is an example of a `docker-compose.yml` file that can be used with
[Docker Compose](https://docs.docker.com/compose/overview/).

Make sure to adjust according to your needs.  Note that only mandatory network
ports are part of the example.

```yaml
version: "3"

services:
  makemkv:
    build: .
    container_name: makemkv
    ports:
      - "2200:22"
      - "10000:10000"
    volumes:
      - ~/.ssh/authorized_keys:/authorized_keys:ro
      - config:/config
      - /data/makemkv/storage:/storage
      - /data/makemkv/output:/output
    environment:
      - AUTO_DISC_RIPPER=1
      - AUTO_DISC_RIPPER_EJECT=1
      - AUTO_DISC_RIPPER_MIN_TITLE_LENGTH=120
    env_file:
      - .env
    devices:
      - /dev/sr1
      - /dev/sg10

volumes:
  config:"
```

## Docker Image Update

If the system on which the container runs doesn't provide a way to easily update
the Docker image, the following steps can be followed:

  1. Fetch the latest image:
```
docker pull hydrohs/makemkv
```
  2. Stop the container:
```
docker stop makemkv
```
  3. Remove the container:
```
docker rm makemkv
```
  4. Start the container using the `docker run` command.

### Synology

For owners of a Synology NAS, the following steps can be used to update a
container image.

  1.  Open the *Docker* application.
  2.  Click on *Registry* in the left pane.
  3.  In the search bar, type the name of the container (`jlesage/makemkv`).
  4.  Select the image, click *Download* and then choose the `latest` tag.
  5.  Wait for the download to complete.  A  notification will appear once done.
  6.  Click on *Container* in the left pane.
  7.  Select your MakeMKV container.
  8.  Stop it by clicking *Action*->*Stop*.
  9.  Clear the container by clicking *Action*->*Clear*.  This removes the
      container while keeping its configuration.
  10. Start the container again by clicking *Action*->*Start*. **NOTE**:  The
      container may temporarily disappear from the list while it is re-created.

### unRAID

For unRAID, a container image can be updated by following these steps:

  1. Select the *Docker* tab.
  2. Click the *Check for Updates* button at the bottom of the page.
  3. Click the *update ready* link of the container to be updated.

## User/Group IDs

When using data volumes (`-v` flags), permissions issues can occur between the
host and the container.  For example, the user within the container may not
exists on the host.  This could prevent the host from properly accessing files
and folders on the shared volume.

To avoid any problem, you can specify the user the application should run as.

This is done by passing the user ID and group ID to the container via the
`UID` and `GID` environment variables.

To find the right IDs to use, issue the following command on the host, with the
user owning the data volume on the host:

    id <username>

Which gives an output like this one:
```
uid=1000(myuser) gid=1000(myuser) groups=1000(myuser),4(adm),24(cdrom),27(sudo),46(plugdev),113(lpadmin)
```

The value of `uid` (user ID) and `gid` (group ID) are the ones that you should
be given the container.

## Accessing the GUI

Assuming that container's ports are mapped to the same host's ports, the
graphical interface of the application can be accessed via:

  * A web browser:
```
http://<HOST IP ADDR>:10000
```

  * Xpra client:
```
xpra attach ssh://<HOST IP ADDR>:2200
```

## Reverse Proxy

Xpra provides example configurations for both Apache and Nginx

### Apache

```
<Location "/xpra">

  RewriteEngine on
  RewriteCond %{HTTP:UPGRADE} ^WebSocket$ [NC]
  RewriteCond %{HTTP:CONNECTION} ^Upgrade$ [NC]
  RewriteRule .* ws://localhost:14500/%{REQUEST_URI} [P]

  ProxyPass ws://localhost:14500
  ProxyPassReverse ws://localhost:14500

  ProxyPass http://localhost:14500
  ProxyPassReverse http://localhost:14500
</Location>
```

### Nginx

```
server {
  listen        443 ssl http2;
  listen        [::]:443 ssl http2;
  server_name   www.example.com;

  location ^~ /xpra/ {
    proxy_pass       http://127.0.0.1:10000/;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
  }
```

## Shell Access

To get shell access to the running container, execute the following command:

```
docker exec -ti CONTAINER sh
```

Where `CONTAINER` is the ID or the name of the container used during its
creation (e.g. `crashplan-pro`).

## Access to Optical Drive(s)

By default, a Docker container doesn't have access to host's devices.  However,
access to one or more devices can be granted with the `--device DEV` parameter.

In the Linux world, an optical drive is represented by two different device
files: `/dev/srX` and `/dev/sgY`, where `X` and `Y` are numbers.

For best performance, it is recommended to expose both these devices to the
container.  For example, for an optical drive represented by `/dev/sr0` and
`/dev/sg1`, the following parameters would be added to the `docker run`
command:
```
--device /dev/sr0 --device /dev/sg1
```

**NOTE**: For an optical drive to be detected by MakeMKV, it is mandatory to
expose `/dev/sgY` to the container.  `/dev/srX` is optional, but performance
could be affected.

The easiest way to determine the right Linux devices to expose is to run the
container (without `--device` parameter) and look at its log: during the
startup, messages similar to these ones are outputed:
```
[cont-init.d] 95-check-optical-drive.sh: executing...
[cont-init.d] 95-check-optical-drive.sh: looking for usable optical drives...
[cont-init.d] 95-check-optical-drive.sh: found optical drive [/dev/sr0, /dev/sg3], but it is not usable because:
[cont-init.d] 95-check-optical-drive.sh:   --> the host device /dev/sr0 is not exposed to the container.
[cont-init.d] 95-check-optical-drive.sh:   --> the host device /dev/sg3 is not exposed to the container.
[cont-init.d] 95-check-optical-drive.sh: no usable optical drive found.
[cont-init.d] 95-check-optical-drive.sh: exited 0.
```

In this case, it's clearly indicated that `/dev/sr0` and `/dev/sg3` needs to be
exposed to the container.

## Automatic Disc Ripper

This container has an automatic disc ripper built-in.  When enabled, any DVD or
Blu-ray video disc inserted into an optical drive is automatically ripped.  In
other words, MakeMKV decrypts and extracts all titles (such as the main movie,
bonus features, etc) from the disc to MKV files.

To enable the automatic disc ripper, set the environment variable
`AUTO_DISC_RIPPER` to `1`.

To eject the disc from the drive when ripping is terminated, set the environment
variable `AUTO_DISC_RIPPER_EJECT` to `1`.

If multiple drives are available, discs can be ripped simultaneously by
setting the environment variable `AUTO_DISC_RIPPER_PARALLEL_RIP` to `1`.

See the [Environment Variables](#environment-variables) section for details
about setting environment variables.

**NOTE**: All titles, audio tracks, chapters, subtitles, etc are
        extracted/preserved.

**NOTE**: Titles and audio tracks are kept in their original format.  They are
        not transcoded or converted to other formats or into smaller sizes.

**NOTE**: Ripped Blu-ray discs can take a large amount of disc space (~40GB).

**NOTE**: MKV Files are written to the `/output` folder of the container.

**NOTE**: The automatic disc ripper processes all available optical drives.

## Troubleshooting

### Expired Beta Key

If the beta key is expired, just restart the container to automatically fetch
and install the latest one.

**NOTE**: Once beta key expires, it can take few days before a new key is made
available by the author of MakeMKV.  During this time, the application is not
functional.

**NOTE**: For this solution to work, the `MAKEMKV_KEY` environment variable must
be set to `BETA`.  See the [Environment Variables](#environment-variables)
section for more details.

[TimeZone]: http://en.wikipedia.org/wiki/List_of_tz_database_time_zones
