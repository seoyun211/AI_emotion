# colab
#!pip install mxnet
#!pip install gluonnlp pandas tqdm
#!pip install sentencepiece (버전 0.1.91)
#!pip install transformers (버전 4.8.2)
#!pip install torch (버전 1.8.1)
#!pip install --pre mxnet==1.9.1
#!pip install gluonnlp==0.10.0
#!pip install numpy
#!pip install 'git+https://github.com/SKTBrain/KoBERT.git#egg=kobert_tokenizer&subdirectory=kobert_hf'
#!pip install 'git+https://github.com/SKTBrain/KoBERT.git#egg=kobert_tokenizer&subdirectory=kobert_hf'

import torch
from torch import nn
import torch.nn.functional as F
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
import numpy as np
from tqdm import tqdm, tqdm_notebook
import pandas as pd
import gc
from transformers.optimization import get_cosine_schedule_with_warmup
from transformers import BertModel

#GPU 
device = torch.device("cuda:0")
gc.collect()
torch.cuda.empty_cache()
CUDA_LAUNCH_BLOCKING=1

tokenizer = KoBERTTokenizer.from_pretrained('skt/kobert-base-v1')
bertmodel = BertModel.from_pretrained('skt/kobert-base-v1')
tok = tokenizer.tokenize

#연결확인
print(len(tokenizer.get_vocab()))  # 단어 개수 확인
print(tokenizer.tokenize("안녕하세요, 반가워요!")) 

#구글 드라이브 연결
from google.colab import drive
drive.mount('/content/drive')
data = pd.read_csv('/content/drive/MyDrive/final_dataset.csv')
print(data.head())

data.sample(n=10)

data.loc[(data['label'] == "기쁨"), 'label_num'] = 0
data.loc[(data['label'] == "당황"), 'label_num'] = 1
data.loc[(data['label'] == "분노"), 'label_num'] = 2
data.loc[(data['label'] == "불안"), 'label_num'] = 3
data.loc[(data['label'] == "상처"), 'label_num'] = 4
data.loc[(data['label'] == "슬픔"), 'label_num'] = 5
data.loc[(data['label'] == "중립"), 'label_num'] = 6
data.loc[(data['label'] == "역겨움"), 'label_num'] = 7
data.loc[(data['label'] == "공포"), 'label_num'] = 8
data.loc[(data['label'] == "놀람"), 'label_num'] = 9

label_names = {
    0: "기쁨",
    1: "당황",
    2: "분노",
    3: "불안",
    4: "상처",
    5: "슬픔",
    6: "중립",
    7: "역겨움",
    8: "공포",
    9: "놀람"
}

print("데이터 분포:")
label_counts = data['label_num'].value_counts().sort_index()

for label_id, label_name in label_names.items():
    count = label_counts.get(label_id, 0)
    print(f"{label_name} ({label_id}): {count}개")

valid_labels = label_counts[label_counts > 0].index.tolist()
data = data[data['label_num'].isin(valid_labels)].reset_index(drop=True)
print(f"\n사용되는 데이터: {valid_labels}")

data_list = []
for sentence, label in zip(data['text'], data['label_num']):
    data = []
    data.append(sentence)
    data.append(str(label))

    data_list.append(data)


#hugging face KoBERT 토크나이저를 사용하여 문장을 BRET 입력 형식으로 변환하는 전처리 클래스
from kobert_tokenizer import KoBERTTokenizer

class BERTSentenceTransform:
    """
    KoBERT용 BERT style 변환 클래스 (Hugging Face tokenizer 전용)
    """

    def __init__(self, tokenizer, max_seq_length, pad=True, pair=False):
        self._tokenizer = tokenizer
        self._max_seq_length = max_seq_length
        self._pad = pad
        self._pair = pair

    def _truncate_seq_pair(self, tokens_a, tokens_b, max_length):
        """긴 문장을 자르는 내부 함수"""
        while True:
            total_length = len(tokens_a) + len(tokens_b)
            if total_length <= max_length:
                break
            if len(tokens_a) > len(tokens_b):
                tokens_a.pop()
            else:
                tokens_b.pop()

    def __call__(self, line):
        # line: (text_a,) 또는 (text_a, text_b)
        text_a = line[0]
        tokens_a = self._tokenizer.tokenize(text_a)

        tokens_b = None
        if self._pair:
            assert len(line) == 2
            text_b = line[1]
            tokens_b = self._tokenizer.tokenize(text_b)

        # [CLS], [SEP] 추가 및 길이 제한
        if tokens_b:
            self._truncate_seq_pair(tokens_a, tokens_b, self._max_seq_length - 3)
        else:
            tokens_a = tokens_a[:self._max_seq_length - 2]

        tokens = [self._tokenizer.cls_token] + tokens_a + [self._tokenizer.sep_token]
        segment_ids = [0] * len(tokens)

        if tokens_b:
            tokens += tokens_b + [self._tokenizer.sep_token]
            segment_ids += [1] * (len(tokens) - len(segment_ids))

        # ✅ Hugging Face 방식: vocab 없이 바로 id 변환
        input_ids = self._tokenizer.convert_tokens_to_ids(tokens)
        valid_length = len(input_ids)

        if self._pad:
            padding_length = self._max_seq_length - valid_length
            input_ids += [self._tokenizer.pad_token_id] * padding_length
            segment_ids += [0] * padding_length

        return (
            np.array(input_ids, dtype='int32'),
            np.array(valid_length, dtype='int32'),
            np.array(segment_ids, dtype='int32')
        )

#토크나이저 로드
tokenizer = KoBERTTokenizer.from_pretrained('skt/kobert-base-v1')
transform = BERTSentenceTransform(tokenizer, max_seq_length=64, pad=True, pair=False)

# 테스트
sample = ("오늘 날씨 정말 좋네요",)
input_ids, valid_length, segment_ids = transform(sample)

print("input_ids:", input_ids[:20])
print("valid_length:", valid_length)
print("segment_ids:", segment_ids[:20])
print("디코딩:", tokenizer.decode(input_ids[:valid_length]))


#Hugging Face KoBERTTokenizer 전용 Dataset 클래스
from torch.utils.data import Dataset

class BERTDataset(Dataset):

    def __init__(self, dataset, sent_idx, label_idx, bert_tokenizer, max_len, pad=True, pair=False):
        transform = BERTSentenceTransform( # 토큰화
            bert_tokenizer,
            max_seq_length=max_len, # 입력 문장 최대길이 근데 bret은 입력 길이가 고정되어야함
            pad=pad, # 길이가 짧은 문장은 pad로 채워줌
            pair=pair # 문장쌍 입력 여부
        )

        self.sentences = [transform([data[sent_idx]]) for data in dataset]
        self.labels = [np.int32(data[label_idx]) for data in dataset]

    def __getitem__(self, idx):
        return (*self.sentences[idx], self.labels[idx])

    def __len__(self):
        return len(self.labels)
    

# Setting parameters
max_len = 128
batch_size = 16
warmup_ratio = 0.1
num_epochs = 5
max_grad_norm = 1
log_interval = 200
learning_rate =  5e-5

from sklearn.model_selection import train_test_split

dataset_train, dataset_test = train_test_split(data_list, test_size=0.2, shuffle=True, random_state=34)

tokenizer = KoBERTTokenizer.from_pretrained('skt/kobert-base-v1')
bertmodel = BertModel.from_pretrained('skt/kobert-base-v1', return_dict=False)

data_train = BERTDataset(dataset_train, 0, 1, tokenizer, max_len, True, False)
data_test = BERTDataset(dataset_test, 0, 1, tokenizer, max_len, True, False)

train_dataloader = torch.utils.data.DataLoader(data_train, batch_size=batch_size, num_workers=0)
test_dataloader = torch.utils.data.DataLoader(data_test, batch_size=batch_size, num_workers=0)


import torch
import torch.nn as nn

class BERTClassifier(nn.Module):
    def __init__(self,
                 bert,
                 hidden_size = 768,
                 num_classes=7,
                 dr_rate=None):
        super(BERTClassifier, self).__init__()
        self.bert = bert
        self.dr_rate = dr_rate
        self.classifier = nn.Linear(hidden_size , num_classes)
        if dr_rate:
            self.dropout = nn.Dropout(p=dr_rate)

    def gen_attention_mask(self, token_ids, valid_length=None):
        """
        안전한 attention mask 생성기.
        - valid_length가 리스트/1D 텐서 형태이면 그것을 사용 (int로 변환)
        - 아니면 token_ids != 0 로부터 mask를 생성 (pad id = 0 가정)
        반환: torch.FloatTensor, same shape as token_ids (batch, seq_len)
        """
        # token_ids: tensor (batch, seq_len)
        if valid_length is None:
            # fallback: pad 토큰(0)을 기준으로 마스크 생성
            return (token_ids != 0).float().to(token_ids.device)

        # valid_length가 텐서인 경우 .tolist() 로 Python 리스트로 바꿔본다 (안전)
        if torch.is_tensor(valid_length):
            try:
                valid_list = valid_length.tolist()
            except Exception:
                # 단일값 혹은 이상한 tensor인 경우, squeeze 후 tolist 시도
                valid_list = [int(x) for x in valid_length.view(-1)]
        elif isinstance(valid_length, (list, tuple)):
            valid_list = valid_length
        else:
            # 숫자나 기타인 경우 하나의 값으로 처리
            try:
                valid_list = [int(valid_length)]
            except Exception:
                # 마지막 수단: token_ids != 0로 생성
                return (token_ids != 0).float().to(token_ids.device)

        batch_size, seq_len = token_ids.shape
        # 안전하게 크기 맞춰 초기화 (device 동일)
        attention_mask = torch.zeros((batch_size, seq_len), dtype=torch.float, device=token_ids.device)

        # valid_list 항목들을 int로 강제 변환하여 슬라이스
        for i, v in enumerate(valid_list):
            try:
                vi = int(v)
            except Exception:
                vi = 0
            if vi <= 0:
                continue
            if vi > seq_len:
                vi = seq_len
            # 슬라이스 할당 (float mask)
            attention_mask[i, :vi] = 1.0

        return attention_mask

    def forward(self, token_ids, valid_length, segment_ids):
        # segment_ids may come as tensor already; ensure long
        if segment_ids is not None:
            seg = segment_ids.long().to(token_ids.device)
        else:
            seg = torch.zeros_like(token_ids).long().to(token_ids.device)

        # gen_attention_mask에서 안전하게 만들어줌
        attention_mask = self.gen_attention_mask(token_ids, valid_length)

        # bert expects input_ids, token_type_ids, attention_mask
        _, pooler = self.bert(input_ids=token_ids.to(token_ids.device),
                              token_type_ids=seg,
                              attention_mask=attention_mask.float().to(token_ids.device),
                              return_dict=False)
        out = pooler
        if self.dr_rate:
            out = self.dropout(out)
        return self.classifier(out)

#train
# BERTClassifier 클래스를 사용해 모델을 생성
model = BERTClassifier(bertmodel, dr_rate=0.5).to(device)

#optimizer와 schedule 설정
no_decay = ['bias', 'LayerNorm.weight']
optimizer_grouped_parameters = [
    {'params': [p for n, p in model.named_parameters() if not any(nd in n for nd in no_decay)], 'weight_decay': 0.01},
    {'params': [p for n, p in model.named_parameters() if any(nd in n for nd in no_decay)], 'weight_decay': 0.0}
]

optimizer = AdamW(optimizer_grouped_parameters, lr=learning_rate)
loss_fn = nn.CrossEntropyLoss() # 다중분류를 위한 대표적인 loss func

t_total = len(train_dataloader) * num_epochs
warmup_step = int(t_total * warmup_ratio)

scheduler = get_cosine_schedule_with_warmup(optimizer, num_warmup_steps=warmup_step, num_training_steps=t_total)

#정확도 측정을 위한 함수 정의
def calc_accuracy(X,Y):
    max_vals, max_indices = torch.max(X, 1)
    train_acc = (max_indices == Y).sum().data.cpu().numpy()/max_indices.size()[0]
    return train_acc

train_dataloader