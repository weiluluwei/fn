# fn

In my first year of work of SQA which deals with server hardware frequently, after a few months I got a little bored of manually remote restart server and wait for the POST screen and press F2/F8/F12/F9, this idea came to me that I need to automate my work. So came several of bash scripts that aids my job and ease the pain.

fn was the first.

For those who are not familliar with servers, most servers(x64) are equiped with bmc, which is a microprocessor runs an embedded operating system. Its name may vary among different vendors, but the principle is the same. This chip gives user ability to take control of the server remotely through its command line or ipmi interface.

You may have wondered that it seems bmc can do the job perfectly, why do I need this script?
For one is that even though bmc can set boot device in a single line of command, it does not work in uefi mode at the time, and the command options are limited to bios/disk/floppy/pxe etc, what if I want to boot through other than the default device, say the second nic port, or enter the HBA option ROM? It turns out that extra work must be done either by add features to BIOS and bmc or think of something else
The other thing is that in my line of work as SQA, we need to find defects, instead of finding one way to make it work, I need to find out why others not. There are several of ways to choose boot device, aside from bmc command line and ipmi, I can set it to default in BIOS, dump and load config files, or we can always press the key to choose from the menu while boots.

This script take advantage of the serial console, and sends control charaters to it, in which approach the purpose of choose device is accomplished. This is a very early version, functions like CTRL-X to enter opROM and select items in menu are not implemented(that script will not be put here at current), also check the script when downloaded, some control charaters may be missing.
