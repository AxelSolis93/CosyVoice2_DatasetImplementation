import argparse
import logging
import glob
import os
from tqdm import tqdm


logger = logging.getLogger()

def main():
    metadata_path = os.path.join(args.src_dir, 'metadata.csv')
    wav_dir = os.path.join(args.src_dir, 'wavs')

    if not os.path.exists(metadata_path):
        raise FileNotFoundError(f"metadata.csv not found at {metadata_path}")
    if not os.path.exists(wav_dir):
        raise FileNotFoundError(f"wavs folder not found at {wav_dir}")

    utt2wav, utt2text, utt2spk, spk2utt = {}, {}, {}, {}

    with open(metadata_path, 'r', encoding='utf-8') as f:
        for line in tqdm(f):
            parts = line.strip().split('|')
            if len(parts) < 3:
                continue  # skip malformed lines
            utt = parts[0]  # e.g., LJ001-0001
            text = parts[2]  # normalized text
            wav_path = os.path.join(wav_dir, utt + '.wav')
            if not os.path.exists(wav_path):
                logger.warning(f"{wav_path} does not exist")
                continue

            spk = utt.split('-')[0]  # use "LJ001" as speaker ID

            utt2wav[utt] = wav_path
            utt2text[utt] = text
            utt2spk[utt] = spk
            spk2utt.setdefault(spk, []).append(utt)

    os.makedirs(args.des_dir, exist_ok=True)

    with open(os.path.join(args.des_dir, 'wav.scp'), 'w') as f:
        for k, v in utt2wav.items():
            f.write(f'{k} {v}\n')
    with open(os.path.join(args.des_dir, 'text'), 'w') as f:
        for k, v in utt2text.items():
            f.write(f'{k} {v}\n')
    with open(os.path.join(args.des_dir, 'utt2spk'), 'w') as f:
        for k, v in utt2spk.items():
            f.write(f'{k} {v}\n')
    with open(os.path.join(args.des_dir, 'spk2utt'), 'w') as f:
        for k, v in spk2utt.items():
            f.write(f'{k} {" ".join(v)}\n')


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--src_dir', type=str)
    parser.add_argument('--des_dir', type=str)
    args = parser.parse_args()
    main()
