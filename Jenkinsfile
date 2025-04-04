pipeline{
    agent any
    environment {
        AWS_REGION = 'us-east-1'
        TF_DIR = 'terraform'
        WEBSITE_DIR = 'website'
        SSH_USER = 'ec2-user'
        SSH_CREDENTIAL_ID = 'jenkins-ssh-key-tf'
    }
    tools {
        terraform 'terraform-latest'
    }
    stages{
        stage("Checkout"){
            steps{
                echo "========Checking out code from GitHub========"
                checkout scm
            }
        }
        stage('Terraform init') {
            steps {
                echo "Initializing Terraform in ${env.TF_DIR}..."
                dir("${env.TF_DIR}"){
                    withCredentials([aws(creadentialsId: 'aws-credentials')]){
                        sh "terraform init"
                    }
                }
            }
            
        }
        stage('Terraform Validate') {
            steps {
                echo 'Validate Terraform code..'
                dir("${env.TF_DIR}"){
                    sh "terraform validate"
                }
            }
        }
        stage('Terraform Init') {
            steps {
                echo "Initializing Terraform in ${env.TF_DIR}..."
                dir("${env.TF_DIR}") {
                    withCredentials([aws(credentialsId: 'aws-credentials')]) {
                        // AWS_* vars sẽ được inject tự động
                        // Sử dụng cấu hình backend từ file backend.tf
                        sh 'terraform init'
                        // Nếu không dùng backend.tf, bạn có thể cấu hình ở đây:
                        // sh '''
                        //    terraform init \
                        //    -backend-config="bucket=your-terraform-state-bucket-name" \
                        //    -backend-config="key=project/ec2-tls/terraform.tfstate" \
                        //    -backend-config="region=${AWS_REGION}" \
                        //    -backend-config="dynamodb_table=your-terraform-lock-table-name"
                        // '''
                    }
                }
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
                          // Lấy IP Public
                          sh 'terraform output -raw instance_public_ip > ../instance_ip.txt'
                          // Lấy URL Website
                          sh 'terraform output -raw website_url > ../website_url.txt'
                          // Lấy Private Key (SENSITIVE!)
                          sh 'terraform output -raw private_key_pem > ../private_key.pem'

                          script {
                             // Đọc các giá trị vào biến môi trường Jenkins
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
            // Stage này sẽ chỉ thành công SAU KHI user đã thêm private key vào Jenkins Credentials (Bước 8)
            steps {
                script {
                    // Kiểm tra IP trước khi tiếp tục
                    if (env.INSTANCE_IP == null || env.INSTANCE_IP.isEmpty()) {
                        error "EC2 instance IP not found. Check previous stage outputs."
                    }
                    // Kiểm tra xem credential đã tồn tại chưa (cách đơn giản)
                    // Lưu ý: cách kiểm tra này không hoàn hảo, chỉ dựa vào ID
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
                // Sử dụng SSH Agent Plugin với credential đã được user thêm vào
                sshagent(credentials: [env.SSH_CREDENTIAL_ID]) {
                    // Lệnh scp để copy file
                    sh """
                        scp -o StrictHostKeyChecking=no \
                            -o UserKnownHostsFile=/dev/null \
                            ${env.WEBSITE_DIR}/index.html \
                            ${env.SSH_USER}@${env.INSTANCE_IP}:/var/www/html/index.html
                    """
                     // UserKnownHostsFile=/dev/null cũng bỏ qua kiểm tra host key, không an toàn cho production.
                    echo "Website files copied successfully!"
                }
                echo "Website deployed! Access at: ${env.WEBSITE_URL}"
            }
        }
    }
    post {
        always {
            echo 'Pipeline finished.'
            // Clean up files in workspace
            deleteDir() // Xóa toàn bộ workspace để dọn dẹp, bao gồm cả key đã output
            // Hoặc xóa file cụ thể: sh 'rm -f instance_ip.txt website_url.txt private_key.pem'
        }
         success {
              echo "Pipeline successful! Access website at ${env.WEBSITE_URL}"
         }
         failure {
              echo "Pipeline failed!"
         }
    }
}