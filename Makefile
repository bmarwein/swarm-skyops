SCRIPTS=./scripts

deploy:
	$(SCRIPTS)/deploy.sh

deploy-%:
	$(SCRIPTS)/deploy.sh stacks/$*.yml

redeploy:
	$(SCRIPTS)/redeploy_all.sh

secrets:
	$(SCRIPTS)/create_secrets.sh

secrets-rotate:
	FORCE=true $(SCRIPTS)/create_secrets.sh

images-export:
	OUT_DIR=./backups $(SCRIPTS)/export-images.sh

images-import:
	$(SCRIPTS)/import-images.sh $(ARCHIVE)

backup:
	$(SCRIPTS)/backup.sh

restore:
	$(SCRIPTS)/restore.sh $(SRC)