pipeline {
    agent any         

    stages {

        stage ('Initialization') {
            agent any

            steps {
                script {

                    withAWS(profile: 'nmettu', region: 'us-east-1') {
                        s3Download(file: 'att-dp-static.properties', bucket: 'att-dp-static-files-for-jenkins' , path: 'att-dp-static.properties' , force: true)
                    }

                    def properties = readProperties file: "att-dp-static.properties"
                    env['GIT_VERSION_TAG'] = ""
                    env['NAME'] = JOB_NAME
                    env['AWS_ACCOUNT_ID'] = properties['DEV_ACCOUNT_ID']
                    env['DKR_REGION'] = properties['DEV_DKR_REGION']
                    env['DOCKER_IMAGE'] = ""
                    env['ECR_IMAGE_TAG'] = ""
                    //env['BUILD_SUCCESS_CODE'] = ""
                }
            }

        }
        
        stage('Git Version') {
            agent any

            steps {
                script {
                    env['GIT_VERSION_TAG'] = GIT_BRANCH +"-"+ GIT_COMMIT
                    
                    sh "echo ${env.GIT_VERSION_TAG} > git_branch"

                    GIT_VERSION = sh(
                        returnStdout: true,
                        script:"""
                            cut -d "/" -f 2 git_branch
                        """
                    )
                    
                    println "GIT_VERSION : " + GIT_VERSION
                }
            }

        }

        stage ('Docker Build') {
            agent any

            steps {
                script {
                    env['DOCKER_IMAGE'] = NAME +":"+ GIT_VERSION
                    env['ECR_IMAGE_TAG'] = AWS_ACCOUNT_ID +".dkr.ecr."+ DKR_REGION +".amazonaws.com/"+ DOCKER_IMAGE
                    
                    sh """
                        docker build -t att-dp-static .
                        docker run -d -p 8910:8080 --name docker-test-static att-dp-static:latest
                    """
                }
            }

        }
        /*
        stage ('Docker Test') {
            agent any

            steps {
                script {

                    env['BUILD_SUCCESS_CODE'] = sh(
                        returnStdout: true,
                        script: "python status-code.py"
                    ).trim()
                    println "BUILD_SUCCESS_CODE is " + env.BUILD_SUCCESS_CODE

                    if ( BUILD_SUCCESS_CODE == '200'){
                        println "SUCCESS"
                    }
                    else {
                        println "FAILURE"
                        //env['BUILD_RESULT'] = ABORTED
                    }

                }
            }
            
            post { 
                always { 
                    sh """
                        docker rm -f docker-test-static
                    """
                }
                failure {
                    sh """
                        docker rmi att-dp-static
                    """
                }
            }
            
        }
        */
        stage('Docker Push') {
            agent any
            
            steps {
                script {

                    sh """
                        docker tag att-dp-static:latest ${env.ECR_IMAGE_TAG}
                    """

                    withAWS(profile:'nmettu', region:'us-east-1') {

                        sh """
                            echo "#!/bin/bash" > cmd.sh
                            echo ""
                            aws ecr get-login --no-include-email >> cmd.sh

                            chmod 700 cmd.sh

                            ./cmd.sh

                            docker push ${env.ECR_IMAGE_TAG}
                        """
                    }
                }
            }
            
            post { 
                always { 
                    sh """
                        docker rmi -f att-dp-static
                        docker rmi -f ${env.ECR_IMAGE_TAG}
                    """
                }
            }
            
        }
        
        stage ('Build Dir CleanUp') {
            agent any

            steps {
                script {
                    deleteDir()
                }
            }
        }
        
    }

}
