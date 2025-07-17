import os
import random
import shutil
import tempfile
from pathlib import Path

def reduce_ljspeech_to_third(dataset_path, percentage=0.33, seed=42):
    """
    Reduce LJSpeech dataset to approximately one third of its original size
    and replace the original folder with the reduced version.
    
    Args:
        dataset_path: Path to the LJSpeech dataset
        percentage: Percentage to keep (0.33 = 33% = 1/3)
        seed: Random seed for reproducibility
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
    
    # Randomly shuffle all lines first (like the original script)
    random.seed(seed)  # Use configurable seed
    random.shuffle(lines)
    
    # Select the first keep_samples after shuffling
    selected_lines = lines[:keep_samples]
    
    # Create temporary directory for the reduced dataset
    temp_dir = tempfile.mkdtemp()
    temp_dataset_path = os.path.join(temp_dir, 'reduced_ljspeech')
    temp_wavs_path = os.path.join(temp_dataset_path, 'wavs')
    
    os.makedirs(temp_dataset_path, exist_ok=True)
    os.makedirs(temp_wavs_path, exist_ok=True)
    
    # Write reduced metadata
    with open(os.path.join(temp_dataset_path, 'metadata.csv'), 'w', encoding='utf-8') as f:
        f.writelines(selected_lines)
    
    # Copy selected audio files
    copied_files = 0
    for line in selected_lines:
        filename = line.split('|')[0] + '.wav'
        src = os.path.join(dataset_path, 'wavs', filename)
        dst = os.path.join(temp_wavs_path, filename)
        
        if os.path.exists(src):
            shutil.copy2(src, dst)
            copied_files += 1
        else:
            print(f"Warning: Audio file not found: {filename}")
    
    print(f"Copied {copied_files} audio files")
    
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
    print(f"Samples: {keep_samples}/{total_samples} ({percentage*100:.1f}%)")
    
    return True

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python reduce_ljspeech.py <dataset_path> [seed]")
        print("  dataset_path: Path to LJSpeech dataset")
        print("  seed: Random seed (default: 42)")
        sys.exit(1)
    
    dataset_path = sys.argv[1]
    seed = int(sys.argv[2]) if len(sys.argv) > 2 else 42
    
    print(f"Using random seed: {seed}")
    success = reduce_ljspeech_to_third(dataset_path, seed=seed)
    
    if not success:
        sys.exit(1)