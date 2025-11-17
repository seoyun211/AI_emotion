import pandas as pd
import chardet

base_path = r"C:\Users\jiheo\OneDrive\Desktop\\"

# 파일 인코딩 감지
with open(base_path + 'converted_add.csv', 'rb') as f:
    result = chardet.detect(f.read())
print("converted_add.csv 인코딩:", result['encoding'])

with open(base_path + 'emotion_dataset.csv', 'rb') as f:
    result = chardet.detect(f.read())
print("emotion_dataset.csv 인코딩:", result['encoding'])

# 감지된 인코딩으로 읽기
df1 = pd.read_csv(base_path + 'converted_add.csv', encoding=result['encoding'])
df2 = pd.read_csv(base_path + 'emotion_dataset.csv', encoding=result['encoding'])

df_merged = pd.concat([df1, df2], ignore_index=True)
df_merged.to_csv(base_path + 'final_dataset.csv', index=False, encoding='utf-8-sig')
print("CSV 파일 합치기 완료!")
