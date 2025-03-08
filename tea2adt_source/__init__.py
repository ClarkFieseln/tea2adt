import pathlib

# The directory containing this file
HERE = pathlib.Path(__file__).parent

# The version in the version file
__version__ =  (HERE / "version").read_text()
