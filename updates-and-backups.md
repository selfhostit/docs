# Updates and backups

## Updating

Run the installer again with the same apps:

```sh
curl -fsSL https://raw.githubusercontent.com/selfhostit/docs/main/install.sh | sh -s -- splitwiz flowy
```

It downloads the newest version of each app and restarts it. Settings (`.env`) and data
(`pb_data`) are kept, and the database is upgraded on start. To update one app by hand, in
its folder:

```sh
docker compose pull && docker compose up -d
```

### One command: `selfhostit update`

To update apps over SSH without the installer, install the `selfhostit` command once:

```sh
mkdir -p ~/bin
curl -fsSL https://raw.githubusercontent.com/selfhostit/docs/main/selfhostit -o ~/bin/selfhostit
chmod +x ~/bin/selfhostit
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.profile
. ~/.profile
```

On a Synology, first turn on Control Panel > User & Group > Advanced > **Enable user home
service**, so your home folder is on the volume and the command survives DSM updates.

Then:

```sh
selfhostit update splitwiz        # one app
selfhostit update splitwiz flowy  # several
selfhostit update all             # every app
selfhostit list                   # the apps it finds and the image each one runs
```

For each app it shows the image its compose file points at, pulls it, and says whether the
container was already up to date, recreated with a new image, or recreated because its
settings changed. It finds apps in the folder the installer uses (`/volume1/docker` on a
Synology, `~/selfhostit` elsewhere), and works for any folder there with a
`docker-compose.yml`. Keep them somewhere else? Add `export SELFHOSTIT_DIR=/path/to/apps` to
`~/.profile`. It uses `sudo` when your user can't reach Docker directly, and asks for the
password once. Run the `curl` line again to get a newer version of the command.

On a Synology without SSH: Container Manager > Image, select the app's image and choose
**Update**, then Project > the app > Action > **Build**.

## Backups

Each app keeps everything in the `pb_data` folder inside its own folder, and makes a nightly
backup into `pb_data/backups`, keeping the last 7. Those stay on the same disk, so also keep
a copy somewhere else. The data is private (Flowy holds health data), so encrypt any copy
that leaves the machine, and leave out the `tailscale` folder: it holds the machine's
Tailscale key, which lets whoever has it join your tailnet as that machine.

- **Synology:** add the apps' `pb_data` folders to a **Hyper Backup** task with
  **client-side encryption** turned on.
- **Other NAS:** include the apps' `pb_data` folders in its backup or snapshot schedule,
  encrypted if it goes off the NAS.
- **Linux or a Pi:** copy the `pb_data` folders to another disk or computer from time to
  time, for example with `rsync -a --exclude tailscale ~/selfhostit/ otherhost:backups/selfhostit/`,
  to an encrypted disk.

Selling or throwing away the machine or its SD card? Delete the apps' folders and wipe the
disk first; the data on it is not encrypted.

To restore, stop the app (`docker compose down`), put `pb_data` back, and start it again
(`docker compose up -d`).

## Removing an app

In its folder, `docker compose down`, then delete the folder. That deletes its data too.
