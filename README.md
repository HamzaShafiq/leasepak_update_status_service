# leasepak_update_status_service

Invoke “Status Transfer” LeasePak API to update status
==============
SOAP client for the [Status Transfer](https://github.com/HamzaShafiq/leasepak_update_status_service)

Uses the [Ruby](https://www.ruby-lang.org/en/)

If you have any issues, suggestions, improvements, etc. then please log them using GitHub issues.

## Requirements

* [ruby](https://www.ruby-lang.org/en/documentation/installation/) 


Usage
-----
Clone the [Status Transfer](https://github.com/HamzaShafiq/leasepak_update_status_service) Git repository and get it up and running

* Clone this Git repository
* Place Status Transfer data csv file under "/docs" directory
* Set configurations insiide "/config/config.yml"
  * get_status_wsdl: LeasePak GetStatusTransferData API WSDL URL
  * update_status_wsdl: LeasePak ApplicationStatusTransfer API WSDL URL
  * path_to_file = Path to the Status Transfer data csv file  

* On your bash run command: ruby update_status.rb


License
-------
The Status Transfer Client in Ruby is released under the MIT license.

Author
------
[HamzaShafiq](https://github.com/HamzaShafiq)

