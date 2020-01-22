// Jenkinsfile
String credentialsId = 'awsCredentials'

try {
  stage('checkout') {
    node {
      cleanWs()
      checkout scm
      
//        def tfHome = tool name: 'Terraform'
//        env.PATH = "${tfHome}:${env.PATH}"
    }
  }

//  stage('Set Terraform path') {
//  steps {
//  script {
//  def tfHome = tool name: 'Terraform'
//  env.PATH = "${tfHome}:${env.PATH}"
//  }
//  sh 'terraform — version'
 
 
//  }
//  }

  // Run terraform init
  stage('init') {
    node {
      withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        credentialsId: credentialsId,
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
      ]]) {
        ansiColor('xterm') {
          sh 'terraform init -input=false'
//          sh "${tfHome}/terraform init"
        }
      }
    }
  }

  // Run terraform plan
  stage('plan') {
    node {
      withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        credentialsId: credentialsId,
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
      ]]) {
        ansiColor('xterm') {
          sh 'terraform plan -out=tfplan -input=false'
//          sh "${tfHome}/terraform plan"
        }
      }
    }
  }

stage('Approval') {
//      steps {
        script {
          def userInput = input(id: 'confirm', message: 'Apply Terraform?', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Apply terraform', name: 'confirm'] ])
//        }
      }
    }

//  if (env.BRANCH_NAME == 'master') {

    // Run terraform apply
    stage('apply') {
      node {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: credentialsId,
          accessKeyVariable: 'AWS_ACCESS_KEY_ID',
          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
        ]]) {
          ansiColor('xterm') {
//              sh """
//              terraform apply tfplan
//              terraform apply -input=false -auto-approve "tfplan"
              sh "set +e; terraform apply -auto-approve -input=false "tfplan";"
//              sh "${tfHome}/terraform apply -auto-approve"
//              """
          }
        }
      }
 //   }

    // Run terraform show
/*    stage('show') {
      node {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: credentialsId,
          accessKeyVariable: 'AWS_ACCESS_KEY_ID',
          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
        ]]) {
          ansiColor('xterm') {
//             sh "terraform show"
//              sh "${tfHome}/terraform show"
          }
        }
      }
    }
*/    
  }
  currentBuild.result = 'SUCCESS'
}
catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException flowError) {
  currentBuild.result = 'ABORTED'
}
catch (err) {
  currentBuild.result = 'FAILURE'
  throw err
}
finally {
  if (currentBuild.result == 'SUCCESS') {
    currentBuild.result = 'SUCCESS'
  }
}
