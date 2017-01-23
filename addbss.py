#!/usr/bin/env python2
# 
# addbss.py
# 
# After using objcopy to convert an ELF file to a HEX file, the BSS section is
# uninitialized. When using a dumb bootloader that just copies the HEX-file
# to memory, this will cause problems. This script adds the BSS section to the HEX file.
#

import subprocess
import re
import sys
import os

from intelhex import IntelHex

def get_bss_section(bbl):
    """ Call the 'size' command to get the address and size of the bss section """
    size = os.environ['SIZE']

    sections = subprocess.check_output([size, "--format=SysV", bbl])

    bss = None

    regex = re.compile("^.bss *([0-9]*) *([0-9]*)$")
    for line in sections.split("\n"):
        res = regex.match(line)
        if res:
            bss = [int(res.group(1)), int(res.group(2))]

    return bss

def main():
    try:
        bbl_file = sys.argv[1]
        hex_file = sys.argv[2]
        offset = int(sys.argv[3], 0)
    except (IndexError, ValueError):
        print "Usage: %s elf_file hex_file offset" % sys.argv[0]
        sys.exit(1)
   
    bss = get_bss_section(bbl_file)
    
    hex_fp = IntelHex(hex_file)
    hex_fp.puts(bss[1] - offset, "\0" * bss[0])
    hex_fp.write_hex_file(hex_file)
    
if __name__ == "__main__":
    main()
    
