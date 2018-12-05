DCR = docker-compose run --rm
DCB = docker-compose build

plan-%:
	$(DCB) tf-$(*)
	$(DCR) tf-$(*) init
	$(DCR) tf-$(*) plan

apply-%:
	$(DCB) tf-$(*)
	$(DCR) tf-$(*) apply
