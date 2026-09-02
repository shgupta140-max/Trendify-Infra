pipeline {
    agent any

    tools {
        terraform 'Terraform'
    }

    environment {
        REGION = 'ap-south-1'
        CLUSTER_NAME = 'trendstore-cluster'
        SLACK_APPROVAL_CHANNEL = '#terraform-approvals'
        SLACK_NOTIFICATION_CHANNEL = '#trendify-notifications'
    }

    stages {
        stage('Terraform Init') {
            steps {
                echo "Initializing Terraform in region: ${env.REGION} for cluster: ${env.CLUSTER_NAME}"
                sh 'terraform init'
            }
        }

        stage('Terraform Format') {
            steps {
                echo "Formatting Terraform configuration in region: ${env.REGION} for cluster: ${env.CLUSTER_NAME}"
                sh 'terraform fmt'
            }
        }
        
        stage('Terraform Validate') {
            steps {
                echo "Validating Terraform configuration in region: ${env.REGION} for cluster: ${env.CLUSTER_NAME}"
                sh 'terraform validate'
            }
        }
        
        stage('Terraform Plan') {
            steps {
                echo "Planning Terraform changes in region: ${env.REGION} for cluster: ${env.CLUSTER_NAME}"
                sh 'terraform plan -out=tfplan'
            }
        }

        stage('Terraform Apply') {
            when {
                expression { return env.BRANCH_NAME == 'main' }
            }
            options {
                timeout(time: 1, unit: 'HOURS')
            }
            steps {
                slackSend(message: "*Action Required:* Pipeline is waiting for manual approval to deploy to Production.\nRunning Terraform Apply in region: ${env.REGION} for cluster: ${env.CLUSTER_NAME}. Please approve here - ${env.BUILD_URL}", 
                channel: "${env.SLACK_APPROVAL_CHANNEL}", 
                color: '#050505')
                
                input (
                    message: 'Do you want to apply the Terraform changes for cluster: ${env.CLUSTER_NAME} in region: ${env.REGION}?',
                    ok: 'Apply'
                )
                
                echo "Applying Terraform changes in region: ${env.REGION} for cluster: ${env.CLUSTER_NAME}"
                sh 'terraform apply tfplan'
                echo "Terraform changes applied successfully in region: ${env.REGION} for cluster: ${env.CLUSTER_NAME}"
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
            slackSend(channel: env.SLACK_NOTIFICATION_CHANNEL, color: 'good', message: "Pipeline completed successfully.\nJob: ${env.JOB_NAME}\nBuild Number: ${env.BUILD_NUMBER}\nBuild URL: ${env.BUILD_URL}")
        }
        
        failure {
            echo 'Pipeline failed.'
            slackSend(channel: env.SLACK_NOTIFICATION_CHANNEL, color: 'danger', message: "Pipeline failed.\nJob: ${env.JOB_NAME}\nBuild Number: ${env.BUILD_NUMBER}\nBuild URL: ${env.BUILD_URL}")
        }
    }
}
