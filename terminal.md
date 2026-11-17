# Open a terminal and connect

The installer runs in a [terminal](words.md#terminal): a window where you type a command
and press Enter. If the apps go on another machine, such as a Raspberry Pi or a NAS, you
use [SSH](words.md#ssh) from your own computer to type in that machine's terminal. This page
shows how, step by step.

## Open a terminal

**Windows 10 or 11:** open the Start menu, type `Terminal` (or `PowerShell` on older
Windows 10) and open it.

**Mac:** open **Terminal** from Applications > Utilities, or press Cmd+Space and type
`Terminal`.

**Linux:** open **Terminal** from your apps menu. On many desktops, Ctrl+Alt+T opens it too.

**Chromebook:** open Settings, search for `Linux` and turn on the **Linux development
environment**. Then open the **Terminal** app.

**Working on the machine itself,** with a keyboard and screen plugged into it: open its
own terminal and skip the next step. Everything you type runs right there.

## Connect to the machine

In the terminal, type `ssh`, your username on that machine, `@`, and the machine's name,
then press Enter. For a Raspberry Pi set up as in [the Pi guide](linux.md), that is:

```sh
ssh you@homeserver.local
```

Replace `you` with the username you chose, and `homeserver` with the machine's name.

- **The first time,** it asks "Are you sure you want to continue connecting
  (yes/no/[fingerprint])?". Type `yes` and press Enter. This only happens once per machine.
- **Then it asks for the password.** Nothing shows while you type it, not even dots. That's
  normal: type it and press Enter.
- **You are in** when the line changes to something like `you@homeserver:~ $`. What you type
  now runs on that machine.

## Paste a command

Copying the install line is easier than typing it. To paste it into the terminal:

- **Windows, Linux and Chromebook:** Ctrl+Shift+V, or right-click in the window.
- **Mac:** Cmd+V.

Then press Enter to run it.

## When the machine's name doesn't answer

If `ssh` says "Could not resolve hostname" or nothing happens, your network may not know
the name. Use the machine's [IP address](words.md#ip-address) instead:

1. Open your router's page in a browser. It is often at `http://192.168.1.1` or
   `http://192.168.0.1`, and the address and password are usually on a sticker on the
   router. Many routers also have a phone app.
2. Find its list of connected devices, and look for your machine's name.
3. Connect with the number it shows, for example:

   ```sh
   ssh you@192.168.1.20
   ```

On a Synology, the **Synology Assistant** app (from Synology's download page) or
`find.synology.com` also shows the NAS's address.

## Leave

Type `exit` and press Enter. The apps keep running on the machine after you leave.
