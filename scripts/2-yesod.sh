echo 'Enter project name'
read NAME
stack new $NAME yesod-sqlite && cd $NAME
echo $'\ndocker: \n enable: true\n' >> stack.yaml
stack build yesod-bin cabal-install --install-ghc
stack setup
stack build
stack test
stack exec cabal update
ALIAS=$'alias docker-yesod-dev="stack --docker-run-args=\'--net=bridge --publish=3000:3000\' exec yesod devel"'
if ! (cat ~/.bashrc | grep -q 'docker-yesod-dev'); then
    echo "$ALIAS" >> ~/.bashrc
fi
echo 'Run docker-yesod-dev to start a yesod development server running in a docker container'
source ~/.bashrc
