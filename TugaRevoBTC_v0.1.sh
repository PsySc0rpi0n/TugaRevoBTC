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
   echo "[4] - Check TxID Details"
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
   read -r -p'> ' input
   if [[ $input != "YES" ]]; then
      return 1
   fi
   return 0
}

send_many(){
   load_addr_data
   eval_send_amount
   mk_json_object_one_val "$btc_amount_dec" "${addr_arr[@]}"
   mk_json_lst_one_val "${addr_arr[@]}"
   if [[ $used_net == "testnet" ]]; then
      output=$(bitcoin-cli -testnet sendmany "" {$pairs} 6 Payments [$items] true 6 CONSERVATIVE)
   else
      output=$(bitcoin-cli sendmany "" {pairs} 6 Payments [$items] true 6 CONSERVATIVE)
   fi
   echo "Transaction complete"
   echo "TxID: $output"
}

# ------ Send BTC Paymento to a single Address ------ #
send_single_payment(){
   local amount
   local ret
   echo "Which address to send:"
   read -r -p '> ' address
   echo "Please confirm address: "$address". Type YES to confirm (case sensitive):"
   confirm_input
   if [[ $? == 0 ]]; then
      echo "How much BTC to send:"
      read -r -p '> ' amount
      echo "Please confirm amount to send: $amount BTC. Type YES to confirm (case sensitive):"
      confirm_input
      if [[ $? == 0 ]]; then
         echo Sending "$amount" "BTC" to "$address"
         if [[ $used_net == "testnet" ]]; then
            bitcoin-cli -testnet sendtoaddress "$address" "$amount" false
         else
            bitcoin-cli sendtoaddress "$address" "$amount" false
         fi
         echo "Transaction complete"
         return 0
      else
         echo Action cancelled. Amount $amount BTC not confirmed!
         return 1
      fi
   else
      echo Action cancelled. Address $address not confirmed!
      return 1
   fi
}

# ------ Check loaded wallet balance ------ #
check_balance(){
   echo "used_net: $used_net"
   echo Checking Full Node data...
   echo Current wallet has:
   if [[ $used_net == "testnet" ]]; then
      bitcoin-cli -testnet getbalance "*" 1 true
   else
      bitcoin-cli getbalance "*" 1 true
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

# ====== Check TxID details ====== #
check_txid(){
   local txid
   local txidlen=64
   local strlen
   echo "Enter transaction ID:"
   read -p '> ' txid
   strlen=${#txid}
   while [[ -z $txid || $strlen -ne $txidlen ]]
   do
      echo "TxID not valid. Please enter a valid one or <Enter> to cancel: "
      read -p '> ' txid
      strlen=${#txid}
      if [[ -z $txid ]]; then
         echo "Cancelled"
         return 1
      fi
   done
   if [[ $used_net == "testnet" ]]; then
      bitcoin-cli -testnet gettransaction $txid
   else
      bitcoin-cli gettransaction "$txid"
   fi
}

# ====== Main script starts here ======
LC_NUMERIC=C

process_args "$@"
while :
do
   main_menu "$used_net"
   process_menu_option
done
