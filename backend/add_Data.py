import pandas as pd

# 🔹 엑셀 파일 경로 지정
file_path = r"C:\Users\jiheo\OneDrive\Desktop\add.xlsx"

# 🔹 엑셀 파일 불러오기
df = pd.read_excel(file_path)

# 🔹 라벨 매핑
label_names = {
    0: "기쁨", 1: "당황", 2: "분노", 3: "불안", 4: "상처",
    5: "슬픔", 6: "중립", 7: "역겨움", 8: "공포", 9: "놀람"
}
label_to_num = {v: k for k, v in label_names.items()}

# 🔹 사용할 문장 컬럼 선택 (사람문장만)
text_columns = ['사람문장1', '사람문장2', '사람문장3']

# 🔹 세 문장 컬럼을 하나의 열로 합치기 (melt)
df_melted = df.melt(id_vars=['감정_대분류'], value_vars=text_columns,
                    var_name='문장종류', value_name='text')

# 🔹 label 및 label_num 추가
df_melted['label'] = df_melted['감정_대분류']
df_melted['label_num'] = df_melted['label'].map(label_to_num)

# 🔹 필요한 열만 남기고 결측 제거
final_df = df_melted[['text', 'label', 'label_num']].dropna()

# 🔹 결과 저장 (바탕화면에 CSV 파일로)
save_path = r"C:\Users\jiheo\OneDrive\Desktop\converted_add.csv"
final_df.to_csv(save_path, index=False, encoding='utf-8-sig')

print("✅ 변환 완료! 저장 위치:", save_path)
print(final_df.head())
