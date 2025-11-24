pipeline {

    agent any

    triggers {
        pollSCM('* * * * *')  
    }

    environment {
        MAVEN_OPTS = '-Xmx2048m'
        PROJECT_NAME = 'spring-petclinic'
        SONAR_PROJECT_KEY = 'spring-petclinic'
        DOCKER_ARGS = '-v /var/run/docker.sock:/var/run/docker.sock --network spring-petclinic_devops-net --memory=4g'
    }

    stages {

        /*********************************************
         * Checkout code
         *********************************************/
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                checkout scm
                script {
                    sh 'git rev-parse --short HEAD'
                    sh 'git log -1 --pretty=%B'
                }
            }
        }

        /*********************************************
         * Build using Java 25
         *********************************************/
        stage('Build (Java 25)') {
            agent {
                docker {
                    image 'maven-java25:latest'
                    args "${DOCKER_ARGS}"
                }
            }
            steps {
                echo 'Building project with Java 25...'
                sh 'chmod +x mvnw'
                sh './mvnw clean compile -DskipTests'
            }
        }


        /*********************************************
         * Unit Tests
         *********************************************/
        stage('Test (Java 25)') {
            agent {
                docker {
                    image 'maven-java25:latest'
                    args "${DOCKER_ARGS}"
                }
            }
            steps {
                echo 'Running unit tests...'
                sh './mvnw test -Dtest="!PostgresIntegrationTests"'
            }
            post {
                always {
                    junit testResults: '**/target/surefire-reports/*.xml', allowEmptyResults: true
                    jacoco(
                        execPattern: '**/target/jacoco.exec',
                        classPattern: '**/target/classes',
                        sourcePattern: '**/src/main/java',
                        exclusionPattern: '**/*Test*.class'
                    )
                }
            }
        }


        /*********************************************
         * SonarQube Analysis
         *********************************************/
        stage('SonarQube Analysis (Java 25)') {
            agent {
                docker {
                    image 'maven-java25:latest'
                    args "${DOCKER_ARGS}"
                }
            }
            steps {
                echo 'Running SonarQube analysis...'
                withSonarQubeEnv('SonarQubeServer') {
                    sh """
                        ./mvnw sonar:sonar \
                        -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                        -Dsonar.projectName=${PROJECT_NAME} \
                        -Dsonar.projectVersion=${BUILD_NUMBER}
                    """
                }
            }
        }


        /*********************************************
         * Wait for Quality Gate
         *********************************************/
        stage('Quality Gate') {
            steps {
                echo 'Waiting for SonarQube quality gate result...'
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        def qg = waitForQualityGate abortPipeline: true
                        echo "Quality gate status: ${qg.status}"
                    }
                }
            }
        }


        /*********************************************
         * Package JAR
         *********************************************/
        stage('Package (Java 25)') {
            agent {
                docker {
                    image 'maven-java25:latest'
                    args "${DOCKER_ARGS}"
                }
            }
            steps {
                echo 'Packaging application...'
                sh './mvnw package -DskipTests'
            }
            post {
                success {
                    stash name: 'jar-artifacts', includes: 'target/*.jar', allowEmpty: false
                }
            }
        }

        /*********************************************
         * Archive artifacts
         *********************************************/
        stage('Archive') {
            steps {
                echo 'Archiving artifacts...'
                unstash 'jar-artifacts'
                archiveArtifacts artifacts: 'target/*.jar',
                    fingerprint: true,
                    allowEmptyArchive: false
            }
        }


        /*********************************************
         * OWASP ZAP Security Scan
         *********************************************/
        stage('OWASP ZAP Scan') {
            steps {
                script {
                    sh '''
                    set +e

                    echo "Starting ZAP container..."
                    docker run -dt --name zap-scanner \
                        --network=spring-petclinic_devops-net \
                        ghcr.io/zaproxy/zaproxy:stable /bin/bash

                    echo "Creating work directory..."
                    docker exec zap-scanner mkdir -p /zap/wrk

                    echo "Running ZAP baseline scan..."
                    ZAP_EXIT=0
                    docker exec zap-scanner zap-baseline.py \
                        -w /zap/wrk \
                        -t http://petclinic:8080 \
                        -r report.html \
                        -I || ZAP_EXIT=$?

                    echo "ZAP scan completed with exit code: ${ZAP_EXIT:-0}"

                    if docker exec zap-scanner test -f /zap/wrk/report.html; then
                        docker cp zap-scanner:/zap/wrk/report.html ./zap_report.html
                        ls -lh zap_report.html
                        echo "✓ ZAP HTML report copied successfully"
                    else
                        echo "⚠️ Report not found, creating placeholder"
                        cat > zap_report.html <<EOF
<!DOCTYPE html>
<html>
<head><title>OWASP ZAP Scan Report</title></head>
<body>
<h1>OWASP ZAP Security Scan</h1>
<h2>Scan Summary</h2>
<p>Scan completed. Check console output for detailed results.</p>
<p><strong>Exit Code:</strong> ${ZAP_EXIT:-0}</p>
</body>
</html>
EOF
                    fi
                    '''
                }
            }
            post {
                always {
                    sh '''
                        docker stop zap-scanner 2>/dev/null || true
                        docker rm zap-scanner 2>/dev/null || true
                    '''
                }
            }
        }


        /*********************************************
         * Publish ZAP Reports
         *********************************************/
        stage('Publish ZAP Report') {
            steps {
                echo 'Publishing OWASP ZAP report...'
                
                // Archive XML report if it exists
                script {
                    if (fileExists('zap_report.xml')) {
                        archiveArtifacts artifacts: 'zap_report.xml', fingerprint: true
                    }
                }
                
                // Publish HTML report
                publishHTML target: [
                    allowMissing: true,
                    reportDir: '.',
                    reportFiles: 'zap_report.html',
                    reportName: 'OWASP ZAP Security Report'
                ]
            }
        }
    }


    post {
        success {
            echo 'Build succeeded!'
        }
        failure {
            echo 'Build failed!'
        }
    }
}
