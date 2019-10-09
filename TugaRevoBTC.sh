#!/bin/bash

# ====== Functions section ======

# ------ Help on script usage ------ #
show_usage_help(){
   echo "Usage: $0 [-t|--testnet|-m|--mainnet]"
   echo "
      This script runs either in BTC Mainnet or Testnet.
      Therefore, one of these two options must be passed.
      This script accepts either single char or long version
      of parameters.
   "
}

# ------ Arguments proccessing ------ #
process_args(){
   if [[ "$#" -lt 1 ]]; then
      show_usage_help
      exit 1
   else
      case "$1" in
         -h|-\?|--help)
            show_usage_help
            ;;
         -t|--testnet)
            used_net="testnet"
            ;;
         -m|--mainnet)
            used_net="mainnet"
            ;;
         *)
            echo "Unknown argument"
            show_usage_help
            exit 1
      esac
   fi
}

# ------ Show Main Menu options ------ #
main_menu(){
   #clear
   echo "================="
   echo "Menu --- $used_net"
   echo "================="
   echo "[1] - Send Single Payment"
   echo "[2] - Send Multiple Payments"
   echo "[3] - Check Balance"
   echo "[4] - Check TxID etails"
   echo "[0] - Quit"
}

# ------ Process Menu Options ------ #
process_menu_option(){
   local mnu_opt
   read -r -p '> ' mnu_opt
   case $mnu_opt in
      1) send_single_payment
         ;;
      2) send_multiple_payment
         ;;
      3) check_balance
         ;;
      4) check_txid
         ;;
      0) echo "Quiting TugaRevoBTC..."
         exit 1
         ;;
      -?*) printf 'Unknown option (ignored): %s\n' "$1" >&2
         main_menu
   esac
}

load_addr_data(){
   declare -ag addr_arr
   local addr_fp
   echo "Enter file path containing addresses:"
   read -r -p '> ' addr_fp
   if [ ! -f "$addr_fp" ]; then
      echo File "$addr_fp": not found!
      exit 1
   fi
   num_addr=$(wc -l < "$addr_fp")
   readarray -t addr_arr < "$addr_fp"
   echo -e "$num_addr addresses loaded sucessefuly\n"
}

# ------ Internal Messages System ------ #
confirm_input(){
   echo Please confirm "$1" "$2". Type YES to confirm:
   read -r -p'> ' input
   if [[ $input != "YES" ]]; then
      echo Action cancelled. "$input_type" not confirmed!
   fi
   return 1
}

send_many(){
   load_addr_data
   eval_send_amount
   mk_json_object_one_val "$btc_amount_dec" "${addr_arr[@]}"
   mk_json_lst_one_val "${addr_arr[@]}"
   if [[ $used_net == "testnet" ]]; then
      bitcoin-cli -testnet sendmany "" {$pairs} 6 Payments [$items] true 6 CONSERVATIVE
   else
      bitcoin-cli sendmany "" {pairs} 6 Payments [$items] true 6 CONSERVATIVE
   fi
   echo "TxID: $1"
}

# ------ Send BTC Paymento to a single Address ------ #
send_single_payment(){
   local input_type
   local amount
   local ret
   echo "Which address to send:"
   read -r -p '> ' address
   input_type="address"
   ret = $(confirm_input $input_type $address)
   if "$ret" == 0; then
      echo "How much BTC to send:"
      read -r -p '> ' amount
      input_type="amount"
      confirm_input "$input_type" "$amount"
      if ! $?; then
         echo Sending "$amount" "BTC" to "$address"
         if [[ $used_net == "testnet" ]]; then
            bitcoin-cli -testnet sendtoaddress "$address" "$amount" false
         else
            bitcoin-cli sendtoaddress "$address" "$amount" false
         fi
      else
         return 1
      fi
   else
      return 1
   fi
   echo "Transaction complete"
}

# ------ Check loaded wallet balance ------ #
check_balance(){
   echo "used_net: $used_net"
   echo Checking Full Node data...
   echo Current wallet has:
   if [[ $used_net == "testnet" ]]; then
      bitcoin-cli -testnet getbalance
   else
   bitcoin-cli getbalance
   fi
}

mk_json_obj(){
   pairs=""
   for((i = 1; i<=$#; i+=2))
   do
     [ -z "$pairs" ] || pairs+=","
     pairs+="$(eval echo \'\"\'\$$i\'\"\':\'\"\'\$$(($i + 1))\'\"\')"
   done
   echo "{$pairs}"
}

mk_json_lst(){
   items=""
   for(( i = 1; i <= ${#addr_arr[@]}; i++))
   do
     [ -z "$items" ] || items+=","
     items+="$(eval echo \'\"\'${addr_arr[$i-1]}\'\"\')"
   done
   echo "[$items]"
}

eval_send_amount(){
   btc_dec=$(bitcoin-cli -testnet getbalance)
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

# ====== Main script starts here ======
LC_NUMERIC=C

process_args "$@"
while :
do
   main_menu "$used_net"
   process_menu_option
done
