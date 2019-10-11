#!/bin/bash

# ------ Check number of Arguments passed ------ #
check_args_count(){
  if [[ $# -lt 3 ]]; then
    show_usage_help
    exit 1
  fi
}

process_args(){
  while [[ -n $1 ]]
  do
    case "$1" in
      -t|--testnet)   used_net="testnet"
        			  ;;
      -m|--mainnet)   used_net="mainnet"
        			  ;;
      -a|--addr-file) if [[ ! -f $2 ]]; then
					    echo "File "$2" not found!"
					  else
						file_path="$2"
					  fi
        			  shift
        			  ;;
      -h|--help)      show_usage_help
        			  ;;
      *) echo "Unknown option: $1"
        			  ;;
    esac
    shift
  done
}


# ------ Load addresses from $file_path ------ #
load_addr_data(){
  declare -ag addr_arr
  num_addr=$(wc -l < "$file_path")
  readarray -t addr_arr < "$file_path"
  echo -e "$num_addr addresses sucessefuly loaded.\n"
}

mk_json_obj(){
  pairs=""
  for((i = 1; i<=$#; i+=2))
  do
	[ -z $pairs ] || pairs+=","
	pairs+="$(eval echo \'\"\'\$$i\'\"\':\'\"\'\$$(($i + 1))\'\"\')"
  done
}

mk_json_lst(){
  items=""
  for(( i = 1; i <= ${#addr_arr[@]}; i++))
  do
	[ -z "$items" ] || items+=","
	items+="$(eval echo \'\"\'${addr_arr[$i-1]}\'\"\')"
  done
}

eval_send_amount(){
  if [[ $used_net == "testnet" ]]; then
	btc_dec=$(bitcoin-cli -testnet getbalance)
  else
	btc_dec=$(bitcoin-cli getbalance)
  fi
  btc_sats=$(echo "$btc_dec * 1*10^8" | bc)
  btc_sats_amount=$(echo "$btc_sats / $num_addr" | bc)
  btc_amount_dec=$(printf "%.8f" $(echo "scale=8; $btc_sats_amount / (1*10^8)" | bc -l))
  echo "$btc_amount_dec"
}

mk_json_object_one_val(){
  local args=""
  shift
  for key in "$@"
  do
	args+="$key $btc_amount_dec "
  done
  mk_json_obj $args
}

mk_json_lst_one_val(){
  local args=""
  for lst in "$@"
  do
	args+="$lst "
  done
  mk_json_lst $args
}

show_usage_help(){
  echo "Usage: $0 [-t|--testnet|-m|--mainnet] [-a|--addr-file] <path/to/file>"
}

send_multiple_payment(){
  eval_send_amount
  mk_json_object_one_val "$btc_amount_dec" "${addr_arr[@]}"
  mk_json_lst_one_val "${addr_arr[@]}"
  if [[ "$used_net" == "testnet" ]]; then
	bitcoin-cli -testnet sendmany "" {$pairs} 6 Payments [$items] true 6 CONSERVATIVE
  else
	bitcoin-cli sendmany "" {$pairs} 6 Payments [$items] true 6 CONSERVATIVE
  fi
  #echo "TxID: $1"
}

LC_NUMERIC=C
check_args_count "$@"
process_args "$@"
load_addr_data
send_multiple_payment "$@"
