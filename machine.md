# Which machine?

The apps need one machine that stays on, day and night, so your phones can reach them
whenever you open an app. It doesn't need to be fast: each app uses about 128 to 512 MB of
memory. Here are four good choices.

## A NAS you already have

**What it is:** a [NAS](words.md#nas), a box of disks for your home network, from Synology,
QNAP, UGREEN or others.

**Cost:** nothing extra.

**Good for:** households that already have one. It is on all the time anyway, and your
backups probably already cover it.

**Watch out for:** it needs a Docker app, such as Container Manager on a Synology. Many
budget and older models don't have one, and then the apps won't run on it. Follow
[Synology NAS](synology.md) or [other NAS and home servers](other-nas.md).

## A spare laptop or desktop

**What it is:** an old computer you no longer use, with [Linux](words.md#linux) installed
on it.

**Cost:** free.

**Good for:** trying the apps without buying anything.

**Watch out for:** it must stay on and plugged in. Set it never to sleep or hibernate, and
for a laptop, not to sleep when you close the lid. It uses more power than a Pi. Follow
[Raspberry Pi and Linux](linux.md).

## Buy a Raspberry Pi or a mini PC

**What it is:** a [Raspberry Pi](words.md#raspberry-pi) is a small, quiet computer the size
of a deck of cards. A mini PC is a small desktop computer, about the size of a sandwich.
Both use little power and can sit next to your router.

**Cost:** prices vary by country and have gone up with memory prices, so take these as
rough guides. A Raspberry Pi 5 kit with a case, power supply and a small SSD costs from
about 150 to 200 euros. A used mini PC costs from about 100 euros, and a new one from about
200.

**Good for:** most households without a NAS. It is a home server you set up once and then
forget.

**Watch out for:** on a Pi, use a USB SSD rather than a microSD card. Cards wear out with a
database writing to them all day. Follow [Raspberry Pi and Linux](linux.md).

## A rented server (a VPS)

**What it is:** a [VPS](words.md#vps), a server you rent in a data centre and reach over the
internet. There is no hardware at home.

**Cost:** from a few euros a month.

**Good for:** people with no space or machine at home, and apps with nothing very private
in them, such as should-we.

**Watch out for:** your data then lives in someone else's data centre, not in your home.
Keeping it at home is the main reason these apps exist. For health data, such as Flowy's
cycles or Troye's weight, think twice. [Tailscale](words.md#tailscale) works the same on a
VPS, so the apps still don't need to be on the internet. Follow
[Raspberry Pi and Linux](linux.md).

## Our suggestion

Use what you already have: a NAS with Docker or a spare computer. If you have neither, a
Raspberry Pi or a mini PC is the best fit for most households.
