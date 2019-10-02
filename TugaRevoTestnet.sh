#! /bin/bash

trap '' 2 # ignore ctrl+c

help_menu(){
  echo "Usage: $0 [-testnet|-mainnet]"
}

main_menu() {
   while true
      do
         #clear # Clear screen for each loop of menu
         echo "============="
         if [[ $1 == "-testnet" ]]; then
           echo "Menu --- Testnet"
         else
           echo "Menu --- Mainnet"
         fi
         echo "============="
         echo "[1] Send BTC to single address"
         echo "[2] Send BTC to multiple addresses"
         echo "[3] Check Balance"
         echo "[4] Check transaction details"
         echo "[0] Exit"
         echo -e "Enter an option <return>"
         read -r -p '> '  answer # Create variable to hold option

         case "$answer" in
            1) send_single_BTC "$address"
               ;;
            2) send_many
               ;;
            3) check_balance
               ;;
            4) echo "Checking TxID details..."
               ;;
            0) echo "Exiting..."
               exit
               ;;
         esac
         echo -e "Hit <return> to continue"
         read -r input
      done
}

send_single_BTC(){
   echo "Which address to send:"
   read -r -p '> ' address
   input_type="address"
   confirm_input "$input_type" "$address"
   echo "How much BTC to send:"
   read -r -p '> ' amount
   input_type="amount"
   confirm_input "$input_type" "$amount"
   echo Sending "$amount" "BTC" to "$address"
   bitcoin-cli -testnet sendtoaddress "$address" "$amount" false
   echo "Transaction complete"
}

check_balance(){
   echo Checking Full Node data...
   echo Current wallet has:
   bitcoin-cli -testnet getbalance
}

confirm_input(){
   echo Please confirm "$1" "$2". Type YES to confirm:
   read -r -p'> ' input
   if [ "$input" != "YES" ]; then
      echo Action cancelled. "$input_type" not confirmed!
      exit
   fi
}

load_addr_data(){
   declare -ag addr_arr

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

send_many(){
  load_addr_data
  eval_send_amount
  mk_json_object_one_val "$btc_amount_dec" "${addr_arr[@]}"
  mk_json_lst_one_val "${addr_arr[@]}"
  bitcoin-cli -testnet sendmany "" {$pairs} 6 Payments [$items] true 6 CONSERVATIVE
  echo "TxID: $1"
}

LC_NUMERIC=C
if [ $# -lt 1 ]; then
  help_menu
  exit
fi
main_menu
