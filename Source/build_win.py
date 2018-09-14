# Build file for windows

from distutils.core import setup
import py2exe
import sys; sys.argv.append('py2exe')

py2exe_options = dict(
                      bundle_files=2,
                      compressed=True,              # Compress library.zip
                      # packages=['pyglet', 'enet'],
                      )

setup(
    author='Caribou/Caramoun',
    description='GS',
    version='0.1',
    console=[
        {
            "script": "server.py",  # Main Python script
        }
    ],

    options={'py2exe': py2exe_options},
    # options={"py2exe":{"packages": ['lxml','gzip']}},
    zipfile=None,
)
