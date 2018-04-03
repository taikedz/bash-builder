#!/usr/bin/env python3

import sys
import re

def isSectionStart(line, interface=""):
    sectionpattern = "^[0-9]+:\\s+%s"
    return re.match(sectionpattern%interface, line) != None

def printSection(interface, lines):
    in_section = False

    for line in lines:
        if in_section:
            if isSectionStart(line):
                return
            print(line, end='')

        else:
            if isSectionStart(line, interface):
                in_section = True
                print(line, end='')

def main():
    interface = sys.argv[1]

    lines = sys.stdin.readlines()

    printSection(interface, lines)

if __name__ == "__main__":
    main()
