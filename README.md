# Serverless Starter

## Why?

This project serves as a reference, serverless application using AWS services:
- API Gateway
    - with endpoint authentication via Lambda Authorizer
    - with an OpenAPI specification made publicly available
- CloudFront (for caching the frontend API)
- Lambda
- DynamoDB
- NuxtJS frontend
- SAM/CloudFormation IaC
- CI/CD

## Project Layout

- `integration-tests/` - this contains post-deploy integration tests written in NodeJS.
- `templates/` - this directory contains the CloudFormation IaC that will be used to define the application. It's designed in a nested stack manner, with the `templates/main.yml` being the parent stack and everything else nested underneath it.
- `src/node/` - this is the root directory for all lambda handlers written in NodeJS.
- `src/python/` - this is the root directory for all lambda handlers written in Python.
- `src/frontend/` - this is the root directory for the frontend code
- `load-tests/` - this directory contains [Artillery](https://www.artillery.io/) scripts and configuration to run load tests against the application
- `openapi/` - this directory contains assets that can be used to render the OpenAPI editor, useful to view and validate your OpenAPI documentation.

## Frontend

The frontend is designed with Server Side Rendering (SSR) in mind. This is using the NuxtJS framework to handle rendering the application. The compute that handles the rendering is AWS Lambda, sitting behind API Gateway.

## Backend

The backend includes examples of serverless functions using both NodeJS and Python runtimes:
- `src/node/`
- `src/python/`

Most of this project is written in NodeJS. A Python `Hello, world` Lambda is provided for reference.

## CI/CD

Makefiles are used throughout the project to handle defining various development workflow commands that need to be run throughout CI/CD. This includes running unit tests, building code, deployment, and integration tests.

The following "CI/CD" entrypoints are defined:

- `unit-test` - iterate through every `src/` directory running tests for each application code component (frontend, backend node, and backend python). Each `src/` directory defines its own `Makefile` with a `test` target to prepare and run tests for that given code
- `build` - iterate through every `src/` directory, performing any required build steps of that code (frontend, backend node, and backend python). Each `src/` directory defines its own `Makefile` with a `build` target to build code. Afterwards, the root `Makefile` will run `sam build` on the `templates/main.yml` file. Finally, it will run `sam package` on the built directory from `sam build`, uploading all code to the S3 bucket specified by the `S3_BUCKET` variable. An `artifacts/main.packaged.yml` will be produced that
- `deploy` - deploys the produced `artifacts/main.packaged.yml` file.
- `integration-test` - iterate through `*.test.js` integration test files in the `integration-tests/` directory.

CI/CD will depend on the following variables:

- `APPLICATION_NAME` - the name of the application you're deploying
- `ENVIRONMENT_NAME` - the name of the environment you're deploying to
- `S3_BUCKET` - the name of the bucket you'd like to upload code artifacts to
- `DEVOPS_ACCOUNT_ID` - the AWS account ID that contains the artifact bucket
- `DEV_ACCOUNT_ID` - the AWS account ID that should receive the dev environment
- `QA_ACCOUNT_ID` - the AWS account ID that should receive the QA environment
- `PROD_ACCOUNT_ID` - the AWS account ID that should receive the production environment

AWS IAM access is handled via IAM roles. This uses the `aws-actions/configure-aws-credentials` action to get credentials from an OIDC provider. To learn more about that, check out [this article](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services).

## IaC

The `templates/` directory contains SAM/CloudFormation templates which define cloud resources. A root stack is defined in `templates/main.yml`, which houses multiple, nested stacks.

Requisite variable inputs are provided via the Makefile. When triggered via CI/CD, these variable inputs are already configured. When triggering locally, you will be required to pass the `-e` flag to certain `make` commands:
- `ENVIRONMENT_NAME`

This project:
- Uses SAM, the [AWS Servesless Applicaiton Model](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html). SAM abstracts and simplifies the creation of serverless toolsets, as defined in `templates/*.yml` files.
- Stubs out a custom Lambda Authorizer function, which will need further developed to integrate with your IdP
- Explicitly defines an OpenAPI spec and makes that spec publicly available via the `/docs` endpoint
