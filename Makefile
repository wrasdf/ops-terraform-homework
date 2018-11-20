DCR = docker-compose run --rm
DCB = docker-compose build

tf-%:
	$(DCB) tf-$(*)
	$(DCR) tf-$(*) init
	$(DCR) tf-$(*) plan
