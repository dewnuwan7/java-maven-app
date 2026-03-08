

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

                sh "mvn build-helper:parse-version versions:set \
                -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} versions:commit"
                def matcher = readFile('pom.xml') =~ '<version>(.+)</version>'
                def version = matcher[0][0]
                env.IMAGE_NAME = "$version-${BUILD_NUMBER}"
            }
        }
    }

    stage("code scan"){
        steps{
            script{
                echo 'Scanning code for quatliy improvements'

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
                sh "docker build -t dewnuwan/java-maven-app:jma-${IMAGE_NAME} ."
            }
        }
    }

    stage("Publish"){
        steps{
            script{
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh "echo $PASSWORD | docker login -u $USERNAME --password-stdin"
                    sh "docker push dewnuwan/java-maven-app:jma-${IMAGE_NAME}"
                    sh "docker rmi dewnuwan/java-maven-app:jma-${IMAGE_NAME}"
                }
            }
        }
    }

    stage("Deploy"){
        steps{
            echo 'Deploying to remote server..'
            sshPublisher(publishers: [sshPublisherDesc(configName: 'prod-server', transfers: [sshTransfer(cleanRemote: false, excludes: '', execCommand: 'docker -v', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+', remoteDirectory: '', remoteDirectorySDF: false, removePrefix: '', sourceFiles: '')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
        }
    }

    stage("Commit Version"){
        steps{
            echo 'commiting to git'
        }
    }



 }

}


