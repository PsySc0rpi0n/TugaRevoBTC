TugaRevoBTC

TugaRevoBTC is a simple script to perform automatic payments of BTC to a single address or a group of addresses.
It can be handy when running projects of Cloud Minning where you need to send payments to your clients.

Getting Started
- Download the script from Github as usual

Prerequisites
- bitcoin core binaries. Download them from your distro repositories. This script uses only commands of bitcoin core when it comes to process payments.
- bash. This was (and still is) developed using bash interpreter.

Give examples
- Two versions are available. An automated script where minimal user intervention is required and another version based in menus
that can be chosen by the user.
- Automated version can run in testnet or mainnet. It only requires two switches and one parameter when launched (only multi addresses payments are available):
   - Automated version examples:
      - ./autotugarevobtc.sh -t -a file_path.dat
      - ./autotugarevobtc.sh -m -a file_path.dat
      where [-m|--mainnet]  and [-t|--mainnet] allow mainnet or testnet networks and [-a|--address] is to specify the file where addresses are stored (to process multi address payments)

   - Manual version
      - ./TugaRevoBTC -t
      - ./TugaRevoBTC -m
      Same as automated version but here the addresses file is not given when script is launched because this version allows for single address payment to be issued. If you need multi address
      payment, the menu will ask you for the addresses file.

Built With
VIM - Vi IMproved 8.0 (2016 Sep 12, compiled Jun 21 2019 04:10:35)

Versioning
No fancy versioning system. Just used v.01

Authors
PsySc0rpi0n - JCOFerreira

License
This project is licensed under the GNU GENERAL PUBLIC LICENSE - see the LICENSE.md file for details
