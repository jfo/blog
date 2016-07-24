---
title: wtf mbr gpt uefi
layout: post
---
Ok. so you get a liveboot medium.

I didn't realize that this was special, I kind of thought it was a whole
environment. in many ways it is, but really it's just what you need to have a
(pleasant?) experience installing stuff onto a physical drive.

Boot into UEFI mode on your live boot medium by hitting f12 or whatever magic
combination of buttons. If you just let it go then it will boot in bios
compatible mode, and it will cause you great pain and suffering when you can't
actually boot into.

now, let's just say you have an extremely simple setup. You have a motherboard,
and a single 120gb ssd. Let's also say that you have a wifi card instead of a
wired connection, because you most likely do, and I do, and it's only one extra command.

So you've booted into you live medium and you have a root prompt.
Congratulations! If you have a wired connection, you should already be
connected to the interwebs. You can test this by `ping`ing or `curl`ing your
favorite website. any old one will do. I like curling the root domain of this
website because it returns one stupid line currently.

```
curl jfo.click
<h1>hello world</h1>
```

If you do NOT have a wired connection, you'll have to connect via wifi. You can
do this from the live boot by using a little utility called `wifi-menu`.

Type

```
$ wifi-menu
```

at the prompt and after a few seconds you should be presented with a list of
detected networks. Choose one, choose a name for the profile (it doesn't really
matter right now what it is), and then enter your password. Wait a little bit
and now you should be connected to the internet.

```
curl jfo.click
<h1>hello world</h1>
```

... or whatever. You only need to be connected to download the packages, but
it's nice to get it out of the way.

Now pick a connected harddrive to install onto. run
[`lsblk`](http://man7.org/linux/man-pages/man8/lsblk.8.html) to see a list of
connected drives. If you only have the usb stick and the ssd drive connected,
it will probably look something like mine:

```
```

Here, `/dev/sda` is my solid state drive, and `/dev/sdb` is the flash media I'm
currently booted from.

You interface with these physical devices through their _device files_.

http://unix.stackexchange.com/questions/18239/understanding-dev-and-its-subdirs-and-files
http://unix.stackexchange.com/questions/19705/what-do-the-device-files-in-dev-actually-do

These drives show up in the `/dev` directory as variations of `sdX` where `X`
is a letter like `a` or `b` above. An important distinction here is that the
_physical drives themselves_ are represented by `/dev/sdX`, and the _partitions
on those drives_ (more on that in a minute) are represented by `/dev/sdXn`
where `n` is a number.

> It doesn't have to be `sdX`, HDD drives show up as `/dev/hdX`. I think it
> depends on the connection (IDE vs SATA/SCSI?) and the drivers you use.

I'm going to be installing to `/dev/sda`. In `lsblk`, you might see partitions
like `/dev/sda1` or `/dev/sda2`, it doesn't matter because the very first thing
we're going to do is wipe the partition table on the target drive.

Wtf is a partition?
------------------

A partition is actually exactly what it sounds like. It is a chunk of memory
that is fenced off from the rest of the drive. We can define these partitions
using a variety of programs. [Gnu
Parted](https://www.google.com/search?q=gnu+parted&oq=gnu+parted&aqs=chrome..69i57j69i60j69i64.1624j0j7&sourceid=chrome&ie=UTF-8)
is a nicely obscure option that presents us with a command line interface and
very little to go on. Like many Gnu tools it is both extremely powerful and
incredibly intimidating. It's usually known as `parted`. You would think that
`gparted` stood for `gnu parted` but it actually stands for `Graphical Parted`,
and is a [Gnome]() frontend to the parted utility.

I've been using [`cfdisk`](https://en.wikipedia.org/wiki/Cfdisk), an
[ncurses](https://en.wikipedia.org/wiki/Ncurses) powered UI to
[fdisk](https://en.wikipedia.org/wiki/Fdisk) and it's been working for me.
There are probably others. You can probably write bytes directly to the device
file if you _really_ knew what you were doing, but I don't think that would be
necessary.

https://www.happyassassin.net/2014/01/25/uefi-boot-how-does-that-actually-work-then/

All of these tools modify the physical disk's partition table. A partition
table is also what it sounds like: A record of what partitions are where on the
disk. Here's where the whole UEFI/GPT vs BIOS/MBT thing starts to get a little
hairy. Let me recap that from the artical linked above.

- UEFI stands for **Unified Extensible Firmware Interface**
- BIOS stands for **Basic Input/Output System**

These are _competing but sometimes kind of compatible_ firmware paradigms. BIOS
is old, UEFI is new. BIOS is dead "simple" (theoretically...) and not very
flexible. UEFI is very "complex" (the
[specification](http://www.uefi.org/sites/default/files/resources/UEFI%20Spec%202_6.pdf)
is *3000 pages long*) but incredibly pliable.

Remember, this is the _firmware_ that is actually running on and _in_ your
motherboard. I suppose there might be a way to actually put a BIOS firmware on
a UEFI board or vice versa, but firmware is not easy to fiddle with, it is,
after all, the very definition of architecturally dependant code.

- GPT stands for **GUID Partition Table**
- MBR stands for **Master Boot Record**

**GPT is associated with UEFI**. The table contains information about the
partitions on the drive and what filesystems the firmware should expect to see
there. An easy way to bork things up is to write a file system type into the
GPT that is incongruent with the filesystem that is actually in the partition,
which I'll touch on further down below.  It's just another one of those golden
opportunities to drop a rock on your foot.

**MBR is associated with BIOS**. Basically, the first thing a BIOS system
always does is look at the same address near the beginning of the physical disk
(`0xffff`) and jump to the address that's there to continue executing the
bootup. there is also a magic number checksum that must be present. I don't
really know much more about this. Here is a blog post I found.

```
http://www.dewassoc.com/kbase/hard_drives/master_boot_record.htm
```

> OMFG. So many acronyms. I didn't even realize this until I wrote that above,
> but GPT is a _nested acronym_. `GUID` stands for **Globally Unique
> Identifier**. This is confusing enough, but it's compounded by the fact that
> GUID is a term associated with Microsoft, and everywhere else (read: Linix) you
> will see `UUID` instead. `UUID` stands for **Universally Unique Identifier**.
> I can only assume this is a terminological holdover from the EFI stuff that
> was developed at Microsoft and upon which UEFI was based.


So, this all seems kind of alright, but it can get really weird. UEFI systems
are required to have a BIOS compatible _mode_ and be able to boot a drive that
has a MBR. This is in fact how most installation media boot by default, because
it will boot on both types of firmwares. If you boot a live CD or usb stick in
its default mode and then try to install an OS on a UEFI machine, things will
be needlessly hard for you. This is a nice opportunity to drop something on
your other foot.

In my case, all this madness was compounded by the fact that my
[motherboard](http://www.newegg.com/Product/Product.aspx?Item=N82E16813128547)'s
firmware is trademarked as, get this, "UEFI DualBIOS<sup>TM</sup>". Now,
given all the information above, you might be able to tell that that is... fucking
meaningless! The firmware can't be BIOS _and_ UEFI at the same time, it can
only be UEFI which also has a BIOS mode. You might further assume that this is
what 'Dual' means. "Hey everyone!" the board is trying to say,
"I'm a **UEFI** system but don't forget I also support BIOS!" _Well wrong
again!_ It is, in fact, a [proprietary backup ROM
chip](http://www.gigabyte.com/microsite/55/tech_081226_dualbios.htm) built into
the motherboard itself that has an _extra copy_ of the "BIOS" firmware in case
the original one gets corrupted or something. That's all well and good, except
that you'll remember that since this is a UEFI system, it doesn't make any
sense to call it BIOS. "BIOS" here is used as a _generic term_ for the
firmware, regardless of the fact that it is _actually_ a UEFI firmware. This is
_further_ compounded by the fact that, since I knew none of this going in, I
was continuously booting my live usb in BIOS compatibility mode, which meant
that it was difficult to tell that I had a UEFI board at all, and all my
installations were just a little bit not set up quite right, and it was
incredibly hard to figure out why.

This giant clusterknot of acronyms was really, really hard to
untangle. Many how to's and forums posts either got the details wrong, or
didn't go into enough detail, or went into _way too much_ detail without enough
context. This is way beyond poweruser territory, and I'd wager even most Linux
users simply find a distro they like, figure out some way to get it to boot on
their machine, and then just don't touch it again for love nor money.


Anyway, the whole point of this is that, of all the myriad workable options for
getting a system, what I really want here is to boot with UEFI natively.

Let's format everything
----------------------

First, let's erase any existing partitions.
Then we will make two.

Then we'll make sure it's a GPT drive.

```
parted /dev/sda mklabel gpt
```

now make two partitions

/dev/sda1 a 200M partition with an EFI filesystem type.
/dev/sda2 a 10 G (or whatever) "linux filesystem"

remember, all that did was write the info into the GPT. We actually have to format the filesystems too.

```
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2
```

now we're ready to mount the drives.

We mount the root partition first, to `/mnt`

```
mount /dev/sda2 /mnt
```

now `cd` into /mnt and `ls`. You should see

```
lost+found
```

[Wtf is
that?](http://unix.stackexchange.com/questions/18154/what-is-the-purpose-of-the-lostfound-folder-in-linux-and-unix) 

anyway, you're going to want to mount the efi filesystem in a very special
place. so, create a new directory:

```
mkdir -p  /mnt/boot/efi
```

and then mount our other partition there.

```
mount /dev/sda1 /mnt/boot/efi
```

Now we're ready to run the pacstrap tool, which installs pacman packages to an
arbitrary root.

```
pacstrap /mnt base base-devel efibootmgr wpa_supplicant grub-efi-x86_64
```

This will take a while. Remember, it is installing to /mnt, which is actually
representing the /dev/sda2 drive, and also sda1.

then generate an fstab file

```
genfstab /mnt >> /mnt/etc/fstab
```

now arch-chroot into the /mnt root.

```
arch-chroot /mnt
```

generate a locale file

```
vi /etc/locale.gen # edit the locale
locale-gen
```

install grub

```
grub-install
```

make a new grub config

```
grub-mkconfig >> /boot/grub/grub.cfg
```

And bob's your mother's brother.


boot kernel without bootloader
http://www.ondatechnology.org/wiki/index.php?title=Booting_the_Linux_Kernel_without_a_bootloader
