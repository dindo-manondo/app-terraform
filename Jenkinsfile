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
// main.tf for why).
//
// Teardown: destroying the bucket is deliberately NOT automatic. Set the
// DESTROY build parameter to true (and run on 'main') to tear it down -
// when DESTROY is true, every normal stage is skipped and only the
// 'Terraform Destroy' stage runs, so a teardown run never accidentally
// re-applies first. Leaving DESTROY at its default (false) keeps the
// pipeline behaving exactly as before.

pipeline {
    agent { label 'local-agent-1' }

    options {
        timestamps()
        timeout(time: 20, unit: 'MINUTES')
    }

    parameters {
        booleanParam(name: 'DESTROY', defaultValue: false, description: 'If true, skip the normal init/validate/plan/apply flow and run terraform destroy instead (main branch only).')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Resolve Environment') {
            when {
                expression { !params.DESTROY }
            }
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
            when {
                expression { !params.DESTROY }
            }
            steps {
                bat 'terraform init -input=false'
            }
        }

        stage('Terraform Validate') {
            when {
                expression { !params.DESTROY }
            }
            steps {
                bat 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            when {
                expression { !params.DESTROY }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-cred']]) {
                    bat "terraform plan -input=false -var=\"environment=${env.DEPLOY_ENV}\" -out=tfplan"
                }
            }
        }

        stage('Terraform Apply') {
            when {
                allOf {
                    branch 'main'
                    expression { !params.DESTROY }
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-cred']]) {
                    bat 'terraform apply -input=false -auto-approve tfplan'
                    bat 'terraform output'
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                allOf {
                    branch 'main'
                    expression { params.DESTROY }
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-cred']]) {
                    bat 'terraform init -input=false'
                    bat 'terraform destroy -input=false -auto-approve'
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
