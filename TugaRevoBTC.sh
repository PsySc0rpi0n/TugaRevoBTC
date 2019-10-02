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

# ------ Internal Messages System ------ #
confirm_input(){
  echo Please confirm "$1" "$2". Type YES to confirm:
  read -r -p'> ' input
  if [[ $input != "YES" ]]; then
	 echo Action cancelled. "$input_type" not confirmed!
	 exit
  fi
}

# ------ Send BTC Paymento to a single Address ------ #
send_single_payment(){
  echo "Which address to send:"
  read -r -p '> ' address
  input_type="address"
  confirm_input "$input_type" "$address"
  echo "How much BTC to send:"
  read -r -p '> ' amount
  input_type="amount"
  confirm_input "$input_type" "$amount"
  echo Sending "$amount" "BTC" to "$address"
  if [[ $used_net == "testnet" ]]; then
    bitcoin-cli -testnet sendtoaddress "$address" "$amount" false
  else
    bitcoin-cli sendtoaddress "$address" "$amount" false
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

# ====== Main script starts here ======
LC_NUMERIC=C

process_args "$@"
while :
do
  main_menu "$used_net"
  process_menu_option
done
