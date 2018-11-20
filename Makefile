DCR = docker-compose run --rm
DCB = docker-compose build

tf-%:
	rm -rf ./EC2/tf/stg/.terraform
	$(DCB) tf-$(*)
	$(DCR) tf-$(*) init
	$(DCR) tf-$(*) plan
