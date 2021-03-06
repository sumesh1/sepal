#!/bin/bash
set -e

echo
echo "**************************"
echo "*** Installing Jupyter ***"
echo "**************************"
/usr/bin/python3 -m pip install jupyter
/usr/bin/python3 /usr/local/bin/jupyter-notebook --generate-config
/usr/bin/python3 -m pip install ipykernel
/usr/bin/python3 -m ipykernel install
R -e "pacman::p_load('IRkernel')"
R -e "IRkernel::installspec(user = FALSE)"
/usr/bin/python3 -m pip install ipywidgets
/usr/bin/python3 -m pip install jupyterlab
/usr/bin/python3 -m pip install folium
/usr/bin/python3 -m pip install ipyleaflet
/usr/bin/python3 -m pip install ipyvuetify
git clone https://github.com/ipython-contrib/jupyter_contrib_nbextensions.git
/usr/bin/python3 -m pip install -e jupyter_contrib_nbextensions
/usr/bin/python3 /usr/local/bin/jupyter contrib nbextension install
/usr/bin/python3 /usr/local/bin/jupyter nbextensions_configurator enable
/usr/bin/python3 /usr/local/bin/jupyter nbextension enable --py --sys-prefix widgetsnbextension

/usr/bin/python3 -m pip install voila
/usr/bin/python3 /usr/local/bin/jupyter nbextension install voila --sys-prefix --py
/usr/bin/python3 /usr/local/bin/jupyter nbextension enable voila --sys-prefix --py
/usr/bin/python3 /usr/local/bin/jupyter serverextension enable voila --sys-prefix

npm install -g --unsafe-perm ijavascript
npm install -g js-beautify
/usr/bin/ijsinstall --install=global
