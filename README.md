# Binary Firmware Generation Tool (fwgen)

Even though this toolset has been created primarily for microchip usb26x USB-hub
firmware generation it can be used to create nearly any binary blob. The core
shell-script '/etc/fwgen/core.sh' is created just to execute the firmware
generation scripts placed in the root firmware directory '/etc/fwgen/fw'. Each
firmware script can be created with a help of functions described in
'/etc/fwgen/functions.sh'. It's strongly recommended to use a POSIX-shell
language for the firmware and library scripts so to have a portable program.

The cmake build script is responsible for the basic scripts set installation. Together
with them a symbolic link is also copied to the target system so to access the core
utility from the system PATHs.

Here is a usage text of the program:

```
root@mrbt1:~# fwgen -h
 Usage: fwgen -f <firmware> [options]

 Create a binary blob in accordance with the passed firmware script name.

 -h, --help            - Display this help.
 -f, --firmware <name> - Firmware name (mandatory).
 -o, --output   <name> - Name of the output file (stdout by default).
 -l, --layout          - Print a firmware layout instead of the binary data.

 Available firmware:
  usb2640

 Depends on: sed
```

As you can see there is one mandatory argument. It's a firmware name. The program
is looking for the corresponding script in the '/etc/fwgen/fw' directory and
executes one if it's found. By default the output data is redirected to the stdout
if no file is specified ('-o' argument is omitted). A firmware layout info is
produced if '-l' argument is passed to the utility. The last option is useful for
debugging.
