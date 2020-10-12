#!groovy
// -*- mode: groovy -*-
build('image-build-erlang', 'docker-host') {
  checkoutRepo()
    runStage('build image') {
      docker.withRegistry('https://dr2.rbkmoney.com/v2/', 'jenkins_harbor') {
        sh 'make build_erlang'
      }
  }
  try {
    if (env.BRANCH_NAME == 'master') {
      runStage('docker image push') {
        docker.withRegistry('https://dr2.rbkmoney.com/v2/', 'jenkins_harbor') {
          sh 'make push'
        }
      }
    }
  } finally {
    runStage('rm local image') {
      sh 'make clean'
    }
  }
}
