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

Por tiempo, decidí descargar la url "https://www.kaggle.com/datasets/mathurinache/the-lj-speech-dataset" y eliminar la parte de descargado automático de dataset. 
El script para entrenar y para inferencia está en `examples/LjSpeech/cosyvoice2/run.sh`. En esta carpeta, una carpeta "dataset" creada manualmente contiene el dataset LjSpeech descomprimido.

Para correr el run.sh, se utilizó 

``` sh
bash run.sh
```

y por cuestiones de tiempo, se hardcodeó que inicie en el stage 0 y termine en el 5 (entrenamiento).
