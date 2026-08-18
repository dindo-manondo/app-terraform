// App Terraform - demo Infrastructure-as-Code pipeline that provisions a
// single S3 bucket in a real AWS account using Terraform. This does NOT
// use jenkins-shared-library's standardPipeline() - that pipeline is built
// around Sonar -> Build -> Containerize -> Push to Nexus -> Deploy for
// application code, which doesn't map onto Terraform's own lifecycle
// (init -> validate -> plan -> apply). Instead this is a small, standalone
// declarative pipeline with IaC-appropriate stages.
//
// Safety gating: 'terraform apply' only runs on the 'main' branch. Every
// other branch runs init/validate/plan only, so opening a PR / pushing a
// feature branch can never touch real AWS resources - only merging to
// main can. This mirrors the spirit of standardPipeline's envMap/
// defaultEnv branch gating used by the other apps in this org, just
// simplified to a single environment since there's only one bucket.
//
// Credentials: uses the existing Jenkins credential 'aws-cred' (kind "AWS
// Credentials", from the AWS Credentials plugin). The
// AmazonWebServicesCredentialsBinding class exports AWS_ACCESS_KEY_ID /
// AWS_SECRET_ACCESS_KEY (and AWS_SESSION_TOKEN, if the credential has one)
// as env vars for the duration of each AWS-calling stage, which Terraform's
// AWS provider and the AWS CLI both read automatically.
//
// State: local backend (terraform.tfstate in the Jenkins workspace - see
// main.tf for why). Destroying the bucket, if ever needed, is a manual
// 'terraform destroy' run from this same workspace - intentionally not
// wired into the pipeline, since an automatic destroy trigger is exactly
// the kind of thing that should require a human to run on purpose.

pipeline {
    agent { label 'local-agent-1' }

    options {
        timestamps()
        timeout(time: 20, unit: 'MINUTES')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Resolve Environment') {
            steps {
                script {
                    def envMap = [
                        'main': 'prod',
                        'release/*': 'staging',
                        'develop': 'dev'
                    ]
                    env.DEPLOY_ENV = envMap[env.BRANCH_NAME] ?: 'dev'
                    echo "Branch '${env.BRANCH_NAME}' -> environment '${env.DEPLOY_ENV}'"
                }
            }
        }

        stage('Terraform Init') {
            steps {
                bat 'terraform init -input=false'
            }
        }

        stage('Terraform Validate') {
            steps {
                bat 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-cred']]) {
                    bat "terraform plan -input=false -var=\"environment=${env.DEPLOY_ENV}\" -out=tfplan"
                }
            }
        }

        stage('Terraform Apply') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-cred']]) {
                    bat 'terraform apply -input=false -auto-approve tfplan'
                    bat 'terraform output'
                }
            }
        }
    }

    post {
        success {
            echo "app-terraform: pipeline completed successfully."
        }
        failure {
            echo "app-terraform: pipeline FAILED - check console output above."
        }
    }
}
