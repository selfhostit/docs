# Words you'll meet

You don't need to learn any of this first; each page links here when a word comes up.

## Terminal

A window where you type commands instead of clicking. You type a line, press Enter, and
the computer answers in text. It is like texting the computer instead of tapping around
in its menus.

Where you meet it: [open a terminal and connect](terminal.md).

## SSH

SSH lets you use the terminal of another machine from your own computer, over your
network. It is like a phone line straight into the machine's terminal: what you type runs
there, not on your computer.

Where you meet it: [open a terminal and connect](terminal.md).

## Linux

A free operating system, like Windows or macOS. Most servers, NAS boxes and every
Raspberry Pi run it. You don't need to know it well: the installer does the Linux parts.

Where you meet it: [Raspberry Pi and Linux](linux.md).

## Docker

Docker runs each app in a container: a sealed box with the app and everything it needs,
kept apart from the rest of the machine. It is like a shipping container: the same box
fits on any ship, so the app runs the same on a Pi, a laptop or a NAS.

Where you meet it: [what you need](README.md#what-you-need).

## Compose file

A short text file, `docker-compose.yml`, that tells Docker how to run an app: which
container, which port and which folder holds its data. It is like a recipe card that
Docker follows every time it starts the app.

Where you meet it: [other NAS and home servers](other-nas.md).

## NAS

A NAS (network attached storage) is a small box full of disks that keeps files for your
home network, such as one from Synology or QNAP. Many can also run apps. It is like a
shared cupboard that everyone at home can reach.

Where you meet it: [which machine?](machine.md#a-nas-you-already-have)

## Home server

Any computer at home that stays on to run apps for your household: a Raspberry Pi, a mini
PC, an old laptop or a NAS. It is like a fridge: it runs all the time in a corner and you
rarely think about it.

Where you meet it: [which machine?](machine.md)

## Raspberry Pi

A cheap, credit-card-sized computer that runs Linux and uses very little power. It is like
a phone's insides without the screen, made to sit in a corner and work all day.

Where you meet it: [Raspberry Pi and Linux](linux.md).

## VPS

A VPS (virtual private server) is a server you rent in a data centre, by the month. You
reach it over the internet and keep no hardware at home. It is like renting a storage unit
instead of using your own attic: handy, but your things are in someone else's building.

Where you meet it: [which machine?](machine.md#a-rented-server-a-vps)

## IP address

The number that tells devices on a network where to find each other, such as
`192.168.1.20`. It is like a street address for a device. At home, your router hands
these out.

Where you meet it: [when the machine's name doesn't answer](terminal.md#when-the-machines-name-doesnt-answer).

## localhost

A name that always means "this same machine". `http://localhost:8092` opens Flowy only in
a browser on the machine the apps run on. It is like saying "here" instead of an address:
it means something different on every device.

Where you meet it: [when something doesn't open](first-steps.md#when-something-doesnt-open).

## Port

A number that picks one program on a machine, such as `8092` for Flowy. If the IP address
is a building's address, the port is the flat number: same building, different door.

Where you meet it: [good to know](linux.md#good-to-know).

## HTTPS

The secure way a browser talks to a website, with addresses that start with `https://`.
What you send is encrypted on the way. It is like a sealed envelope instead of a postcard.
Phones only install web apps and show their notifications over HTTPS.

Where you meet it: [use them on your phones](phones.md).

## Domain

A name you own on the internet, such as `example.com`, that you can point at your own
machine. It is like a name on a letterbox: people find you by the name, not the number.
You don't need one: Tailscale gives the apps their addresses.

Where you meet it: [your own domain with a reverse proxy](phones.md#your-own-domain-with-a-reverse-proxy).

## Tailscale

Tailscale is a free service that links your own devices into one private network, called
your tailnet, wherever they are. Only devices signed in to your account (or that you
share with) can reach it. It is like a private hallway between your phone and your home
server.

Where you meet it: [Tailscale is a VPN, but not that kind](phones.md#tailscale-is-a-vpn-but-not-that-kind).

## VPN

A VPN (virtual private network) is a private, encrypted link over the internet. Some VPN
apps hide your browsing; Tailscale is the other kind and only links your own devices. It
is like a private tunnel under a public road.

Where you meet it: [Tailscale is a VPN, but not that kind](phones.md#tailscale-is-a-vpn-but-not-that-kind).

## Reverse proxy

A program that takes visits to your domain from the internet and passes each one to the
right app, adding HTTPS on the way. It is like a receptionist who answers the front door
and walks each visitor to the right room.

Where you meet it: [your own domain with a reverse proxy](phones.md#your-own-domain-with-a-reverse-proxy).

## Port forwarding

A router setting that lets the internet reach one port on a machine at home. It is like
giving a stranger a key to one door of your house. The apps don't need it with Tailscale,
and you should never forward the apps' own ports.

Where you meet it: [can I put the apps on the internet?](security.md#can-i-put-the-apps-on-the-internet)

## Admin page

Each app's control room, at its address with `/_/` at the end. The owner signs in there
to add people and see or change all the data. It is like the staff-only room behind a
shop counter.

Where you meet it: [add your household](first-steps.md#2-add-your-household).

## Web app

A web app is a website that you can install on your phone's home screen, where it opens
and sends notifications like an app from a store. It is like a shortcut that grew into a
full app. Installing one needs an `https://` address.

Where you meet it: [install the app on the phone](phones.md#install-the-app-on-the-phone).

## Setup code

A one-time code the installer shows for each new app. You type it when you make the first
account, so nobody else who finds a fresh install can claim it. It is like the code on a
new safe that you replace with your own.

Where you meet it: [make your account](first-steps.md#1-make-your-account).

## Owner and member

The first account in an app is its owner, who can add people and open the admin page.
Everyone the owner adds is a member, who just uses the app. It is like the person who
holds the lease and the people who live there with them.

Where you meet it: [add your household](first-steps.md#2-add-your-household).

## Backup

A copy of your data kept somewhere else, so you can get it back if a disk breaks or
something goes wrong. It is like a spare house key at a friend's place: useful only if it
isn't kept in the same house.

Where you meet it: [updates and backups](updates-and-backups.md#backups).
