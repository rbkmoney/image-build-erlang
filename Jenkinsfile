#!groovy
// -*- mode: groovy -*-
build('image-build-erlang', 'docker-host') {
  checkoutRepo()
    runStage('build image') {
      withPrivateRegistry() {
        sh 'make build_erlang'
      }
  }
  try {
    if (env.BRANCH_NAME == 'master') {
      runStage('docker image push') {
        withPrivateRegistry() {
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
