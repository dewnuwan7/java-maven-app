

pipeline {
 agent any

 tools{
    maven 'maven-3.9.13'
 }

 stages{
    stage("init"){
        steps{
            script{
                echo "Initializing"
                echo "Incrementing Version.."

                sh "mvn build-helper:parse-version versions:set-DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} versions:commit"
                def matcher = readFile('pom.xml') =~ '<version>(.+)</version>'
                def version = matcher[0][1]
                env.IMAGE_NAME = "$version-${BUILD_NUMBER}"
            }
        }
    }

    stage("Build Project"){
        steps{
            script{
                sh 'mvn clean package'
            }
        }
    }

    stage("Build Docker"){
        steps{
            script{
                sh "docker build -t jma-${IMAGE_NAME} ."
            }
        }
    }

    stage("Publish"){
        steps{
            script{
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    echo $PASSWORD | docker login -u $USERNAME --password-stdin
                    sh "docker push jma-${IMAGE_NAME}"
                    sh "docker rmi jma-${IMAGE_NAME}"
                }
            }
        }
    }

    stage("Deploy"){
        steps{
            script{
                echo 'Deploying to remote VM'
            }
        }
    }

    stage("Commit Version"){
        steps{
            echo 'commiting to git'
        }
    }



 }

}