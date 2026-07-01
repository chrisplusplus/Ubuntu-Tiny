default:
	docker build -t ghostplant/flashback:24.04 -f Dockerfile.2404 --network=host .
	docker run -it --rm --privileged -p 8443:8443 -p 5901:5901 -v /external:/root ghostplant/flashback:24.04 || true
