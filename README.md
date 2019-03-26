# safesync

> This script is for Manjaro systems on which configures/creates or tests system's mirrorlist.
It can also change the active mirror in mirrorlist ("on-the-fly"), protecting from selecting an unsafe mirror.
(Acts like Manjaro `pacman-mirrors`, from a different perspective)

### Dependencies
* bash :)
* jq
* curl (required by pacman too)
* awk, grep, (included in `base/base-devel`)
* polkit (optional for writing system mirrorlist with `pkexec`)

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

The scope is to always have ONLY ONE active server in the mirrorlist and only change it when needed (server is down, need the latest Manjaro updates as soon as posible etc.).

You keep/maintain your preffered mirror servers in the standard pacman mirrorlist, with all except one commented out.

This way, your system will either update safely, or not at all, in which case you can change the active server, only if/when you need to.

A possible workfrlow for using safesync as your main mirrorlist maintenance tool can be:
1. Create your mirrorlist initially, choosing from any available countries in repo.manjaro.org. (`--init`). This will save a sorted list of servers by speed (fastest first) and enable the first one.
2. After initial creation, run `--next` to verify the active server is _safe_ (DBs are same or newer than your current local DBs). If not, it will disable the current (_unsafe_) and enable the _next safe_ server.
3. That's it, until you notice pacman reporting unable to update, or very slow downloads etc. If you decide to change the active server, only run `--next` and check again with `pacman`.

For whoever finds this usefull, I will be happy. For the rest, do your maintenance however you prefer.

Please report any bugs and ideas for relevant useful improvements and features.

Most of all, I would appreciate advice from experienced users in Bash scripting or code in general, for improving my script/command methods and learning to write more efficient, safer and smarter code.

I know I lack experience on many, like:
* Error traping/control
* Variables escaping/quoting
* For/until loops etc.
* Picking the better tool for filtering/sorting etc. (awk, grep, find...)
* and more..

