set -e
set -x

make_conda_entrypoint() {
    local filepath="$1"
    local pythonpath="$2"
    local workingdir="$3"
    ls -al $filepath
    rm -rf $filepath
	cat <<- EOF > $filepath
	#!$pythonpath
	if __name__ == '__main__':
	   import sys
	   sys.path.insert(0, '$workingdir')
	   import conda.cli.main
	   sys.exit(conda.cli.main.main())
	EOF
    chmod +x $filepath
    cat $filepath
}

main_test() {
    export PYTEST_EXE="~/miniconda/bin/py.test"

    # basic unit tests
    make conda-version
    make integration
#    ~/miniconda/bin/python -m pytest --cov-report xml --shell=bash --shell=zsh -m "not installed" --doctest-modules conda tests
}

activate_test() {
#    local prefix=$(python -c "import sys; print(sys.prefix)")
#    ln -sf shell/activate $prefix/bin/activate
#    ln -sf shell/deactivate $prefix/bin/deactivate
#    make_conda_entrypoint $prefix/bin/conda $prefix/bin/python pwd

    ~/miniconda/bin/python utils/setup-testing.py develop
    export PATH="~/miniconda/bin:$PATH"
    hash -r
    ~/miniconda/bin/python -c "import conda; print(conda.__version__)"
    ~/miniconda/bin/python -m conda info

    export PYTEST_EXE="~/miniconda/bin/py.test"
    make test-installed

#    ~/miniconda/bin/python -m pytest --cov-report term-missing --cov-report xml --cov-append --shell=bash --shell=zsh -m "installed" tests
}


conda_build_smoke_test() {
    conda config --add channels conda-canary
    conda build conda.recipe
}

conda_build_unit_test() {
    pushd conda-build
    echo
    echo ">>>>>>>>>>>> running conda-build unit tests >>>>>>>>>>>>>>>>>>>>>"
    echo
    ~/miniconda/bin/python -m conda info
    ~/miniconda/bin/python -m pytest --basetemp /tmp/cb -v --durations=20 -n 0 -m "serial" tests
    ~/miniconda/bin/python -m pytest --basetemp /tmp/cb -v --durations=20 -n 2 -m "not serial" tests
    popd
}

env | sort

if [[ $FLAKE8 == true ]]; then
    ~/miniconda/bin/python -m flake8 --statistics
elif [[ -n $CONDA_BUILD ]]; then
    conda_build_smoke_test
    conda_build_unit_test
else
    main_test
    if [[ "$(uname -s)" == "Linux" ]]; then
        activate_test
    fi
fi

set +x
