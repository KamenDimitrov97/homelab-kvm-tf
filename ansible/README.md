# Testing 

ansible -i inventory.ini cp1 -b -m shell -a 'for h in cp1 cp2 cp3 w1 w2 storage1; do ping -c1 -W1 $h || exit 1; done'

