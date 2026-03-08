

pipeline {
 agent any

 tools{
    maven 'maven-3.9.13'
 }

 stages{

    stage('Checkout') {
                    steps {
                        checkout scm
                        scmSkip(deleteBuild: true, skipPattern:'.*\\[ci-skip\\].*')
                    }
                }


    stage("Increment Version"){
        steps{
            script{
                echo "Initializing"
                echo "Incrementing Version.."

                sh "mvn build-helper:parse-version versions:set \
                -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} versions:commit"
                def matcher = readFile('pom.xml') =~ '<version>(.+)</version>'
                def version = matcher[1][1]
                env.IMAGE_NAME = "$version-${BUILD_NUMBER}"
            }
        }
    }

    stage("Code Scan"){
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

    stage("Build Image"){
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
            sshPublisher(publishers: [sshPublisherDesc(configName: 'prod-server', transfers: [sshTransfer(cleanRemote: false, excludes: '', execCommand: """docker stop java-maven-app
            docker rm java-maven-app
            docker images dewnuwan/java-maven-app --format "{{.ID}}" | tail -n +2 | xargs -r docker rmi
            docker run -d -p 8080:8080 --name java-maven-app dewnuwan/java-maven-app:jma-${IMAGE_NAME}""", execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+', remoteDirectory: '', remoteDirectorySDF: false, removePrefix: '', sourceFiles: '')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
        }
    }

    stage("Commit Version"){
        steps{
            echo 'commiting to git'
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

    post {
        success {

            slackSend(
                channel: '#your-channel-name',
                color: 'good', // Green color for success
                message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
            )
        }
        failure {
            // This block runs only if the entire pipeline fails
            slackSend(
                channel: '#your-channel-name',
                color: 'danger', // Red color for failure
                color: '#FF0000', // Hex color also works
                message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
            )
        }
        // You can add other conditions like 'unstable', 'aborted', 'always' etc.
        unstable {
            slackSend(
                channel: '#your-channel-name',
                color: 'warning', // Yellow color for unstable (e.g., test failures)
                message: "UNSTABLE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
            )
        }
    }

}


