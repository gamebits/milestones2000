# Programmer’s notes (October 2026)

Thanks to the hundreds of people who downloaded and paid Reliefware fees for this game. I no longer live in Tennessee, but can be reached at drkenfp@mac.com if you have any general questions about the game. I no longer own my beloved Apple ][gs, so I am unable to assist with any technical questions about the build. I give you permission to peruse and play with these files for your personal use. I do not give permission for anyone to sell these files for any purpose.

God Bless,
Ken Franklin”

# Documentation for "Milestones 2000" by Ken Franklin

## INTRODUCTION

MILESTONES 2000 is an automobile race game played with a special deck of cards.  One player plays against the computer.  It is written in ORCA Pascal, which uses the speed, the stereo sound, and the advantages of GSOS 5.0.2.  The program contains over 500K of digitized sound and graphics files, packed into a single 340K file for ease of use (using Apple's sound and graphics compression techniques).

This game is Reliefware -- very similar to Shareware. Please try it out for a week. If you enjoy it, please pay for it by sending $15 to:

> ReliefWare Central  
> Ken Franklin  
> 1603 Northridge Ct  
> Clarksville, TN  37042-5162

> **\*\*\*IMPORTANT!\*\*\***  ALL money received for this game will be given to charities working for homeless relief.  I intend to choose charities that show a good record of truly benefiting homeless families.  I do NOT intend to keep any of the money.  If you enjoy having a roof over your head and a computer within it, please consider paying the Reliefware fee.

If you don't enjoy it, or don't want to pay the $15, then please delete it or pass it on to a friend. This is NOT public domain software, and may not be sold without my written permission. It may be distributed freely on bulletin boards or to friends, as long as this complete documentation file accompanies it.

Your honesty and constructive criticism are appreciated.

## LEGAL STUFF

This documentation and software are Copyright 1990 by Ken Franklin.  I give permission to distribute copies of the package ONLY AS A UNIT (documentation, program, and icon file) and ONLY FOR FREE.  I do not give permission for the sale of copies of this package.  All other rights are reserved.  I make no guarantees that this program will make your dog behave, or raise your computer's consciousness.  If you don't want it, toss it.

User groups who want to distribute this package for a small "copying fee" can get permission by contacting me by mail, or by EMail (America Online "Dr Ken  FP"'; GEnie KEN.FRANKLIN).

This program contains material from the ORCA/Pascal Run-Time Libraries, copyright 1987-1988 by Byte Works, Inc.  Used with permission.

## SYSTEM REQUIREMENTS

* **Hardware / RAM:** Milestones 2000 requires an Apple IIGS with 1 Meg of RAM.  To use this minimum configuration, you need to prepare a "stripped-down" system disk (see **3.5" DISK INSTALLATION** below).  Users with a hard drive and many desk accessories will probably need a bit more RAM.
* **System Version:** System 5.0.2 (as a minimum) is needed to run MILESTONES 2000.  However, System 5.0.4 is recommended, since the audio processing tools are much faster in that version.

## HOW TO PLAY THE GAME

Complete rules of the game are included under the "Game" item, under "Help".  

* **Interface:** Basically, when you see a watch icon, it's the computer's turn; when you see a pointer icon, it's your turn.  You play a card by pointing at it with the cursor, then dragging it to where you want to play it.
* **Objective:** The basic object of the Game is to score 5000 points by competing in a series of road rallies.  Your Apple ][gs is your opponent.  You use a special deck of 101 cards to play Milestones 2000: there are Distance cards, Fix cards, and Power cards to aid your cause, and Problem cards to hinder your opponent.

## HARD DISK INSTALLATION

Make sure you have System 5.0.2 or later running.  Also make sure you have TOOL029 (the ACE Toolset) in the TOOLS folder of your SYSTEM folder.  If it's not, use the Installer on your System Tools disk to install the ACE toolset.

Make sure the files MILESTONES.2000 and MSHOF are in the same directory; then launch MILESTONES.2000 to begin.  That's it!

> **IMPORTANT:** Your IIGS will write to the file MSHOF any time you quit.  If you lock that file, or delete it, or write-protect the volume it's on -- you'll get a nasty message, and any saved game or updates to the "Hall of Fame" will be lost.  At ehe start of the program, the IIGS looks for the file; if it's messed up, missing or inaccessible, the program will try to recover -- but I make no guarantees, other than it doesn't try to erase anything.

An extra copy of the file MSHOF is included, called EMPTYHOF.  If all else fails, delete MSHOF and rename the file EMPTYHOF to MSHOF..

## 3.5" DISK INSTALLATION

1. Make a COPY of your system disk (5.0.2 or later).  DO NOT DO THIS TO YOUR ORIGINAL!
2. In the SYSTEM/TOOLS folder, delete all tools >EXCEPT< TOOL014, TOOL015, TOOL016, TOOL018, TOOL020, TOOL021, TOOL022, TOOL027, TOOL029, and TOOL034.
3. In the SYSTEM/SYSTEM.SETUP folder, delete the CDEV.INIT file.
4. Delete the CDEV folder and its contents.
5. Delete all desk accessories (including CONTROL.PANEL) from the SYSTEM/DESK.ACCS folder (but leave the folder alone).
6. In the SYSTEM/DRIVERS folder, delete all files >EXCEPT< APPLEDISK3.5 and CONSOLE.DRIVER.
7. In the SYSTEM/FONTS folder, delete all files except FASTFONT.
8. In the SYSTEM folder, delete P8 and START.
9. In the ICONS folder, delete FTYPE.MAIN and FTYPE.AUX.
10. In the root directory, delete BASIC.LAUNCHER and BASIC.SYSTEM.
11. Finally (!) you should now have a disk with over 340K free. Copy the files MSHOF and MILESTONES.2000 to the root directory of this disk.  Then rename MILESTONES.2000 to MS.SYS16.
12. Boot this disk, and it will run the game.  When you select Quit, it will save MSHOF and restart -- as soon as the game reappears, you can turn off your machine.

## WHAT'S NEW IN VERSION 1.5

* The "About" box shows my current address.
* The Hall of Fame rankings are cleaned up each time the program is run.  First, if two entries are the same except that one is capitalized and one is not, the two are combined.  Second, the sort is now according to TOTAL point spreads, instead of average point spread per game.
* The computer asks you for the player's name at the start (instead of making you select "Player..." from the menu).  To keep the current player name, just press return.
* The computer is a teeny bit smarter in its play, and goes for 2000km less frequesntly.
* The Info menu has two options: TURN SOUND ON/OFF (self-explanatory) and TURN DECK COUNT ON/OFF.  The latter toggles a small blue rectangle at the bottom of the screen that shows how many cards remain in the deck; when 10 or less cards remain, the rectangle turns red.
* By dragging cards back and forth in the green section, you can now rearrange your hand.
* Finally, I changed the Acknowledgements (under "Help") to include my new son, Jeremy Karl Franklin.

## TECHNICAL NOTES

MILESTONES 2000 is a new version of MILESTONES, my first published Apple program.  It is based on Parker Brothers' MILLE BORNES, which in turn was derived from one of several "car racing" card games of England and France.

The sounds dressed up using Sound Shop, a utility included with Roger Wagner's Hyperstudio. The graphics were painted with Activision's Paintworks Gold and Beagle Bros' Platinum Paint. The programming was done using Byte Works' ORCA Pascal. The entire project used up many evenings over three months.  The program itself is only 60K of the file; the remainder is in the "resource fork". For the programmers out there, there are four custom resource types:

* `$0BA6` = graphics bitmaps, packed using PackBytes
* `$0BA7` = index of LocInfos for graphics resources
* `$2BA6` = ACE-compressed digitized sound samples
* `$3BA6` = an array of size/speed/volume data for the `$2BA6` resources

If you're interested, the number $BA6 was used because the hex digits correspond to position of my initials (KJF) in the alphabet.  I did not use the "standard" sound resource format - mainly because I couldn't figure out how to convert the SoundShop and ACE data into the numbers needed for the standard format.

The Blue car (as my son Matt points out) is my 1989 Chrysler LeBaron, also known as "Spacerider".

Enjoy.

--Ken Franklin  
22 December 1990