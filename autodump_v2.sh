#!/bin/bash

# (c) 2014-2017 Denis Gudtsov, CPM Ltd.
#
# grab tcpdump from multiple hosts
# 

declare -a pids

declare -A pcaps_AM
declare -A mlogc_AM
declare -A pcaps_hosts
declare -A mlogc_hosts

# check if xterm available
x_avail=`env |grep DISPLAY= |wc -l`
# or set x_avail=0 in config

. ./autodump_v2.cfg

### functions

function readshm {
#	$ssh_cmd ${am[$i]} $readShm_cmd
#	echo param: $1
	$ssh_cmd ${AM[$1]} $readShm_cmd
#	cat readshm.txt
}


function read_cards {

		for i in "${!AM[@]}"
		do

			product=$i
			echo "connecting to product: $product"
#			if [ -n "${commands_pcap_da[${product}-AM]}" ]
#			then
#			echo "commands for AM: ${commands_pcap_da[${product}-AM]}"
#			fi


			shm_result=$(readshm $i)

			active_cards=`echo "$shm_result" | grep _ACTIVE |awk '{print $1" "$6}'`

#			echo "act cards: $active_cards" 

			# array of MP,CE,AM...	
			card_types=($(echo "$active_cards" | awk '{print $2}' | sort| uniq))

			for card_type in "${card_types[@]}"
			do
					echo "type: $card_type"
		#  		    echo "$active_cards" |grep $card_type |awk '{print $1}'	
					cards=($(echo "$active_cards"|grep $card_type |awk '{print $1}'))

					# filling hosts
					if [ -z "${DA[${product}-${card_type}]}" ]
					then
						echo "empty $product - $card_type"
						DA[${product}-${card_type}]=${cards[@]}
				    else
						echo "NON empty $product - $card_type"
					fi

#					echo "cards: ${cards[@]}"
		#			echo "size: ${#cards[@]}"
			done
#			fi

	done
}


function get_data {

# mode: pcap or mlogc
mode=$1

declare -A commands_da

case "$mode" in 
		pcap)
#				commands_da=( "${commands_pcap_da[*]}" )
				for key in "${!commands_pcap_da[@]}"  # make sure you include the quotes there
				do
				  commands_da["$key"]="${commands_pcap_da["$key"]}"
				done
				filename_template="$template_pcap"
				local_store_dir=$pcap_local_store_dir
				;;
		mlogc)
#				commands_da=${commands_mlogc_da[@]}
				for key in "${!commands_mlogc_da[@]}"  # make sure you include the quotes there
				do
				  commands_da["$key"]="${commands_mlogc_da["$key"]}"
				done
				filename_template="$template_log"
				local_store_dir=$mlogc_local_store_dir
				;;
esac


for prod_card in "${!commands_da[@]}"
do

 cmd=${commands_da[$prod_card]}
 echo command for $prod_card card is: $cmd
 product=`echo $prod_card | awk 'BEGIN {FS="-"}{print $1}'`
 card=`echo $prod_card | awk 'BEGIN {FS="-"}{print $2}'`
 # product - ключ в AM
 shelf_slot_list=(${DA[$prod_card]})

 printf 'shelf_slot_list: %s\n' "${DA[$prod_card]}"


 declare -a files_temp
 files_temp=()
 # карточек может быть несколько
 for c in "${shelf_slot_list[@]}"
 do

		 full_host="$prod_card-$c"
		  echo "connecting to  : $full_host"

		  filename_host=${filename_template/__HOST__/$full_host}
		  filename_date=${filename_host/__DATE__/$date_format}
		  filename=${filename_date/__CASE__/$case}

		  full_path="$local_store_dir/$filename"

		 echo c: "$prod_card-$c"
		 echo card: $card
		 echo file: $full_path
		 # если не DA, не делать лишний ssh
		 if [ "$card" = "AM" ]
		then
				if [ "$x_avail" -gt "0" ] && [ -x $xterm_cmd ]; then
					xterm -e "$ssh_cmd ${AM[$product]} '$cmd >$full_path'" &
				else
		 			$ssh_cmd ${AM[$product]} "$cmd >$full_path" &
				fi
				
			pid=$!
		 else
				if [ "$x_avail" -gt "0" ] && [ -x $xterm_cmd ]; then
					xterm -e "$ssh_cmd ${AM[$product]} 'ssh $c $cmd >$full_path'" &
				else
		 			$ssh_cmd ${AM[$product]} "ssh $c $cmd >$full_path" & 
				fi
			pid=$!
 		fi
		
		pids+=($pid);
 
		files_temp+=($full_path)

		 # в c - конкретный shelf-slot
		 # здесь делаем ssh на AM и оттуда ssh на c с командой cmd
 done

 echo "files for $product :"
 printf '%s\n' "${files_temp[@]}"
 case "$mode" in 
		pcap)
			temp_pcaps=${pcaps_AM[$product]}
			files_temp+=($temp_pcaps)
			pcaps_AM[$product]=${files_temp[@]}
				;;
		mlogc)
			temp_mlogc=${mlogc_AM[$product]}
			files_temp+=($temp_mlogc)
			mlogc_AM[$product]=${files_temp[@]}
				;;
 esac
done


}

function get_hosts
{
# mode: pcap or mlogc
mode=$1

declare -A commands_hosts


case "$mode" in 
		pcap)
				for key in "${!commands_pcap[@]}"  # make sure you include the quotes there
				do
				  commands_hosts["$key"]="${commands_pcap["$key"]}"
				done
				filename_template="$template_pcap"
				local_store_dir=$pcap_local_store_dir
				;;
		mlogc)
				for key in "${!commands_mlogc[@]}"  # make sure you include the quotes there
				do
				  commands_hosts["$key"]="${commands_mlogc["$key"]}"
				done
				filename_template="$template_log"
				local_store_dir=$mlogc_local_store_dir
				;;
esac

 declare -a files_temp
 files_temp=()


for i in "${!hosts[@]}"
do

		 full_host="$i"
		  echo "connecting to  : $full_host"

		  filename_host=${filename_template/__HOST__/$full_host}
		  filename_date=${filename_host/__DATE__/$date_format}
		  filename=${filename_date/__CASE__/$case}

		  full_path="$local_store_dir/$filename"

  echo $mode command for $i: ${commands_hosts[$i]}
  if [ "${commands_hosts[$i]}" != "" ]
	then
		if [ "$x_avail" -gt "0" ] && [ -x $xterm_cmd ]; then
	  		xterm -e "$ssh_cmd ${hosts[$i]} '${commands_pcap[$i]} >$full_path'" &
		else
			$ssh_cmd ${hosts[$i]} "${commands_pcap[$i]} >$full_path" &
		fi
		pids+=($!);
 
#		files_temp+=($full_path)
    	
		case "$mode" in 
		pcap)
			pcaps_hosts[$i]=$full_path
				;;
		mlogc)
			mlogc_hosts[$i]=$full_path
				;;
	 	esac
		
   	echo "files for host $i :"
    printf '%s\n' "$full_path"

	else 
		echo skip host without $mode command
	fi


#    case "$mode" in 
#		pcap)
#			temp_pcaps=${pcaps_hosts[$i]}
#			files_temp+=($temp_pcaps)
#			pcaps_hosts[$i]=${files_temp[@]}
#				;;
#		mlogc)
#			temp_mlogc=${mlogc_hosts[$i]}
#			files_temp+=($temp_mlogc)
#			mlogc_hosts[$i]=${files_temp[@]}
#				;;
# esac

done

}

function copy_remote
{

# mode: pcap or mlogc
mode=$1

for am in "${!AM[@]}"
do
		case "$mode" in 
				pcap)
					files_list=(${pcaps_AM[$am]})
						;;
				mlogc)
					files_list=(${mlogc_AM[$am]})
						;;
		esac


		declare -a remotes_list
		remotes_list=()
		for i in "${files_list[@]}"
		do
				echo i: $i
				remotes_list+=("${AM[$am]}:$i")
		done
		
		if [ "${#remotes_list[@]}" -gt "0" ]
		then
		# копирование		
				$scp_cmd ${remotes_list[@]} ./$filename_dir
		# удаление скопированного
				$ssh_cmd ${AM[$am]} "rm ${files_list[@]}"
		fi
done

for h in "${!hosts[@]}"
do
		case "$mode" in 
				pcap)
					file_item=(${pcaps_hosts[$h]})
						;;
				mlogc)
					file_item=(${mlogc_hosts[$h]})
						;;
		esac

		if [ -n "$file_item" ]
		then
		# копирование		
				$scp_cmd ${hosts[$h]}:${file_item} ./$filename_dir
		# удаление скопированного
				$ssh_cmd ${hosts[$h]} "rm ${file_item}"

		fi
		
done

}

function merge_cap
{
		pushd ./
		cd ./$filename_dir/
		for i in "${!AM[@]}"
		do
			product=$i
			if [ -n "${commands_merge_cap[$product]}" ]
			then
				filename_template="$template_pcap_merged"
		  		filename_prod=${filename_template/__HOST__/$product}
		  		filename_date=${filename_prod/__DATE__/$date_format}
		  		filename=${filename_date/__CASE__/$case}

				${commands_merge_cap[$product]} >$filename
			fi
		done
		
		for i in "${!hosts[@]}"
		do
			product=$i
			if [ -n "${commands_merge_cap[$product]}" ]
			then
				filename_template="$template_pcap_merged"
		  		filename_prod=${filename_template/__HOST__/$product}
		  		filename_date=${filename_prod/__DATE__/$date_format}
		  		filename=${filename_date/__CASE__/$case}

				${commands_merge_cap[$product]} >$filename
			fi
		done
		popd
}

### end functions

case=$1
folder=$2
#date_format=`date +"%d%m%Y"`

if [ "${case:(-1)}" = "/" ]
then
	folder=$case
	case=""
fi

xterm_cmd=`which xterm`

if [ "$case" = "" ]
then
	echo use : $0 [case_name] [directory_to_store]
	echo e.g.: $0 1-voice-tc-1-1
	echo if case is not defined = timestamp
	echo directory_to_store - folder and parents will be created
	echo if derectory is not defined = case_name
	case=`date +"%Y_%m_%d_%H_%M_%S"`
fi

if [ "$folder" != "" ]
then
	filename_dir="$folder/$case"
else
	filename_dir=$case
	echo using default folder: $filename_dir
fi

echo checking network...

$ping_check

if [ "$?" -gt "0" ]
then
	echo "gw is unreachable, exiting"
	exit 1
fi

mkdir -p $filename_dir
#filename_template_pcap="$filename_dir/$template_pcap"
filename_template_pcap="$template_pcap"

filename_template_log="$filename_dir/$template_log"


echo "get cards status..."

read_cards
echo "done"

echo "connecting to DA hosts"

get_hosts pcap

get_data pcap
get_data mlogc


echo "done"

echo stop terminal windows when done
echo press Enter to stop
read
kill ${pids[@]}

# копирование

copy_remote pcap
copy_remote mlogc

merge_cap

gzip ./$filename_dir/*
touch $filename_dir/readme.txt
exit


echo done
