

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
                    sh "docker build -t ${IMAGE_TAG} ."
                    sh "echo $PASSWORD | docker login -u $USERNAME --password-stdin"
                    sh "docker push ${IMAGE_TAG}"
                    sh "docker rmi ${IMAGE_TAG}"
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
            docker run -d -p 8080:8080 --name java-maven-app ${IMAGE_TAG}""", execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+', remoteDirectory: '', remoteDirectorySDF: false, removePrefix: '', sourceFiles: '')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
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


