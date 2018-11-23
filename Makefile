DCR = docker-compose run --rm
DCB = docker-compose build

tf-%:
	$(DCB) tf-$(*)
	$(DCR) tf-$(*) init
	$(DCR) tf-$(*) plan
	$(DCR) tf-$(*) plan -refresh=true -target=main.tf
	$(DCR) tf-$(*) plan -refresh=true -target=vpc.tf
	$(DCR) tf-$(*) plan -refresh=true -target=bastion.tf
