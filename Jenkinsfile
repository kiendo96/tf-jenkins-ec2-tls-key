pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1' // Hoặc region của bạn
        TF_DIR = 'terraform'
        WEBSITE_DIR = 'website'
        SSH_USER = 'ec2-user' // Username SSH cho Amazon Linux 2 AMI
        // SSH_USER = 'ubuntu' // Nếu dùng Ubuntu
        SSH_CREDENTIAL_ID = 'jenkins-ssh-key-tf'
    }

    tools {
        terraform 'terraform-latest'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                echo "Initializing Terraform in ${env.TF_DIR}..."
                dir("${env.TF_DIR}") {
                    withCredentials([aws(credentialsId: 'aws-credentials')]) {
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                echo 'Validating Terraform code...'
                dir("${env.TF_DIR}") {
                    sh "terraform validate"
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                echo 'Creating Terraform execution plan...'
                dir("${env.TF_DIR}") {
                    withCredentials([aws(credentialsId: 'aws-credentials')]) {
                        sh "terraform plan -out=tfplan"
                    }
                }
                archiveArtifacts artifacts: "${env.TF_DIR}/tfplan"
            }
        }

        stage('Terraform Apply') {
            steps {
                echo 'Applying Terraform plan...'
                dir("${env.TF_DIR}") {
                    withCredentials([aws(credentialsId: 'aws-credentials')]) {
                        sh "terraform apply -auto-approve tfplan"
                    }
                }
            }
        }

        stage('Get Outputs & Private Key') {
            steps {
                dir("${env.TF_DIR}") {
                    withCredentials([aws(credentialsId: 'aws-credentials')]) {
                        sh 'terraform output -raw instance_public_ip > ../instance_ip.txt'
                        sh 'terraform output -raw website_url > ../website_url.txt'
                        sh 'terraform output -raw private_key_pem > ../private_key.pem'

                        script {
                            env.INSTANCE_IP = readFile('../instance_ip.txt').trim()
                            env.WEBSITE_URL = readFile('../website_url.txt').trim()

                            echo "-----------------------------------------------------"
                            echo "!!! ACTION REQUIRED !!!"
                            echo "Terraform has generated an SSH private key."
                            echo "You MUST copy the private key output from the 'private_key.pem' artifact"
                            echo "or from the 'Terraform Apply' stage logs (if not masked)"
                            echo "and add it to Jenkins Credentials with ID: ${env.SSH_CREDENTIAL_ID}"
                            echo "Username for the key should be: ${env.SSH_USER}"
                            echo "Rerun the pipeline AFTER adding the credential for deployment to work."
                            echo "EC2 Instance Public IP: ${env.INSTANCE_IP}"
                            echo "Website URL: ${env.WEBSITE_URL}"
                            echo "-----------------------------------------------------"
                            archiveArtifacts artifacts: 'instance_ip.txt, website_url.txt, private_key.pem'
                        }
                    }
                }
            }
        }

        stage('Deploy Website to EC2') {
            steps {
                script {
                    if (env.INSTANCE_IP == null || env.INSTANCE_IP.isEmpty()) {
                        error "EC2 instance IP not found. Check previous stage outputs."
                    }

                    try {
                        withCredentials([sshUserPrivateKey(credentialsId: env.SSH_CREDENTIAL_ID, keyFileVariable: 'SSH_KEY_FILE')]) {
                            echo "SSH Credential '${env.SSH_CREDENTIAL_ID}' found. Proceeding with deployment."
                        }
                    } catch (Exception e) {
                        error """
                        SSH Credential with ID '${env.SSH_CREDENTIAL_ID}' not found or configured incorrectly in Jenkins.
                        Please follow the instructions from the 'Get Outputs & Private Key' stage to add the generated private key.
                        Then, rerun the pipeline.
                        """
                    }
                }

                echo "Deploying ${env.WEBSITE_DIR}/index.html to EC2 instance ${env.INSTANCE_IP}..."
                sshagent(credentials: [env.SSH_CREDENTIAL_ID]) {
                    sh """
                        scp -o StrictHostKeyChecking=no \
                            -o UserKnownHostsFile=/dev/null \
                            ${env.WEBSITE_DIR}/index.html \
                            ${env.SSH_USER}@${env.INSTANCE_IP}:/var/www/html/index.html
                    """
                    echo "Website files copied successfully!"
                }
                echo "Website deployed! Access at: ${env.WEBSITE_URL}"
            }
        }
    } // End stages

    post {
        always {
            echo 'Pipeline finished.'
            // Clean up specific output files, giữ lại logs nếu cần
            sh 'rm -f instance_ip.txt website_url.txt private_key.pem'
        }
        success {
            echo "Pipeline successful! Access website at ${env.WEBSITE_URL}"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}