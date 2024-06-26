#!/bin/sh

# the specific information for the model you want to download from huggingface hub
MODEL_NAME=THUDM/chatglm3-6b-128k
SAVE_DIR=chatglm
NON_MODEL_FILE_PATTERNS="*.md *.json *.py *.model"
NUM_MODEL_SHARDS=7
MODEL_FILE_FORMAT=bin

# the default setting that you don't need to change for the most cases
MODEL_TYPE=clm
TASK="text_generation"
DEVICES="0"
PEFT_PATH=""


## 1. download the non model files with only one process and only 10 times for retrying (enough)
python src/download_model.py \
--model_name $MODEL_NAME \
--save_dir $SAVE_DIR \
--download_mode all \
--allow_patterns  $NON_MODEL_FILE_PATTERNS \
--max_retry 10 \

echo "All non-model files are downloaded, including ${NON_MODEL_FILE_PATTERNS}."

## 2. download the model files with multiple processes and 30 times for retrying (sometimes may not enough)
for i in $(seq 1 $NUM_MODEL_SHARDS); do
    python src/download_model.py \
    --model_name $MODEL_NAME \
    --save_dir $SAVE_DIR \
    --download_mode all \
    --allow_patterns "pytorch_model-0000${i}-of-0000${NUM_MODEL_SHARDS}.${MODEL_FILE_FORMAT}" \
    --max_retry 50 \
    &
done

# Wait for all model shard downloading processes to finish
wait

echo "All model shards from idx 1 to ${NUM_MODEL_SHARDS} are downloads."


## 3. loaded the downloaded model

echo "Loading the downloaded model automatically..."

python src/load_downloaded_model.py \
--model_path "${SAVE_DIR}/${MODEL_NAME}" \
--model_type $MODEL_TYPE \
--task $TASK \
--devices $DEVICES \
