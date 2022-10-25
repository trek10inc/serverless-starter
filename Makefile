MAKEFLAGS=--warn-undefined-variables

APPLICATION_NAME ?= serverless-starter
STACK_NAME ?= ${APPLICATION_NAME}-${ENVIRONMENT_NAME}
CHANGE_SET_NAME ?= "release"
AWS_REGION ?= us-east-1
TEST_ARGS ?=

node_modules: package-lock.json
	npm ci
	touch node_modules
src/node_modules: src/package-lock.json
	cd src && npm ci
	# touch src/node_modules

src/openapi.packaged.json: templates/api.yml
	whoami
	cat ./templates/api.yml | yq .Resources.Api.Properties.DefinitionBody > src/openapi.packaged.json

artifacts/dist.zip: $(shell find ./src -name '*.js') node_modules src/node_modules src/openapi.packaged.json
	mkdir -p artifacts
	rm -rf artifacts/dist.zip
	find ./src/* -exec touch -h -t 200101010000 {} +
	cd src && zip -r -D -9 -y --compression-method deflate -X -x @../package-exclusions.txt @ ../artifacts/dist.zip * | grep -v 'node_modules'
	@echo "zip file MD5: $$(cat artifacts/dist.zip | openssl dgst -md5)"

artifacts/template.packaged.yml: templates/main.yml artifacts/dist.zip
	mkdir -p artifacts
	sam package \
		--template-file templates/main.yml \
		--s3-bucket "${ARTIFACT_BUCKET}" \
		--s3-prefix "${ARTIFACT_PREFIX}" \
		--output-template-file artifacts/template.packaged.yml
	touch artifacts/template.packaged.yml


### PHONY dependencies
.PHONY: dependencies lint-cfn lint-code lint build test coverage debug package create-change-set deploy-change-set integration-test openapi-server clean

dependencies: node_modules src/node_modules
	pip install -r requirements.txt

lint: node_modules src/node_modules
	./node_modules/.bin/eslint . --max-warnings=0
	cfn-lint

build: artifacts/dist.zip

test: src/openapi.packaged.json
	./node_modules/.bin/env-cmd -f ./.env.test ./node_modules/.bin/mocha './src/{,!(node_modules)/**}/*.spec.js' ${TEST_ARGS}
coverage:
	./node_modules/.bin/nyc $(MAKE) test
debug:
	$(MAKE) test TEST_ARGS="--inspect-brk"

package: artifacts/template.packaged.yml

create-change-set:
	mkdir -p artifacts
	@echo "Deploying ${STACK_NAME} with changeset ${CHANGE_SET_NAME}"
	aws cloudformation create-change-set \
		--stack-name ${STACK_NAME} \
		--template-body file://artifacts/template.packaged.yml \
		--parameters \
			ParameterKey=ApplicationName,ParameterValue='"${APPLICATION_NAME}"' \
			ParameterKey=EnvironmentName,ParameterValue='"${ENVIRONMENT_NAME}"' \
		--tags \
			Key=ApplicationName,Value=${APPLICATION_NAME} \
			Key=EnvironmentName,Value=${ENVIRONMENT_NAME} \
		--capabilities CAPABILITY_AUTO_EXPAND CAPABILITY_NAMED_IAM CAPABILITY_IAM \
		--change-set-name "${CHANGE_SET_NAME}" \
		--description "${CHANGE_SET_DESCRIPTION}" \
		--include-nested-stacks \
		--change-set-type $$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} > /dev/null && echo "UPDATE" || echo "CREATE")
	@echo "Waiting for change set to be created..."
	@CHANGE_SET_STATUS=None; \
	while [[ "$$CHANGE_SET_STATUS" != "CREATE_COMPLETE" && "$$CHANGE_SET_STATUS" != "FAILED" ]]; do \
		CHANGE_SET_STATUS=$$(aws cloudformation describe-change-set --stack-name ${STACK_NAME} --change-set-name ${CHANGE_SET_NAME} --output text --query 'Status'); \
	done; \
	aws cloudformation describe-change-set --stack-name ${STACK_NAME} --change-set-name ${CHANGE_SET_NAME} > artifacts/${STACK_NAME}-${CHANGE_SET_NAME}.json; \
	if [[ "$$CHANGE_SET_STATUS" == "FAILED" ]]; then \
		CHANGE_SET_STATUS_REASON=$$(aws cloudformation describe-change-set --stack-name ${STACK_NAME} --change-set-name ${CHANGE_SET_NAME} --output text --query 'StatusReason'); \
		if [[ "$$CHANGE_SET_STATUS_REASON" == "The submitted information didn't contain changes. Submit different information to create a change set." ]]; then \
			echo "ChangeSet contains no changes."; \
		else \
			echo "Change set failed to create."; \
			exit 1; \
		fi; \
	fi;
	@echo "Change set ${STACK_NAME} - ${CHANGE_SET_NAME} created."

deploy-change-set: node_modules
	CHANGE_SET_STATUS=$$(aws cloudformation describe-change-set --stack-name ${STACK_NAME} --change-set-name ${CHANGE_SET_NAME} --output text --query 'Status'); \
	if [[ "$$CHANGE_SET_STATUS" == "FAILED" ]]; then \
		CHANGE_SET_STATUS_REASON=$$(aws cloudformation describe-change-set --stack-name ${STACK_NAME} --change-set-name ${CHANGE_SET_NAME} --output text --query 'StatusReason'); \
		echo "$$CHANGE_SET_STATUS_REASON"; \
		if [[ "$$CHANGE_SET_STATUS_REASON" == "The submitted information didn't contain changes. Submit different information to create a change set." ]]; then \
			echo "ChangeSet contains no changes."; \
		else \
			echo "Change set failed to create."; \
			exit 1; \
		fi; \
	else \
		aws cloudformation execute-change-set \
			--stack-name ${STACK_NAME} \
			--change-set-name ${CHANGE_SET_NAME}; \
	fi;
	./node_modules/.bin/cfn-event-tailer ${STACK_NAME}

integration-test: node_modules
	export API_ENDPOINT=$$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" --output text); \
	./node_modules/.bin/env-cmd -f ./.env.integration.test ./node_modules/.bin/mocha --timeout 6000 './integration-tests/{,!(node_modules)/**}/*.test.js'

openapi-server:
	live-server openapi &
	nodemon --watch ./templates/api.yml --exec 'yq .Resources.Api.Properties.DefinitionBody < ./templates/api.yml > openapi/openapi.packaged.json'

clean:
	rm -rf .nyc_output
	rm -rf artifacts
	rm -rf coverage
	rm -rf node_modules
	rm -rf src/node_modules
	rm -rf src/openapi.packaged.json
	rm -rf openapi/openapi.packaged.json
