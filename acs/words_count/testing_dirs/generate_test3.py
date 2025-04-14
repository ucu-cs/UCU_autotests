for i in range(1_000):
    with open(f"./test4/word{i}.txt", "w", encoding="utf-8") as file:
        file.write("word " * 10)
