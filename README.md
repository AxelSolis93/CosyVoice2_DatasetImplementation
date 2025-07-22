# CosyVoice2_Implementation
 
Implementación de CosyVoice2, entrenando con el dataset "LjSpeech". 


- Clone the repo
    ``` sh
    git clone --recursive https://github.com/FunAudioLLM/CosyVoice.git
    # If you failed to clone the submodule due to network failures, please run the following command until success
    cd CosyVoice
    git submodule update --init --recursive
    ```
  
- Install Conda: please see https://docs.conda.io/en/latest/miniconda.html
- Create Conda env:

    ``` sh
    conda create -n cosyvoice -y python=3.10
    conda activate cosyvoice
    # pynini is required by WeTextProcessing, use conda to install it as it can be executed on all platforms.
    conda install -y -c conda-forge pynini==2.1.5
    pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host=mirrors.aliyun.com
    
    # If you encounter sox compatibility issues
    # ubuntu
    sudo apt-get install sox libsox-dev
    # centos
    sudo yum install sox sox-devel
    ```

### Model download

Para este proyecto, únicamente utilicé CosyVoice2-0.5B.

``` python
# SDK模型下载
from modelscope import snapshot_download
snapshot_download('iic/CosyVoice2-0.5B', local_dir='pretrained_models/CosyVoice2-0.5B')
```

``` sh
# git模型下载，请确保已安装git lfs
mkdir -p pretrained_models
git clone https://www.modelscope.cn/iic/CosyVoice2-0.5B.git pretrained_models/CosyVoice2-0.5B
```

### Reemplazado de dataset

El stage -2 se encarga de descargar la base de datos nueva LjSpeech, el stage -1 se encarga de dividir el dataset a un tercio de su tamaño y a generar una carpeta para inferencias con 100 samples. La parte dividida del dataset se escoge aleatoriamente y tiene una semilla por defecto de 42.

Para correr el run.sh, se utilizó 

``` sh
 bash run.sh --stage -2 --stop_stage -1
```
permitiendo colocar los stages como parámetros en la consola. Para preparar los datos se deben correr los stages del 0 al 3, las inferencias son el 41 y 42, y el proceso de entrenamiento es del stage 5 al 6, con el stage 7 como opcional si se quiere exportar el modelo para facilitar inferencias.

