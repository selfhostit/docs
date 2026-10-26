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

On a Synology without SSH: Container Manager > Image, select the app's image and choose
**Update**, then Project > the app > Action > **Build**.

## Backups

Each app keeps everything in the `pb_data` folder inside its own folder, and makes a nightly
backup into `pb_data/backups`, keeping the last 7. Those stay on the same disk, so also keep
a copy somewhere else:

- **Synology:** add the `docker` folder to a **Hyper Backup** task.
- **Other NAS:** include the apps' folders in its backup or snapshot schedule.
- **Linux or a Pi:** copy the folder to another disk or computer from time to time, for
  example with `rsync -a ~/selfhostit/ otherhost:backups/selfhostit/`.

To restore, stop the app (`docker compose down`), put `pb_data` back, and start it again
(`docker compose up -d`).

## Removing an app

In its folder, `docker compose down`, then delete the folder. That deletes its data too.
