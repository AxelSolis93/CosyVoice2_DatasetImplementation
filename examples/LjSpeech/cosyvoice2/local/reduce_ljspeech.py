import os
import random
import shutil
import tempfile
import json
from pathlib import Path

def reduce_ljspeech_to_third(dataset_path, percentage=0.33, seed=42, inference_samples=100):
    """
    Reduce LJSpeech dataset to approximately one third of its original size,
    replace the original folder with the reduced version, and create inference data.
    
    Args:
        dataset_path: Path to the LJSpeech dataset
        percentage: Percentage to keep (0.33 = 33% = 1/3)
        seed: Random seed for reproducibility
        inference_samples: Number of samples for inference (default: 100)
    """
    
    print(f"Reducing LJSpeech dataset at: {dataset_path}")
    
    # Check if dataset exists
    if not os.path.exists(dataset_path):
        print(f"Error: Dataset not found at {dataset_path}")
        return False
    
    metadata_file = os.path.join(dataset_path, 'metadata.csv')
    if not os.path.exists(metadata_file):
        print(f"Error: metadata.csv not found at {metadata_file}")
        return False
    
    # Read metadata
    with open(metadata_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    total_samples = len(lines)
    keep_samples = int(total_samples * percentage)
    
    print(f"Original samples: {total_samples}")
    print(f"Keeping samples: {keep_samples} ({percentage*100:.1f}%)")
    print(f"Inference samples: {inference_samples}")
    
    # Randomly shuffle all lines first
    random.seed(seed)
    random.shuffle(lines)
    
    # Select samples for training (reduced dataset)
    training_lines = lines[:keep_samples]
    
    # Select samples for inference (separate from training)
    # Take from the remaining samples or overlap if needed
    if len(lines) >= keep_samples + inference_samples:
        inference_lines = lines[keep_samples:keep_samples + inference_samples]
    else:
        # If not enough samples, take from beginning
        inference_lines = lines[:inference_samples]
    
    # Create temporary directory for the reduced dataset
    temp_dir = tempfile.mkdtemp()
    temp_dataset_path = os.path.join(temp_dir, 'reduced_ljspeech')
    temp_wavs_path = os.path.join(temp_dataset_path, 'wavs')
    
    os.makedirs(temp_dataset_path, exist_ok=True)
    os.makedirs(temp_wavs_path, exist_ok=True)
    
    # Write reduced metadata for training
    with open(os.path.join(temp_dataset_path, 'metadata.csv'), 'w', encoding='utf-8') as f:
        f.writelines(training_lines)
    
    # Copy selected audio files for training
    copied_files = 0
    for line in training_lines:
        filename = line.split('|')[0] + '.wav'
        src = os.path.join(dataset_path, 'wavs', filename)
        dst = os.path.join(temp_wavs_path, filename)
        
        if os.path.exists(src):
            shutil.copy2(src, dst)
            copied_files += 1
        else:
            print(f"Warning: Audio file not found: {filename}")
    
    print(f"Copied {copied_files} audio files for training")
    
    # Create inference data
    print("Creating inference data...")
    
    # Create tts_text.json
    tts_data = {}
    inference_wavs_path = os.path.join(temp_dataset_path, 'inference_wavs')
    os.makedirs(inference_wavs_path, exist_ok=True)
    
    inference_copied = 0
    for line in inference_lines:
        parts = line.strip().split('|')
        if len(parts) >= 2:
            filename = parts[0]
            text = parts[1]
            
            # Add to tts_text.json
            tts_data[filename] = [text]
            
            # Copy audio file for inference
            src_audio = os.path.join(dataset_path, 'wavs', filename + '.wav')
            dst_audio = os.path.join(inference_wavs_path, filename + '.wav')
            
            if os.path.exists(src_audio):
                shutil.copy2(src_audio, dst_audio)
                inference_copied += 1
            else:
                print(f"Warning: Inference audio file not found: {filename}.wav")
    
    # Write tts_text.json in parent directory
    parent_dir = os.path.dirname(dataset_path)
    tts_json_path = os.path.join(parent_dir, 'tts_text.json')
    with open(tts_json_path, 'w', encoding='utf-8') as f:
        json.dump(tts_data, f, indent=2, ensure_ascii=False)
    
    print(f"Created tts_text.json with {len(tts_data)} samples")
    print(f"Copied {inference_copied} audio files for inference")
    
    # Copy other files that might exist (README, etc.)
    for item in os.listdir(dataset_path):
        item_path = os.path.join(dataset_path, item)
        if os.path.isfile(item_path) and item != 'metadata.csv':
            shutil.copy2(item_path, temp_dataset_path)
    
    # Replace original dataset with reduced version
    print("Replacing original dataset with reduced version...")
    
    # Remove original dataset
    shutil.rmtree(dataset_path)
    
    # Move reduced dataset to original location
    shutil.move(temp_dataset_path, dataset_path)
    
    # Clean up temporary directory
    shutil.rmtree(temp_dir)
    
    print(f"Dataset successfully reduced!")
    print(f"New dataset location: {dataset_path}")
    print(f"Training samples: {keep_samples}/{total_samples} ({percentage*100:.1f}%)")
    print(f"Inference samples: {len(tts_data)} in tts_text.json")
    print(f"Inference audio files: {inference_copied} in inference_wavs/ folder")
    print(f"tts_text.json created at: {tts_json_path}")
    
    return True

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python reduce_ljspeech.py <dataset_path> [seed] [inference_samples]")
        print("  dataset_path: Path to LJSpeech dataset")
        print("  seed: Random seed (default: 42)")
        print("  inference_samples: Number of samples for inference (default: 100)")
        sys.exit(1)
    
    dataset_path = sys.argv[1]
    seed = int(sys.argv[2]) if len(sys.argv) > 2 else 42
    inference_samples = int(sys.argv[3]) if len(sys.argv) > 3 else 100
    
    print(f"Using random seed: {seed}")
    print(f"Inference samples: {inference_samples}")
    success = reduce_ljspeech_to_third(dataset_path, seed=seed, inference_samples=inference_samples)
    
    if not success:
        sys.exit(1)
