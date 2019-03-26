#!/bin/bash
#####################################################################
## ===================== Disclaimer ============================== ##
## This script-program is a proof-of-concept project and           ##
## a self training playground on Bash scripting.                   ##
## It is free for copy and use, while I am not responsible for any ##
## damage on your software or hardware. Use at your own risk!      ##
## It would be kind if you report any possible bugs, or ideas for  ##
## smart improvement of current code logic and possible new        ##
## features that are relevant.                                     ##
## =============================================================== ##

#####################################################################
##                         safesync                                ##
## This script will find the fastest Manjaro repo servers          ##
## and save them at pacman mirrorlist or locally for later usage,  ##
## initially setting the fastest in priority                       ##
## Checking and changing to a safe to update mirror.               ##
## Testing mirrors for speed or whatever (WIP)                     ##
## Acts like Manjaro pacman-mirrors, from a different perspective  ##
## =============================================================== ##
#####           petsam's "Adventures in Bash"                   #####
#####################################################################

# set -e

# Don't run as root or sudo
if (( $(id -u) == 0 )); then
    echo "You should not run this script as root"
    echo "Exiting..."
    exit;
fi
# echo "User: " $USER " " "$(id -u)"

# Help message
SfsHelp="Safesync creates Manjaro mirrorlist and changes mirrors safely
    Options:
    safesync {-i --init} (Re)Initialize the mirrorlist sorted by fastest
    safesync {-t --test} Test current active servers status
    safesync {-n --next} Select the next (safe) mirror server in /etc/pacman.d/mirrorlist
    safesync (-h --help) This help message information"

SfsMirrorlistHeading="##### Generated by SafeSync #####
"
    
IsManjaro=$(grep -iwH manjaro /etc/*release)
LocalRepo="/var/lib/pacman/sync/"
DBRepos=$(for r in $(ls /var/lib/pacman/sync/*.db); do repo=${r##*/}; echo  ${repo%.db}; done)

# TODO add option parameter for a custom/local mirrorlist to test (--test)
#MirrorList=mirrorlist
MirrorList=/etc/pacman.d/mirrorlist
# Create work directory
if [ -w /tmp ];then
	WorkDir=/tmp/$0-$(date +%s)
else
	WorkDir=$HOME/.local/tmp/$0-$(date +%s)
fi
mkdir -p "$WorkDir"
# WorkDir="$WorkDir"\/
echo "Created working directory :" "$WorkDir"
cd $WorkDir

# Check for given command line parameters  
if [ $# -eq 0 ]; then
    echo "No arguments provided"
    echo -e "$SfsHelp"
    exit;
elif [ $1 = "-i" ] || [ $1 = "--init" ]; then
    echo "Starting creation of mirrorlist"
elif [ $1 = "-n" ] || [ $1 = "--next" ]; then
    PConfRepos=$(grep -v ^# /etc/pacman.conf | grep -F [ | grep -v options)
    RepoSections=$(grep -v ^# /etc/pacman.conf | grep -v options | grep -m1 -A 1000  ^\\[ | tr -d " ")
    arch=$(uname -m)
    CurrentRepo=""
    if [ ! -f $MirrorList ]; then echo "MirrorList was not found. Exiting..." ; exit; fi
    MListServers=$(grep "Server" $MirrorList | tr -d " " | cut -d "=" -f 2)
    # Check active servers in mirrorlist
    echo "Local repos: " ${DBRepos[@]}
    #echo ${MListServers[@]}
	
	for server in ${MListServers[@]}
		do
			IsSafe=""
			# Construct sed server regexp variable
			SedServer=${server#*//}
			SedServer=${SedServer/"/"*/}
			SedServer=${SedServer//"."/"\."}
			echo $server
			echo ${DBRepos[@]}
			for crepo in ${DBRepos[@]}
				do
					# Construct curl server line variable
					ServerLine=${server//\$arch/${arch}}
					ServerLine=${ServerLine//\$repo/${crepo}}
					LocalCRepo=$LocalRepo
					#echo "Current repo :"$crepo
					LocalCRepo+="/${crepo}.db"
					LocalCRepoTime=$(stat -c "%y" $LocalCRepo | xargs -I {} date  -d {} +"%s")
					ServerLine+="/${crepo}.db"
					RepoTime=$(curl -sIm 5 $ServerLine | grep -i ^"Last-Modified" | cut -d ":" -f 2,3,4 | xargs -I {} date -d {} +%s)
					
					if ! [ $RepoTime ]; then
						echo $crepo ": Remote Time is null"
						IsSafe="UNSAFE"
						echo $crepo " is " "$IsSafe"
						if [[ $(grep -e "$SedServer" "$MirrorList" | tr -d " " | grep -c -e "^Server") -ge 1 ]]; then
							pkexec sed -i '/'"$SedServer"'/ s/^Server/#Server/' "$MirrorList"
							echo "$server is UNSAFE and was disabled."
						fi
						continue 2
						#echo "Error status: " $?
					elif  [[ $RepoTime -ge $LocalCRepoTime ]] ; then
						IsSafe="OK"
						echo $crepo $RepoTime $LocalCRepoTime  $IsSafe
					else 
						IsSafe="UNSAFE"
						echo $crepo " is " "$IsSafe"
						echo $crepo $RepoTime $LocalCRepoTime  $IsSafe
						if [[ $(grep -e "$SedServer" "$MirrorList" | tr -d " " | grep -c -e "^Server") -ge 1 ]]; then
							pkexec sed -i '/'"$SedServer"'/ s/^Server/#Server/' "$MirrorList"
						fi
						echo "$server is UNSAFE and was disabled."
						continue 2
					fi
				done
			if [[ $IsSafe == OK ]]; then
				echo $server " is " "$IsSafe"
				if [[ $(grep -e "$SedServer" "$MirrorList" | tr -d " " | grep -c -e ^#Server) -ge 1 ]]; then
					pkexec sed -i '/'"$SedServer"'/ s/^#*Server/Server/' "$MirrorList"
					echo "Enabled in mirrorlist!"
				fi
				exit;
			fi
		done
	# TODO Check for an active good mirror and if not, warn for recreating mirrorlist with --init, or pass directly (break the 'if')
	if $(grep ^Server "$MirrorList"); then
		echo "There is no enabled Server in the mirrorlist. Recreate mirrorlist with \"safesync -i\" "
	fi
	exit;
    
elif [ $1 = "-t" ] || [ $1 = "--test" ]; then
    echo "This parameter is not implemented yet. Yet in progress"

    PConfRepos=$(grep -v ^# /etc/pacman.conf | grep -F [ | grep -v options)
    RepoSections=$(grep -v ^# /etc/pacman.conf | grep -v options | grep -m1 -A 1000  ^\\[ | tr -d " ")
    
    arch=$(uname -m)
    CurrentRepo=""

    for Line in $RepoSections
	  do 
		Rentry=$(echo $Line | cut -d= -f1)
		RValue=$(echo $Line | cut -d= -f2)
		echo "Current entry :" $Rentry
		echo "Current value :" $RValue
		
		if [ $Rentry = $RValue ]; then
		    CurrentRepo=$(echo $Rentry | tr  -d '[:punct:]')
		    echo "Current repo :"$CurrentRepo
		    LocalRepo+="/${CurrentRepo}.db"
		    LocalRepoTime=$(stat -c "%y" $LocalRepo | xargs -I {} date  -d {} +"%s")
		elif [ $Rentry = "Server" ]; then
		    repo=$CurrentRepo
		    echo "Current repo :"$CurrentRepo
		    echo ${RValue}" "$(curl -sIm 5 $RValue/$repo.db | grep -i ^"Last-Modified" | cut -d ":" -f 2,3,4 | xargs -I {} date -d {} +%s) >> remotestatus.log
		elif [ $Rentry = "Include" ]; then
		    repo=$CurrentRepo
		    #echo "Current repo :"$CurrentRepo
		    if [ -r $Rvalue ]; then
			  MirrorList=$(cat ${RValue} | grep "Server?=" | tr  -d " " | cut -d= -f2)
			  Mirrors=${MirrorList[@]//\$arch/${arch}}
			  Mirrors=${Mirrors[@]//\$repo/${repo}}
			  for ServerLine in ${Mirrors[@]}
				do
				    ServerLine+="/${repo}.db"
				    RepoTime=$(curl -sIm 5 $ServerLine | grep -i ^"Last-Modified" | cut -d ":" -f 2,3,4 | xargs -I {} date -d {} +%s)
				    echo $ServerLine $RepoTime $LocalRepoTime  $(if  (( $RepoTime >= $LocalRepoTime )) ; then echo OK; else echo UNSAFE; fi)
				    # >> remotestatus.log
				done
		    fi
		fi
	  done

    exit;
elif [ $1 = "-h" ] || [ $1 = "--help" ]; then
    echo -e "$SfsHelp"
    exit;
else
    echo "This is not a valid parameter!" $1
    echo -e "$SfsHelp"
    exit;
fi

SysBranch=$(grep -v ^# /etc/pacman.d/mirrorlist | grep -wo -m1 -E "stable|testing|unstable")

echo "System Branch is $SysBranch"

## Get user Branch
echo "What is your Branch? Press <S> Stable, <T> Testing "
echo " <U> Unstable <Enter> for "$SysBranch" <C> Cancel"

read selBranch
# echo $selBranch " selected"

if [ ! $selBranch ]; then
    MyBranch="testing"
else
    case "$selBranch" in
	  [Ss])MyBranch="stable";;
	  [Tt])MyBranch="testing";;
	  [Uu])MyBranch="unstable";;
	  [Cc])rm -R $(WorkDir) ; exit ;;       ## TODO clean temp dir
	  *)MyBranch="$SysBranch";;
    esac
fi

echo "We will configure mirrors for $MyBranch Branch"

case $MyBranch in
    stable)
    AwkBranch="2"
    ;;
    testing)
    AwkBranch="3"
    ;;
    unstable)
    AwkBranch="4"
    ;;
    *)
    echo "There is a wrong Branch setting. Exiting..."; exit;
    ;;
esac

echo "Get status.json locally"
curl -s https://repo.manjaro.org/status.json | jq > status.json

# Get mirrors (branches, last_sync, url, country)

cat status.json  | jq '.[] | .last_sync, .branches[0], .branches[1], .branches[2], .protocols[0], .protocols[1], .protocols[2], .country, .url' | tr -d \" | pr -a -9 -T -J | grep -v "^-1" > allmirrors.log

echo "Filtering for bad mirrors"
# TODO add selectable timeout in seconds
# BadMirror=49
#  awk variable -v badmirror="$BadMirror" (when I find out how to check the regexed value..)
awk '/^[0-4][0-9]\:/  { print $8 "\t " $9 }' allmirrors.log | tr -d "_" | tr '[:upper:]' '[:lower:]'> goodmirrors.log

## Get user countries

declare -al CountryGroup
CountryGroup[1]="Austria Belgium Czech Denmark France Germany Netherlands"
CountryGroup[2]="France Netherlands Portugal Spain UnitedKingdom"
CountryGroup[3]="Bulgaria Greece Italy Turkey"
CountryGroup[4]="Belarus Bulgaria Georgia Poland Hungary Russia Sweden Ukraine"
CountryGroup[5]="Bangladesh China HongKong Indonesia Iran Japan Philippines Singapore SouthKorea Taiwan Vietnam"
CountryGroup[6]="Brazil Chile CostaRica Colombia Ecuador"
CountryGroup[7]="Canada Ecuador UnitedStates"
CountryGroup[8]="Kenya SouthAfrica"
CountryGroup[9]="Australia Japan NewZealand"


echo "(1) Austria,Belgium,Czech,Denmark,France,Germany,Netherlands"
echo "(2) France,Netherlands,Portugal,Spain,United_Kingdom"
echo "(3) Bulgaria,Greece,Italy,Turkey"
echo "(4) Belarus,Bulgaria,Georgia,Poland,Hungary,Russia,Sweden,Ukraine"
echo "(5) Bangladesh,China,Hong_Kong,Indonesia,Iran,Japan,Philippines,Singapore,South_Korea,Taiwan,Vietnam"
echo "(6) Brazil,Chile,Costa_Rica,Colombia,Ecuador"
echo "(7) Canada,Ecuador,United_States"
echo "(8) Kenya,South_Africa"
echo "(9) Australia,Japan,New_Zealand"
echo " "
echo "Select the countries you want for your mirrors."
echo "Enter the group number or the country name separated by a comma <,>"
echo "You may mix groups with country names, case insensitive, with spaces or lower dash."

read -r  selCountriesSingle

selCountriesSingle=$(echo "$selCountriesSingle" | sed 's/\ //g' | tr '[:upper:]' '[:lower:]' | sort -u)
IFS=',' read -ra selCountries <<< "$selCountriesSingle"
echo "You selected: " ${selCountries[@]}
if [ ${#selCountries[@]} == 0 ]; then
    echo "No countries entered. Exiting"
    rm -R "$WorkDir" 
    exit 
else 
	RepoCountries=""
	for Country in ${selCountries[@]}
		do
			if [[ $Country == [0-9] ]]; then
				IFS=' ' read -ra Group  <<< "${CountryGroup[$Country]}"
				for GrpCountry in ${Group[@]}
					do
						echo $GrpCountry
						if [[ -f proberepos.conf ]]; then
							if  [[ $(awk '{print $2}' proberepos.conf | grep -ciw $GrpCountry) -eq 0 ]]; then
								awk -v country="$GrpCountry" '{ if ( $1 == country )  print $2, $1 }' goodmirrors.log >> proberepos.conf
							fi
						else
							awk -v country="$GrpCountry" '{ if ( $1 == country )  print $2, $1 }' goodmirrors.log > proberepos.conf
						fi
						if [ "$RepoCountries" = "" ]; then
							RepoCountries=$GrpCountry
						else
							RepoCountries="$RepoCountries, $GrpCountry"
						fi
					done
			else
				echo $Country
				if [[ $(awk '{print $2}' proberepos.conf | grep -ciw $Country) -eq 0 ]]; then
					awk -v country="$Country" '{ if ( $1 == country )  print $2, $1 }' goodmirrors.log >> proberepos.conf
					if [ "$RepoCountries" = "" ]; then
						RepoCountries=$Country
					else
						RepoCountries="$RepoCountries, $Country"
					fi
				fi
			fi
		done
fi
if [ "$RepoCountries" = "" ]; then
    echo "No valid countries selected. Exiting..."
    exit
else
    echo "Selected countries:"
    echo $RepoCountries
fi

echo "Testing repos:"
cat proberepos.conf
echo " "
Arch=$(uname -m)
TestMirrors=$(awk '{print $1}' proberepos.conf)

## Select verbose or quiet
CurlQuiet=true
if [ $CurlQuiet == true ]; then
    CurlFlags="%{url_effective}\\t%{scheme}\\t%{time_total}\\t%{time_appconnect}\\t%{time_starttransfer}\\n"
else
    CurlFlags="URL:\\t%{url_effective}\\n\\nFilename:\\t%{filename_effective}\\nProtocol:\\t%{scheme}\\nRetries:\\t%{num_connects}\\nDownload\\ size:\\t%{size_download}\\nTimes:\\n\\t\\tSecure\\ connect:\\t%{time_appconnect}\\n\\t\\tUntil\\ transfer:\\t%{time_starttransfer}\\nTotal\\ time:\\t%{time_total}\\n\\n"
fi

## Select priority on https
PriSSL=false
if [[ "$PriSSL" == true ]]; then
    CurlProto="--proto-default https --connect-timeout 12"
    echo Protocol flags "$CurlProto"
else
    CurlProto="--connect-timeout 10"
    echo Protocol flags "$CurlProto"
fi

## Probing repo servers for speed check
echo "Starting repo servers testing. Please wait..."
for mirror in $TestMirrors
    do
        echo "$mirror"
        # SizeGood=false
        # curl -SsI -o mheader "$mirror""$MyBranch"/extra/"$Arch"/extra.files.tar.gz
        ConGood=$(curl -SsI -w "%{http_connect}" "$mirror""$MyBranch"/extra/"$Arch"/extra.files.tar.gz | grep -iw ^http | cut -d\  -f2)
        echo "Response is " "$ConGood"
        if (( ConGood >= 200 )) && (( ConGood < 400 )) ; then
		curl -m 37 --stderr probing.err $CurlProto -f -Ss -w "$CurlFlags" -o /dev/null --url "$mirror""$MyBranch"/extra/"$Arch"/extra.files.tar.gz  >> probing.log
		#echo "Error code " $?
		#echo "Finished probing server"
		if [ $CurlQuiet == true ]; then
		    awk -v mirror="$mirror" '{ print mirror, $2, $3 }' probing.log | tail -n1 >> result.log
		fi
        else
		echo "This mirror server seems deactivated or having temporary problems. Skipping..."
	  fi
    done
# TODO add parameters or conf file for custom options on --verbose, --prefer-secure-protocol, --max-timeout
if [ $CurlQuiet == true ]; then
    if [ -s result.log ]; then
	  echo "The results are saved"
	  awk '{ print $1, $2, $3 }' result.log | sort -k3 -n -
	  echo " "
	  while true; do
		read -p "Do you want to save these mirrors as your system mirrorlist?
		[Y]es [N]o [L]ocally: " SaveMirrorList
		echo "$MyBranch"
		case $SaveMirrorList in
		[Yy]) echo $SfsMirrorlistHeading > mirrorlist
			  awk '{ print $1, $2, $3 }' result.log | sort -k3 -n - | awk -v branch="$MyBranch" ' { print "#Server = " $1 branch "/$repo/$arch" }' >> mirrorlist
			  sed -i '2 s/^#//' mirrorlist
			  echo " The mirrorlist has been created at "$WorkDir"/mirrorlist"
			  echo "Copying to system..."
			  pkexec cp -b --suffix ."$(date +%s)" "$WorkDir"/mirrorlist /etc/pacman.d/
			  # TODO ask to delete workdir
			  break ;;
		[Ll]) echo $SfsMirrorlistHeading > mirrorlist
			  awk '{ print $1, $2, $3 }' result.log | sort -k3 -n - | awk -v branch="$MyBranch" ' { print "#Server = " $1 branch "/$repo/$arch" }' >> mirrorlist
			  sed -i '2 s/^#//' mirrorlist
			  echo " The mirrorlist has been created at "$WorkDir"/mirrorlist"
			  echo "Use this command to replace current mirrorlist (the old one is backed up)"
			  echo "sudo cp -b --suffix old "$WorkDir"/mirrorlist /etc/pacman.d/"
			  break ;;
		[Nn]) break ;;
		   *) echo "   Answer [Y]es or [N]o." ;;
		esac
	  done
    else
	  echo "There were errors and a mirrorlist could not be created."
	  echo "Maybe try selecting other countries."
	  echo "If you think this is a bug, please report it to the script author."
    fi
else
    cat probing.log
    echo " "
    echo "=================================================================="
    echo "Verbose output."
    echo "No mirrorlist auto creation. Do manual mirror selection and editing mirrorlist"
    echo "View the full output at "$WorkDir"/probing.log"
fi

if [ -s probing.err ]; then
    echo "=================================================================="
    echo " "
    cat probing.err
    echo " "
    echo "=================================================================="
    echo "There was an error."
    echo "Please, report this bug to the script author."
fi

exit
