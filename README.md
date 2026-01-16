# T4n-OS-Live — OS Maker

## T4n OS

T4n OS adalah sistem operasi Linux independen yang berfokus pada:
- Minimal & modular
- Kontrol penuh sistem

## Basis Upstream

T4n-OS-Live **berbasis langsung** pada tool resmi Void Linux:

👉 https://github.com/void-linux/void-mklive

Seluruh mekanisme build, opsi, dan perilaku **mengikuti void-mklive**.  
Repositori ini hanya menambahkan **preset dan wrapper khusus T4n OS**.

## Toolchain

- `mkiso.sh` — Live ISO (bootable & installable)
- `mklive.sh` — Live image minimal
- `mkrootfs.sh` — RootFS (tanpa kernel)
- `mkplatformfs.sh` — RootFS + kernel
- `mkimage.sh` — Image ARM
- `mknet.sh` — Netboot
- `installer.sh` — Installer ringan
- `release.sh` — CI & signing rilis

## T4n Wrapper

### `t4n-iso.sh`
```
	Usage: $PROGNAME [options ...] [-- mklive options ...]

	Wrapper script around mklive.sh for several standard flavors of live images.
	Adds void-installer and other helpful utilities to the generated images.
        
	create by Gh0sT4n(https://github.com/gh0st4n) 

	OPTIONS
	 -a <arch>     Set architecture (or platform) in the image
	 -b <variant>  One of base, server, bspwm, xfce, river or kde. 
               May be specified multiple times to build multiple variants.
	 -d <date>     Override the datestamp on the generated image (YYYYMMDD format)
	 -t <arch-date-variant>
	               Equivalent to setting -a, -b, and -d
	 -r <repo>     Use this XBPS repository. May be specified multiple times
	 -h            Show this help and exit
	 -V            Show version and exit

	Other options can be passed directly to mklive.sh by specifying them after the --.
	See mklive.sh -h for more details.
```


### Contoh
```
./t4n-iso.sh -a x86_64
./t4n-iso.sh -a x86_64 -b bspwm
./t4n-iso.sh -a x86_64-musl -b base -p "NetworkManager dbus"
```

## Dokumentasi Lengkap

Semua detail usage, parameter kernel, dan workflow build:
- 👉 https://github.com/void-linux/void-mklive
- 👉 [README.md.in](https://github.com/t4n-company/T4n-OS-Live/blob/main/README.md.in) - README.md T4n OS/Void Linux

## Referensi & Kredit

* [Void Linux & Contributors](https://github.com/void-linux/void-mklive)
* [Langit Ketujuh (L7 OS)](https://github.com/langitketujuh/l7-os)
* [d77void - dani-77](https://github.com/dani-77/d77void)
