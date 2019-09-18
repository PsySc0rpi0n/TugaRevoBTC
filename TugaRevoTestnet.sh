#! /bin/bash

trap '' 2 # ignore ctrl+c

main_menu() {
   while true
      do
         #clear # Clear screen for each loop of menu
         echo "============="
         echo "Menu --- Testnet"
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
               #send_to_mult_addr
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
   echo "Enter address to check balance:"
   read -r -p '> ' address
   input_type="address"
   confirm_input "$input_type" "$address"
   echo Checking Full Node data...
   echo Address "$address" balance is:
   bitcoin-cli -testnet getreceivedbyaddress "$address" 1
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

#send_to_mult_addr(){
#   load_addr_data
#
#   val=$(printf "%.9f" $(echo $(bitcoin-cli -testnet getbalance) / "$num_addr" | bc -l))
#
#   printf 'Value to send: %0.8f BTC\n' "$val"
#   while true
#   do
#       echo "Confirm with YES or cancel with NO (caps matter)"
#       read -r -p '> ' opt
#       case $opt in
#           "YES") count=0
#                  com_params="\"\" \"{"
#                  for i in "${addr_arr[@]}"
#                  do
#                     ((count++))
#                     com_params+="\\\"$i\\\""
#                     if [ "$count" -lt "$num_addr" ]; then
#                        com_params+=":$val,"
#                     else
#                        com_params+=":$val"
#                     fi
#                  done
#                  com_params+="}\" 6 \"Periodic payments\" \"["
#
#                  count=0
#                  for i in "${addr_arr[@]}"
#                  do
#                     ((count++))
#                     if [ "$count" -lt "$num_addr" ]; then
#                        com_params+="\\\"$i\\\","
#                     else
#                        com_params+="\\\"$i\\\"]\""
#                     fi
#                     done
#                     com_params+=" true 6 CONSERVATIVE"
#                     #echo "bitcoin-cli -testnet sendmany "$com_params""
#                     #bitcoin-cli -testnet sendmany $com_params
#                     echo $com_params > addrlst.dat
#                     printf 'TxID: %s\n' "$?"
#                     return 1
#                     ;;
#           "NO") echo "Action cancelled!"
#                 return 2
#                 ;;
#       esac
#   done
#}

send_many(){
  load_addr_data
  count=0
  backcptb='""'
  min_conf=6
  comm1="Periodic payments"
  replcbl=true
  conf_targ=6
  est_mde=CONSERVATIVE

  val=$(printf "%.9f" $(echo $(bitcoin-cli -testnet getbalance) / "$num_addr" | bc -l))
  printf "Value to send: %.8f BTC\n" "$val"

  obj_init="\""
  json_obj='{'
  for i in "${addr_arr[@]}"
  do
    ((count++))
    json_obj+="\"$i\""
    json_obj+=":"
    if [ "$count" -lt "$num_addr" ]; then
      json_obj+="$val,"
    else
      json_obj+="$val}"
    fi
  done
  obj_end+='"'
  json_final=$(echo $json_obj | jq '.')
  printf "bitcoin-cli -testnet sendmany  %s %s%s%s %d %s\n" "$backcptb" "$obj_init" "$json_final" "$obj_end" $min_conf "$comm1"
}

LC_NUMERIC=C
main_menu
