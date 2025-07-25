#!/bin/bash
# Copyright 2024 Alibaba Inc. All Rights Reserved.
../cosyvoice/path.sh || exit 1;

export PYTHONPATH=$(realpath ../../../):$(realpath ../../../third_party/Matcha-TTS/):$PYTHONPATH

stage=5
stop_stage=5

data_url=www.openslr.org/resources/60
data_dir=./dataset
pretrained_model_dir=../../../pretrained_models/CosyVoice2-0.5B
#pretrained_model_dir=../../../pretrained_models/trained

random_seed=42  # Random seed for dataset reduction

x=LJSpeech-1.1

while [[ $# -gt 0 ]]; do
  case $1 in
    --stage)
      stage="$2"
      shift 2
      ;;
    --stop_stage)
      stop_stage="$2"
      shift 2
      ;;
    *)
      echo "Argumento desconocido: $1"
      shift
      ;;
  esac
done

echo "Ejecutando desde stage $stage hasta $stop_stage"


if [ ${stage} -le -2 ] && [ ${stop_stage} -ge -2 ]; then
  echo "Data Download"
  echo "Data Download for LJSpeech"
  mkdir -p ${data_dir}
  # Se llama al script una sola vez, pasándole solo el directorio de datos.
  # El script que creamos antes ya sabe qué URL y archivo descargar.
  local/download_and_untar.sh --remove-archive ${data_dir} https://data.keithito.com/data/speech/LJSpeech-1.1.tar.bz2 LJSpeech-1.1
  
  part=LJSpeech-1.1
fi


if [ ${stage} -le -1 ] && [ ${stop_stage} -ge -1 ]; then
  # Reduce dataset to 1/3 of original size
  echo "Reducing LJSpeech dataset to 1/3 of original size..."
   python ./local/reduce_ljspeech.py reduce ${data_dir}/${x} ${random_seed}
fi

if [ ${stage} -le 0 ] && [ ${stop_stage} -ge 0 ]; then
  echo "Data preparation for LJSpeech: prepare wav.scp/text/utt2spk/spk2utt"
  
  mkdir -p data/$x
  python ./local/prepare_data.py --src_dir $data_dir/$x --des_dir data/$x
  
fi

if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
  echo "Extract campplus speaker embedding, you will get spk2embedding.pt and utt2embedding.pt in data/$x dir"
  ../../../tools/extract_embedding.py --dir data/$x \
  --onnx_path $pretrained_model_dir/campplus.onnx
  
fi

if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
  echo "Extract discrete speech token, you will get utt2speech_token.pt in data/$x dir"
  ../../../tools/extract_speech_token.py --dir data/$x \
  --onnx_path $pretrained_model_dir/speech_tokenizer_v2.onnx
  
fi

if [ ${stage} -le 3 ] && [ ${stop_stage} -ge 3 ]; then
  echo "Prepare required parquet format data, you should have prepared wav.scp/text/utt2spk/spk2utt/utt2embedding.pt/spk2embedding.pt/utt2speech_token.pt"
  mkdir -p data/$x/parquet
  ../../../tools/make_parquet_list.py --num_utts_per_parquet 1000 \
    --num_processes 10 \
    --src_dir data/$x \
    --des_dir data/$x/parquet
  
fi

#Prepare dataset for Inference
if [ ${stage} -le 41 ] && [ ${stop_stage} -ge 41 ]; then
  echo "Data preparation for LJSpeech inference: prepare wav.scp/text/utt2spk/spk2utt"
  inference_dataset="LJSpeech-1.1-inference"
  
  # Check if inference source directory exists
  if [ ! -d "$data_dir/$inference_dataset" ]; then
    echo "Error: Inference source directory not found at $data_dir/$inference_dataset"
    echo "Please run stage -1 first to create the inference dataset"
    exit 1
  fi
  
  mkdir -p data/$inference_dataset
  python ./local/prepare_data.py --src_dir $data_dir/$inference_dataset --des_dir data/$inference_dataset
  
  echo "Extract campplus speaker embedding, you will get spk2embedding.pt and utt2embedding.pt in data/$inference_dataset dir"
  ../../../tools/extract_embedding.py --dir data/$inference_dataset \
  --onnx_path $pretrained_model_dir/campplus.onnx
  
  echo "Extract discrete speech token, you will get utt2speech_token.pt in data/$inference_dataset dir"
  ../../../tools/extract_speech_token.py --dir data/$inference_dataset \
  --onnx_path $pretrained_model_dir/speech_tokenizer_v2.onnx
  
  echo "Prepare required parquet format data, you should have prepared wav.scp/text/utt2spk/spk2utt/utt2embedding.pt/spk2embedding.pt/utt2speech_token.pt"
  mkdir -p data/$inference_dataset/parquet
  ../../../tools/make_parquet_list.py --num_utts_per_parquet 1000 \
    --num_processes 10 \
    --src_dir data/$inference_dataset \
    --des_dir data/$inference_dataset/parquet
fi

# inference
if [ ${stage} -le 42 ] && [ ${stop_stage} -ge 42 ]; then
  echo "Run inference. Please make sure utt in tts_text is in prompt_data"
  # TODO consider remove bin/inference.py, or use similar initilization method as in readme
  for mode in sft zero_shot; do
    python ../../../cosyvoice/bin/inference.py --mode $mode \
      --gpu 0 \
      --config conf/cosyvoice2.yaml \
      --prompt_data data/LJSpeech-1.1-inference/parquet/data.list \
		--prompt_utt2data data/LJSpeech-1.1-inference/parquet/utt2data.list \
      --tts_text `pwd`/tts_text.json \
      --qwen_pretrain_path $pretrained_model_dir/CosyVoice-BlankEN \
      --llm_model $pretrained_model_dir/llm.pt \
	  --flow_model $pretrained_model_dir/flow.pt \
	  --hifigan_model $pretrained_model_dir/hift.pt \
	  --result_dir `pwd`/exp/cosyvoice/LJSpeech-1.1/$mode
	  #--flow_model "" \
	  #--llm_model "" \  
      #--hifigan_model "" \
  done
fi

# train llm
export CUDA_VISIBLE_DEVICES="0" #Changed since I only have 1 gpu
num_gpus=$(echo $CUDA_VISIBLE_DEVICES | awk -F "," '{print NF}')
job_id=1986
dist_backend="nccl"
num_workers=2
prefetch=100
train_engine=torch_ddp
if [ ${stage} -le 5 ] && [ ${stop_stage} -ge 5 ]; then
  echo "Run train. We only support llm traning for now. If your want to train from scratch, please use conf/cosyvoice.fromscratch.yaml"
  mkdir -p data
  mkdir -p exp/cosyvoice2/llm/$train_engine
  mkdir -p exp/cosyvoice2/flow/$train_engine
  mkdir -p tensorboard/cosyvoice2/llm/$train_engine
  mkdir -p tensorboard/cosyvoice2/flow/$train_engine
  data_list=data/$x/parquet/data.list
  
   if [ ! -f "$data_list" ]; then
    echo "ERROR: $data_list not found. Please run stages 0-3 first."
    exit 1
  fi
  
  total_lines=$(wc -l < $data_list)
  train_lines=$(( (total_lines * 9) / 10 ))
  dev_lines=$(( total_lines - train_lines ))
  
  
  
  head -n $train_lines $data_list > data/train.data.list
  tail -n $dev_lines $data_list > data/dev.data.list
  
  echo "Train samples: $train_lines, Dev samples: $dev_lines"
  
  echo "Run train. We only support llm training for now. If you want to train from scratch, please use conf/cosyvoice.fromscratch.yaml"
  
  if [ $train_engine == 'deepspeed' ]; then
	  echo "Notice deepspeed has its own optimizer config. Modify conf/ds_stage2.json if necessary"
  fi
  for model in llm flow; do
    torchrun --nnodes=1 --nproc_per_node=$num_gpus \
        --rdzv_id=$job_id --rdzv_backend="c10d" --rdzv_endpoint="localhost:1234" \
      ../../../cosyvoice/bin/train.py \
      --train_engine $train_engine \
      --config conf/cosyvoice2.yaml \
      --train_data data/train.data.list \
      --cv_data data/dev.data.list \
      --qwen_pretrain_path $pretrained_model_dir/CosyVoice-BlankEN \
      --model $model \
      --checkpoint $pretrained_model_dir/$model.pt \
      --model_dir `pwd`/exp/cosyvoice2/$model/$train_engine \
      --tensorboard_dir `pwd`/tensorboard/cosyvoice2/$model/$train_engine \
      --ddp.dist_backend $dist_backend \
      --num_workers ${num_workers} \
      --prefetch ${prefetch} \
      --pin_memory \
      --use_amp \
      --deepspeed_config ./conf/ds_stage2.json \
      --deepspeed.save_states model+optimizer
  done
fi

# average model
average_num=5
if [ ${stage} -le 6 ] && [ ${stop_stage} -ge 6 ]; then
  for model in llm flow; do
    decode_checkpoint=`pwd`/exp/cosyvoice2/$model/$train_engine/${model}.pt
    echo "do model average and final checkpoint is $decode_checkpoint"
    python ../../../cosyvoice/bin/average_model.py \
      --dst_model $decode_checkpoint \
      --src_path `pwd`/exp/cosyvoice2/$model/$train_engine  \
      --num ${average_num} \
      --val_best
  done
fi

if [ ${stage} -le 7 ] && [ ${stop_stage} -ge 7 ]; then
  echo "Export your model for inference speedup. Remember copy your llm or flow model to model_dir"
  python ../../../cosyvoice/bin/export_jit.py --model_dir $pretrained_model_dir
  python ../../../cosyvoice/bin/export_onnx.py --model_dir $pretrained_model_dir
fi
