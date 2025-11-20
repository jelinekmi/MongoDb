import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os

# Složka s JSON soubory (aktuální složka)
json_folder = '.'

# Načtení všech JSON souborů ve složce
dataframes = []
for file in os.listdir(json_folder):
    if file.endswith('.json'):
        path = os.path.join(json_folder, file)
        df = pd.read_json(path, lines=False)  # přepni na lines=False pokud máš běžný JSON
        print(f"? Načten {file} - {df.shape[0]} øádkù, {df.shape[1]} sloupců")
        dataframes.append(df)

# Spojení všech dat (pokud mají podobnou strukturu)
combined_df = pd.concat(dataframes, ignore_index=True)

# Základní přehled
print("\n?? Základní informace:")
print(combined_df.info())

print("\n?? Popisné statistiky (číselné sloupce):")
print(combined_df.describe())

print("\n? Počty chybějících hodnot:")
print(combined_df.isnull().sum())

# Výběr pouze číselných sloupcù pro sumu a průměr
numeric_cols = combined_df.select_dtypes(include=[np.number])

print("\n?? Součty číselných sloupcù:")
print(numeric_cols.sum())

print("\n?? Průměry číselných sloupcù:")
print(numeric_cols.mean())

# Vykreslení histogramù
print("\n?? Vykreslení histogramů...")
numeric_cols.hist(bins=20, figsize=(12, 8))
plt.tight_layout()
plt.savefig('histogramy.png')
plt.close()

# Korelační matice
if numeric_cols.shape[1] > 1:
    plt.figure(figsize=(10, 6))
    sns.heatmap(numeric_cols.corr(), annot=True, cmap='coolwarm')
    plt.title('?? Korelační matice')
    plt.savefig('korelace.png')
    plt.close()

