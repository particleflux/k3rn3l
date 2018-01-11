
install: k3rn3l.sh lib/utils.sh
	mkdir -p /opt/k3rn3l
	cp -r k3rn3l.sh lib /opt/k3rn3l/
	echo -e '#!/usr/bin/env bash\ncd /opt/k3rn3l\nexec ./k3rn3l.sh "$$@"' > /opt/bin/k3rn3l
	chmod +x /opt/bin/k3rn3l
