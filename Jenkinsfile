#!groovy
// -*- mode: groovy -*-
build('image-build-erlang', 'docker-host') {
  checkoutRepo()
    runStage('build image') {
      withPublicRegistry() {
        sh 'make build-erlang'
      }
  }
  withPrivateRegistry() {
    try {
      if (env.BRANCH_NAME == 'master') {
        runStage('docker image push') {
          sh 'make push'
        }
      }
    } finally {
      runStage('rm local image') {
        sh 'make clean'
      }
    }
  }
}
