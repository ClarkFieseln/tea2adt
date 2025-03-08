###################################################################################################################
NOTE:
#####
This readme is only for "contributors" of the project.
You may use it as a guide in case you want to create variants of this tool on another PyPI or Test PyPI repository.
But then you need to change the name of your tool and create the corresponding project.
###################################################################################################################


#################
before you start:
#################

# set the 'default' configuration:
----------------------------------

echo "true" > cfg/install_dependencies

# install dependencies:
-----------------------

sudo apt update

sudo apt upgrade

python3 -m pip install --upgrade pip

pip install wheel

pip install minimodem

pip install gpg


######################
for test in test.pypi:
######################

# inside the folder with the setup.py file type:

python3 -m pip install -e . --config-settings editable_mode=compat

python3 -m build

twine check dist/*

cd tea2adt_source

# test if the local installation works:

tea2adt -V

-----------------------------------------------------------------------------

pip install -I --user idna

# inside the folder with the setup.py file type:

python3 -m twine upload --repository-url https://test.pypi.org/legacy/ dist/*

      user: __token__
      pwd: (paste token here)

# now copy the text at the beginning of the page, see e.g.:
   https://test.pypi.org/project/tea2adt/0.0.6/

# the text may be something like this:
# pip install -i https://test.pypi.org/simple/ tea2adt==0.0.6
# you may first want to create a virtual environment:
   virtualenv venv_test
   cd venv_test
   source bin/activate
   (or source local/bin/activate ?)

# repeat steps above in "before you start"

# after that type:
   pip install -i https://test.pypi.org/simple/ tea2adt==0.0.6
   (you may need to repeat if the first try fails!)

# now the command tea2adt is available for use, check installation path with:
   pip show tea2adt
# change to that 'Location', e.g.:
   cd /home/<user>/.pyenv/versions/3.10.14/lib/python3.10/site-packages/tea2adt_source
   tea2adt -V
   pip list | grep tea2adt

# leave the virtual environment:
   deactivate

------------------------------------------------------------------------------

####################
for release in pypi:
####################

# TODO: setup.py install is deprecated -> adapt procedure as required.

# inside the folder with the setup.py file type:

python3 setup.py sdist bdist_wheel

twine check dist/*

twine upload dist/*

# enter user and password (or token), e.g.:

      user: __token__
      pwd: (paste token here)

# now the pypi project is available here:
   https://pypi.org/project/tea2adt

# install on the machine you want to use the tool with:
   pip install tea2adt

# now the command tea2adt is available for use
