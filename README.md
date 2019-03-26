# safesync

> This script is for *Manjaro* systems on which configures/creates or tests system's mirrorlist.
It can also change the active mirror in mirrorlist ("on-the-fly"), protecting from selecting an unsafe mirror.
(Acts like Manjaro `pacman-mirrors`, from a different perspective)

### Dependencies
* bash :)
* jq
* curl (required by `pacman` too)
* awk, grep, (included in `base/base-devel`)
* pkexec (optional for writing system mirrorlist, provided by `polkit`)

```
Safesync creates Manjaro mirrorlist and changes mirrors safely
    Options:
    safesync {-i --init} (Re)Initialize the mirrorlist sorted by fastest
    safesync {-n --next} Select the next (safe) mirror server in /etc/pacman.d/mirrorlist
    safesync {-t --test} Test current active servers status
    safesync (-h --help) This help message information
```
* `-i | --init`

Reads mirror status from repo.manjaro.org, filters out currently in-active servers and starts testing for speed, by downloading a file. Sorts on fastest server and offers to save as the system (pacman) mirrorlist, or in temp folder.

* `-n | --next`

Checks current system's mirrorlist servers repo DBs timestamp and 
  * accepts as _safe_ and enables the first one (if it is not already) more recent than system's DBs timestamps
  * disables each one that has older timestamp than system's DBs, as _unsafe_.

* `-t | --test`

Tests mirror servers for speed or whatever (WIP), similarly to `--init`

## Scope and perspective
The perspective used for a proper and safe package update, avoiding accidental partial updates is to *always have ONLY ONE active server in the mirrorlist and only change it when needed* (server is not responding, need of the latest Manjaro updates as soon as posible etc.). The problem arises when your current active mirror has temporary problems. If there are more than one servers in the mirrorlist, pacman uses the next one. During this change, it is not checked whether the new assigned server has the same update status as the default one (at least, this is what I think, since I haven't read or heard it is; I would be happy if I find out I was wrong!). Manjaro mirror servers have various update/sync frequencies. Some update every hour (or less) while others once a day, depending on the providers. In case you configure your mirrors depending on their up-to-date status, you may have different results depending on the time of configuration and the chosen mirrors/countries. For example: 

A (the) Greek mirror syncs once a day at about 12:00 UTC, while a french mirror every one hour. 

* If I run `pacman mirrors` or check on the repo webpage at 14:00 UTC, I will choose the Greek server as it will be up-to-date and since it's the nearest to me, it's my best choice for speed, as well as the French mirror, but because the French mirror is faster, it goes at the top of the mirrorlist (if I rank for speed), with the Greek one as second. 
* Then there is a Manjaro update at 22:00 UTC and I update my system at 24:00 UTC (using the French mirror).
* Next day at about 08:00-10:00 UTC, I try to install a new package or update the system. If at that time the French mirror is not responding, `pacman` will fallback to the Greek mirror, which has older packages. If you don't use `-y` pacman parameter, you will not even notice an error message for "local packages are newer than remote ones" and you will get into a "partially updated" system!!

With SafeSync method, you are supposed to have only one enabled mirror in the mirrorlist. Then, whenever the server is unusable, you run `safesync --next` and in a few seconds you have the fastest and sefest (for your system) mirror enabled, while the _unsafe_ mirror is disabled. Also, if you always use this command before any system or package syncing action, you will always be sure you will *never* have a _partially updated_ system!

You may use safesync either in your manually configured mirrorlist, or even in combination with a `pacman-mirrors` created one, or of course... exclusively, as it can create a preferred servers list in a very easy interactive procedure, with 9 prefixed country groups (by regions) and a choice to just enter a group number, or enter country names (with or without capitalization format, or spaces, or underscores), or a combination of both. You may write the result to pacman mirrorlist (getting root privileges), keeping a copy of the old one, or save locally and use it as you like.

A possible workflow for using safesync as your main mirrorlist maintenance tool can be:
1. Create your mirrorlist initially, choosing from any available countries in repo.manjaro.org. (`--init`). This will save a sorted list of servers by speed (fastest first) and enable the first one.
2. After initial creation, run `--next` to verify the active server is _safe_ (DBs are same or newer than your current local DBs). If not, it will disable the current (_unsafe_) and enable the _next safe_ server.
3. That's it, until you notice pacman reporting unable to update, or very slow downloads etc. If you decide to change the active server, only run `--next` and check again with `pacman`.

For whoever finds this useful, I will be happy. For the rest, do your maintenance however you prefer.

Please report any bugs and ideas for relevant useful improvements and features.

Most of all, I would appreciate advice from experienced users in Bash scripting or code in general, for improving my script/command methods and learning to write more efficient, safer and smarter code.

I know I lack experience on many, like:
* Error traping/control
* Variables escaping/quoting
* For/until loops etc.
* Picking the better tool for filtering/sorting etc. (awk, grep, find...)
* and more..

