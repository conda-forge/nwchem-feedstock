
#!/bin/bash

echo " " >> $PREFIX/.messages.txt
echo "Before starting to use nwchem please deactivate and activate your environment again." >> $PREFIX/.messages.txt
echo "This will correctly populate the NWCHEM_BASIS_LIBRARY and NWCHEM_NWPW_LIBRARY environment variables." >> $PREFIX/.messages.txt
echo "For a more extensive configuration, copy the $PREFIX/etc/default.nwchemrc file to ~/.nwchemrc." >> $PREFIX/.messages.txt
