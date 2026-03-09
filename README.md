# Java Maven CI/CD Pipeline with Jenkins & Docker

A complete CI/CD pipeline for a Java application using Maven, Jenkins, and Docker. This project demonstrates how to automate the process of building, packaging, and containerizing a Java application using Jenkins pipelines.
***

## Project Overview

This project implements a Continuous Integration and Continuous Deployment (CI/CD) workflow for a Java application. Using CI/CD automation ensures faster releases, consistent builds, and fewer manual deployment errors.

### Pipeline in Action

https://github.com/user-attachments/assets/e7cf40ce-2223-4b47-b458-e94aa7ce18f2

[![Watch the video](https://img.youtube.com/vi/1jv38kaBVOQ/0.jpg)](https://www.youtube.com/watch?v=1jv38kaBVOQ)

The pipeline automatically:

* Pulls source code from a repository

* Builds the project using Maven

* Packages the application as a .jar

* Builds a Docker image

* Deploys the container

## Architecture
<img width="1837" height="903" alt="java-maven-cicd-pipeline excalidraw (2)" src="https://github.com/user-attachments/assets/29a1cee5-e463-4913-8349-211c1154a6de" />


## Prerequisites

Make sure the following tools are installed:

* Java JDK 8+

* Maven

* Docker

* Jenkins

* Git

***

## Setup Instructions
1. Clone the Repository
```bash
git clone https://github.com/yourusername/java-maven-jenkins-docker-pipeline.git
cd java-maven-jenkins-docker-pipeline
```
2. Build the Application
Use Maven to compile and package the application. This generates a .jar file inside the target/ directory:
```bash
mvn clean package
```
3. Build and Run the Docker Image
Build the image:
```bash
docker build -t java-maven-app .
```
4. Run the container:
```bash
docker run -p 8080:8080 java-maven-app
```
***
## Jenkins Pipeline
The CI/CD pipeline is defined as code using a Jenkinsfile.

```groovy


pipeline {
 agent any

 tools{
    maven 'maven-3.9.13'
 }

 stages{

    stage('Checkout Version') {
                    steps {
                        checkout scm
                        scmSkip(deleteBuild: true, skipPattern:'.*\\[ci-skip\\].*')

                        script{

                            //Incrementing Version

                            sh "mvn build-helper:parse-version versions:set \
                            -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} versions:commit"
                            def matcher = readFile('pom.xml') =~ '<version>(.+)</version>'
                            def version = matcher[1][1]
                            env.IMAGE_NAME = "$version-${BUILD_NUMBER}"
                            env.IMAGE_TAG= "dewnuwan/java-maven-app:jma-${IMAGE_NAME}"
                        }
                    }
                }

    stage("Build Project"){
        steps{
            script{

                sh 'mvn clean package'

               //commiting to git
                sh """
                   git config user.name "jenkins"
                   git config user.email "jenkins@thesudofiles.com"
                   git add .
                   git commit -m "[ci-skip] version bump"
                   """
                gitPush(gitScm: scm, targetBranch: 'master', targetRepo: 'origin')

            }
        }
    }

    stage("Test"){
        steps {
            script{
                sh 'mvn test'
            }
        }
    }


    stage("Build Image"){
        steps{
            script{
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh """
                        docker build --pull --cache-from ${IMAGE_TAG} -t ${IMAGE_TAG} .
                        echo $PASSWORD | docker login -u $USERNAME --password-stdin
                        docker push ${IMAGE_TAG}
                        docker rmi ${IMAGE_TAG}
                       """
                }

            }
        }
    }


    stage("Deploy"){
        steps{
            echo 'Deploying to remote server..'
            sshPublisher(publishers: [sshPublisherDesc(configName: 'prod-server', transfers: [sshTransfer(cleanRemote: false, excludes: '', execCommand: """docker stop java-maven-app
            docker rm java-maven-app
            docker images dewnuwan/java-maven-app --format "{{.ID}}" | tail -n +2 | xargs -r docker rmi
            docker run -d -p 8080:8080 --name java-maven-app ${IMAGE_TAG}""", execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+',
            remoteDirectory: '', remoteDirectorySDF: false, removePrefix: '', sourceFiles: '')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
        }
    }

 }

    post {

        success {
            slackSend(
                channel: '#ci-cd',
                color: 'good',
                message: """
:white_check_mark: *BUILD SUCCESS*

*Job:* ${env.JOB_NAME}
*Build:* #${env.BUILD_NUMBER}
*Branch:* ${env.BRANCH_NAME}
*Docker Image:* ${env.IMAGE_TAG}
*Duration:* ${currentBuild.durationString}

*Deployment:* <http://168.144.23.78:8080|Open Application>

*Build Logs:* ${env.BUILD_URL}
"""
            )
        }

        failure {
            slackSend(
                channel: '#ci-cd',
                color: 'danger',
                message: """
:x: *BUILD FAILED*

*Job:* ${env.JOB_NAME}
*Build:* #${env.BUILD_NUMBER}
*Branch:* ${env.BRANCH_NAME}

Check logs:
${env.BUILD_URL}
"""
            )
        }

        unstable {
            slackSend(
                channel: '#ci-cd',
                color: 'warning',
                message: """
:warning: *BUILD UNSTABLE*

*Job:* ${env.JOB_NAME}
*Build:* #${env.BUILD_NUMBER}
*Branch:* ${env.BRANCH_NAME}

Review test results:
${env.BUILD_URL}
"""
            )
        }
    }

}


```
***
## Pipeline Workflow
The Jenkins pipeline executes the following stages:

* Code Checkout: Jenkins pulls the latest code from the repository.

* Build: Maven compiles the Java source code.

* Test: Unit tests are executed to validate the build.

* Package: The project is packaged into a .jar artifact.

* Docker Build: A Docker image is built containing the application.

* Deployment: The container is started using the newly built image.

***

## Benefits of This Setup
* Automated builds

* Faster deployments

* Consistent runtime environment

* Reduced manual errors

* Easy scaling with containerization
